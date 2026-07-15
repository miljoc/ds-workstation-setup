#!/usr/bin/env bash
set -euo pipefail

EXTENSION_DIR="$HOME/.local/share/nautilus-python/extensions"
EXTENSION_FILE="$EXTENSION_DIR/image_converter.py"

sudo dnf install -y \
  nautilus-python \
  ImageMagick \
  libnotify

# EPEL currently provides the libheif command-line tools on Rocky Linux 10.
if ! command -v heif-convert >/dev/null 2>&1; then
  sudo dnf install -y libheif-tools || sudo dnf install -y libheif
fi

mkdir -p "$EXTENSION_DIR"

cat > "$EXTENSION_FILE" <<'PY'
#!/usr/bin/env python3

from __future__ import annotations

import concurrent.futures
import os
import shutil
import subprocess
import threading
from pathlib import Path
from typing import Sequence

from gi.repository import GObject, GLib, Nautilus


SUPPORTED_EXTENSIONS = {
    ".heic",
    ".heif",
    ".avif",
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".tif",
    ".tiff",
    ".bmp",
}

MAX_WORKERS = max(1, min(6, os.cpu_count() or 2))


class ImageConverterExtension(GObject.GObject, Nautilus.MenuProvider):
    """Image conversion and rotation actions for Nautilus."""

    def get_file_items(
        self,
        files: Sequence[Nautilus.FileInfo],
    ) -> list[Nautilus.MenuItem]:
        paths = self._get_supported_paths(files)

        if not paths:
            return []

        root_item = Nautilus.MenuItem(
            name="ImageConverterExtension::Root",
            label="Afbeelding bewerken",
            tip="Converteer of roteer de geselecteerde afbeelding(en)",
            icon="image-x-generic-symbolic",
        )

        submenu = Nautilus.Menu()

        self._append_item(
            submenu, "JpgHigh", "Converteer naar JPG - hoge kwaliteit",
            "Converteer naar JPEG met kwaliteit 95", paths, "jpg"
        )
        self._append_item(
            submenu, "JpgSmall", "Converteer naar JPG - maximaal 2048 px",
            "Verklein de lange zijde tot maximaal 2048 pixels", paths, "jpg-small"
        )
        self._append_item(
            submenu, "Png", "Converteer naar PNG",
            "Converteer naar PNG", paths, "png"
        )
        self._append_item(
            submenu, "Webp", "Converteer naar WebP - hoge kwaliteit",
            "Converteer naar WebP met kwaliteit 90", paths, "webp"
        )
        self._append_item(
            submenu, "RotateLeft", "Roteer 90 graden linksom",
            "Maak een kopie die 90 graden linksom is gedraaid", paths, "rotate-left"
        )
        self._append_item(
            submenu, "RotateRight", "Roteer 90 graden rechtsom",
            "Maak een kopie die 90 graden rechtsom is gedraaid", paths, "rotate-right"
        )

        root_item.set_submenu(submenu)
        return [root_item]

    def _append_item(
        self,
        submenu: Nautilus.Menu,
        identifier: str,
        label: str,
        tip: str,
        paths: list[Path],
        mode: str,
    ) -> None:
        item = Nautilus.MenuItem(
            name=f"ImageConverterExtension::{identifier}",
            label=label,
            tip=tip,
        )
        item.connect("activate", self._on_activate, paths.copy(), mode)
        submenu.append_item(item)

    def _get_supported_paths(
        self,
        files: Sequence[Nautilus.FileInfo],
    ) -> list[Path]:
        paths: list[Path] = []

        for file_info in files:
            location = file_info.get_location()
            if location is None:
                continue

            path_string = location.get_path()
            if not path_string:
                continue

            path = Path(path_string)
            if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
                paths.append(path)

        return paths

    def _on_activate(
        self,
        _menu_item: Nautilus.MenuItem,
        paths: list[Path],
        mode: str,
    ) -> None:
        worker = threading.Thread(
            target=self._process_batch,
            args=(paths, mode),
            daemon=True,
        )
        worker.start()

    def _process_batch(self, paths: list[Path], mode: str) -> None:
        successes: list[Path] = []
        failures: list[str] = []

        with concurrent.futures.ThreadPoolExecutor(
            max_workers=min(MAX_WORKERS, len(paths)),
        ) as pool:
            future_map = {
                pool.submit(self._process_one, path, mode): path
                for path in paths
            }

            for future in concurrent.futures.as_completed(future_map):
                source = future_map[future]
                try:
                    successes.append(future.result())
                except Exception as exc:
                    failures.append(f"{source.name}: {exc}")

        GLib.idle_add(self._refresh_directories, paths, successes)

        if failures:
            self._write_error_log(failures)
            self._notify(
                "Afbeeldingen bewerken",
                f"{len(successes)} bestand(en) voltooid; {len(failures)} mislukt.",
                error=True,
            )
        else:
            self._notify(
                "Bewerking voltooid",
                f"{len(successes)} bestand(en) succesvol verwerkt.",
            )

    def _process_one(self, source: Path, mode: str) -> Path:
        if not source.exists():
            raise RuntimeError("bronbestand bestaat niet meer")

        if mode == "jpg":
            return self._convert_to_jpg(source)
        if mode == "jpg-small":
            return self._convert_to_small_jpg(source)
        if mode == "png":
            return self._convert_to_png(source)
        if mode == "webp":
            return self._convert_to_webp(source)
        if mode == "rotate-left":
            return self._rotate_image(source, -90, "-linksom")
        if mode == "rotate-right":
            return self._rotate_image(source, 90, "-rechtsom")

        raise ValueError(f"onbekende bewerking: {mode}")

    def _convert_to_jpg(self, source: Path) -> Path:
        destination = self._available_destination(source, ".jpg")
        if source.suffix.lower() in {".heic", ".heif", ".avif"}:
            self._require_command("heif-convert")
            command = ["heif-convert", "-q", "95", str(source), str(destination)]
        else:
            self._require_command("magick")
            command = [
                "magick", str(source), "-auto-orient", "-quality", "95",
                str(destination),
            ]
        self._run_command(command, destination)
        return destination

    def _convert_to_small_jpg(self, source: Path) -> Path:
        self._require_command("magick")
        destination = self._available_named_destination(source, "-2048px", ".jpg")
        command = [
            "magick", str(source), "-auto-orient", "-resize", "2048x2048>",
            "-quality", "92", str(destination),
        ]
        self._run_command(command, destination)
        return destination

    def _convert_to_png(self, source: Path) -> Path:
        destination = self._available_destination(source, ".png")
        if source.suffix.lower() in {".heic", ".heif", ".avif"}:
            self._require_command("heif-convert")
            command = ["heif-convert", str(source), str(destination)]
        else:
            self._require_command("magick")
            command = ["magick", str(source), "-auto-orient", str(destination)]
        self._run_command(command, destination)
        return destination

    def _convert_to_webp(self, source: Path) -> Path:
        self._require_command("magick")
        destination = self._available_destination(source, ".webp")
        command = [
            "magick", str(source), "-auto-orient", "-quality", "90",
            str(destination),
        ]
        self._run_command(command, destination)
        return destination

    def _rotate_image(self, source: Path, degrees: int, name_suffix: str) -> Path:
        self._require_command("magick")
        destination = self._available_named_destination(
            source, name_suffix, source.suffix.lower()
        )
        command = [
            "magick", str(source), "-auto-orient", "-rotate", str(degrees),
            "+repage", str(destination),
        ]
        self._run_command(command, destination)
        return destination

    def _run_command(self, command: list[str], destination: Path) -> None:
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            error_message = (
                result.stderr.strip()
                or result.stdout.strip()
                or f"programma stopte met code {result.returncode}"
            )
            raise RuntimeError(error_message)

        if not destination.exists() or destination.stat().st_size == 0:
            try:
                destination.unlink(missing_ok=True)
            except OSError:
                pass
            raise RuntimeError("uitvoerbestand is niet aangemaakt of is leeg")

    def _available_destination(self, source: Path, extension: str) -> Path:
        candidate = source.with_suffix(extension)
        if candidate != source and not candidate.exists():
            return candidate

        number = 1
        while True:
            candidate = source.with_name(f"{source.stem}-{number}{extension}")
            if not candidate.exists():
                return candidate
            number += 1

    def _available_named_destination(
        self,
        source: Path,
        name_suffix: str,
        extension: str,
    ) -> Path:
        candidate = source.with_name(f"{source.stem}{name_suffix}{extension}")
        if not candidate.exists():
            return candidate

        number = 1
        while True:
            candidate = source.with_name(
                f"{source.stem}{name_suffix}-{number}{extension}"
            )
            if not candidate.exists():
                return candidate
            number += 1

    def _refresh_directories(
        self,
        source_paths: list[Path],
        output_paths: list[Path],
    ) -> bool:
        directories = {path.parent for path in source_paths + output_paths}

        for directory in directories:
            try:
                os.utime(directory, None)
            except OSError:
                pass

            marker = directory / ".nautilus-image-converter-refresh"
            try:
                marker.touch(exist_ok=True)
                marker.unlink(missing_ok=True)
            except OSError:
                pass

        return False

    def _write_error_log(self, failures: list[str]) -> None:
        error_log = Path.home() / ".cache" / "nautilus-image-converter.log"
        try:
            error_log.parent.mkdir(parents=True, exist_ok=True)
            error_log.write_text("\n".join(failures) + "\n", encoding="utf-8")
        except OSError:
            pass

    def _require_command(self, command: str) -> None:
        if shutil.which(command) is None:
            raise RuntimeError(f"vereist programma ontbreekt: {command}")

    def _notify(self, title: str, message: str, error: bool = False) -> None:
        if shutil.which("notify-send") is None:
            return

        icon = "dialog-error" if error else "image-x-generic"
        subprocess.run(
            [
                "notify-send",
                "--app-name=Nautilus Image Converter",
                f"--icon={icon}",
                title,
                message,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
PY

chmod 0644 "$EXTENSION_FILE"
python3 -m py_compile "$EXTENSION_FILE"

# Nautilus will load the extension on its next start. Ignore failure when it is not running.
nautilus -q >/dev/null 2>&1 || true

echo "Nautilus image converter installed: $EXTENSION_FILE"
