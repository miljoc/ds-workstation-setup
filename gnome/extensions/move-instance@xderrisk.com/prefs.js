import Adw from "gi://Adw";
import {
  ExtensionPreferences,
  gettext as _,
} from "resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js";

export default class MoveInstancePrefs extends ExtensionPreferences {
  fillPreferencesWindow(window) {
    const settings = this.getSettings();
    const page = new Adw.PreferencesPage();
    const group = new Adw.PreferencesGroup({
      title: _("WM_CLASS Configuration"),
      description: _("Add window class names (e.g., Spotify) to force moving."),
    });

    window.add(page);
    page.add(group);

    const row = new Adw.EntryRow({
      title: _("WM_CLASS List (comma separated)"),
      text: settings.get_strv("whitelist").join(", "),
    });

    row.connect("changed", (entry) => {
      let list = entry
        .get_text()
        .split(",")
        .map((s) => s.trim())
        .filter((s) => s !== "");
      settings.set_strv("whitelist", list);
    });

    group.add(row);
  }
}
