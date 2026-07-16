#!/usr/bin/env python3
from __future__ import annotations

import concurrent.futures
import hashlib
import os
import re
import shutil
import subprocess
import tempfile
import threading
from pathlib import Path
from typing import Sequence

from gi.repository import GObject, GLib, Nautilus

IMAGE_EXTENSIONS = {'.heic','.heif','.avif','.jpg','.jpeg','.png','.webp','.tif','.tiff','.bmp'}
HEIF_EXTENSIONS = {'.heic','.heif','.avif'}
VIDEO_EXTENSIONS = {'.webm','.mp4','.m4v','.mov','.mkv','.avi','.mpeg','.mpg','.ts','.mts','.m2ts','.ogv'}
MEDIA_EXTENSIONS = IMAGE_EXTENSIONS | VIDEO_EXTENSIONS
LOG_PATH = Path.home()/'.cache'/'doorsecure-workstation-tools.log'
MAX_IMAGE_WORKERS = max(1,min(6,os.cpu_count() or 2))
MAX_VIDEO_WORKERS = 2

class WorkstationTools(GObject.GObject, Nautilus.MenuProvider):
    def get_file_items(self, files: Sequence[Nautilus.FileInfo]):
        paths=self._paths(files)
        if not paths:
            return []
        root=Nautilus.MenuItem(name='WorkstationTools::Root',label='Workstation Tools',tip='Media, OCR, QR, metadata en pad-acties',icon='applications-utilities-symbolic')
        menu=Nautilus.Menu()
        images=[p for p in paths if p.suffix.lower() in IMAGE_EXTENSIONS]
        videos=[p for p in paths if p.suffix.lower() in VIDEO_EXTENSIONS]
        if images:
            item=Nautilus.MenuItem(name='WorkstationTools::Images',label='Afbeeldingen',tip='Afbeeldingen converteren en bewerken')
            sub=Nautilus.Menu()
            for ident,label,mode in [
                ('Jpg','Naar JPG - hoge kwaliteit','img-jpg'),
                ('JpgSmall','Naar JPG - maximaal 2048 px','img-jpg-small'),
                ('Png','Naar PNG','img-png'),
                ('Webp','Naar WebP - hoge kwaliteit','img-webp'),
                ('Left','Roteer 90 graden linksom','img-left'),
                ('Right','Roteer 90 graden rechtsom','img-right'),
            ]: self._action(sub,ident,label,images,mode)
            item.set_submenu(sub); menu.append_item(item)
        if videos:
            item=Nautilus.MenuItem(name='WorkstationTools::Videos',label='Video',tip='Video converteren met FFmpeg')
            sub=Nautilus.Menu()
            for ident,label,mode in [
                ('Mp4','Naar MP4 - compatibel','vid-mp4'),
                ('Mp4Fast','Naar MP4 - snel indien mogelijk','vid-mp4-fast'),
                ('Webm','Naar WebM - hoge kwaliteit','vid-webm'),
                ('WebmSmall','Naar WebM - kleiner bestand','vid-webm-small'),
                ('Mp3','Alleen audio naar MP3','vid-mp3'),
                ('Opus','Alleen audio naar Opus','vid-opus'),
            ]: self._action(sub,ident,label,videos,mode)
            item.set_submenu(sub); menu.append_item(item)
        if images:
            item=Nautilus.MenuItem(name='WorkstationTools::Recognition',label='OCR en QR',tip='Tekst en QR-codes herkennen')
            sub=Nautilus.Menu()
            self._action(sub,'OCR','Tekst herkennen en kopieren',images,'ocr')
            self._action(sub,'QR','QR/barcode lezen en kopieren',images,'qr-copy')
            self._action(sub,'QROpen','QR-link openen',images,'qr-open')
            item.set_submenu(sub); menu.append_item(item)
        util=Nautilus.MenuItem(name='WorkstationTools::Utilities',label='Bestandsinformatie',tip='Metadata, hashes en paden')
        usub=Nautilus.Menu()
        self._action(usub,'Metadata','Metadata kopieren',paths,'metadata')
        self._action(usub,'Hash','SHA-256 kopieren',paths,'hash')
        self._action(usub,'Path','Volledig pad kopieren',paths,'path')
        self._action(usub,'Markdown','Markdown-link kopieren',paths,'markdown')
        util.set_submenu(usub); menu.append_item(util)
        root.set_submenu(menu)
        return [root]

    def _action(self, menu, ident, label, paths, mode):
        item=Nautilus.MenuItem(name=f'WorkstationTools::{ident}',label=label,tip=label)
        item.connect('activate',self._activate,paths.copy(),mode)
        menu.append_item(item)

    def _paths(self, files):
        out=[]
        for info in files:
            loc=info.get_location(); s=loc.get_path() if loc else None
            if s and Path(s).is_file(): out.append(Path(s))
        return out

    def _activate(self,_item,paths,mode):
        threading.Thread(target=self._run_action,args=(paths,mode),daemon=True).start()

    def _run_action(self,paths,mode):
        try:
            if mode.startswith('img-'): self._batch(paths,mode,MAX_IMAGE_WORKERS)
            elif mode.startswith('vid-'): self._batch(paths,mode,MAX_VIDEO_WORKERS)
            elif mode=='ocr': self._ocr(paths)
            elif mode in {'qr-copy','qr-open'}: self._qr(paths,mode=='qr-open')
            elif mode=='metadata': self._metadata(paths)
            elif mode=='hash': self._hash(paths)
            elif mode=='path': self._copy('\n'.join(str(p) for p in paths),'Pad gekopieerd')
            elif mode=='markdown': self._copy('\n'.join(f'[{p.name}]({p.as_uri()})' for p in paths),'Markdown-link gekopieerd')
        except Exception as exc:
            self._log([str(exc)]); self._notify('Workstation Tools',str(exc),True)

    def _batch(self,paths,mode,max_workers):
        self._notify('Bewerking gestart',f'{len(paths)} bestand(en) worden verwerkt.')
        ok=[]; bad=[]
        with concurrent.futures.ThreadPoolExecutor(max_workers=min(max_workers,max(1,len(paths)))) as pool:
            fmap={pool.submit(self._one,p,mode):p for p in paths}
            for f in concurrent.futures.as_completed(fmap):
                try: ok.append(f.result())
                except Exception as exc: bad.append(f'{fmap[f].name}: {exc}')
        GLib.idle_add(self._refresh,paths,ok)
        if bad:
            self._log(bad); self._notify('Bewerking voltooid',f'{len(ok)} gelukt, {len(bad)} mislukt. Zie {LOG_PATH}.',True)
        else: self._notify('Bewerking voltooid',f'{len(ok)} bestand(en) succesvol aangemaakt.')

    def _one(self,src,mode):
        if mode=='img-jpg': return self._img_jpg(src)
        if mode=='img-jpg-small': return self._img_small(src)
        if mode=='img-png': return self._img_png(src)
        if mode=='img-webp': return self._img_webp(src)
        if mode=='img-left': return self._img_rotate(src,-90,'-linksom')
        if mode=='img-right': return self._img_rotate(src,90,'-rechtsom')
        if mode=='vid-mp4': return self._vid_mp4(src,False)
        if mode=='vid-mp4-fast': return self._vid_mp4(src,True)
        if mode=='vid-webm': return self._vid_webm(src,False)
        if mode=='vid-webm-small': return self._vid_webm(src,True)
        if mode=='vid-mp3': return self._vid_audio(src,'.mp3','libmp3lame','192k')
        if mode=='vid-opus': return self._vid_audio(src,'.opus','libopus','128k')
        raise RuntimeError('Onbekende actie')

    def _img_jpg(self,src):
        dst=self._dest(src,'.jpg')
        if src.suffix.lower() in HEIF_EXTENSIONS: self._cmd(['heif-convert','-q','95',str(src),str(dst)],dst)
        else: self._cmd(['magick',str(src),'-auto-orient','-quality','95',str(dst)],dst)
        return dst
    def _img_png(self,src):
        dst=self._dest(src,'.png')
        if src.suffix.lower() in HEIF_EXTENSIONS: self._cmd(['heif-convert',str(src),str(dst)],dst)
        else: self._cmd(['magick',str(src),'-auto-orient',str(dst)],dst)
        return dst
    def _magick_input(self,src):
        if src.suffix.lower() not in HEIF_EXTENSIONS: return src,None
        fd,name=tempfile.mkstemp(prefix='ws-tools-',suffix='.png'); os.close(fd); tmp=Path(name)
        self._cmd(['heif-convert',str(src),str(tmp)],tmp); return tmp,tmp
    def _img_small(self,src):
        dst=self._named(src,'-2048px','.jpg'); inp,tmp=self._magick_input(src)
        try: self._cmd(['magick',str(inp),'-auto-orient','-resize','2048x2048>','-quality','92',str(dst)],dst)
        finally:
            if tmp: tmp.unlink(missing_ok=True)
        return dst
    def _img_webp(self,src):
        dst=self._dest(src,'.webp'); inp,tmp=self._magick_input(src)
        try: self._cmd(['magick',str(inp),'-auto-orient','-quality','90',str(dst)],dst)
        finally:
            if tmp: tmp.unlink(missing_ok=True)
        return dst
    def _img_rotate(self,src,degrees,suffix):
        ext='.jpg' if src.suffix.lower() in HEIF_EXTENSIONS else src.suffix.lower()
        dst=self._named(src,suffix,ext); inp,tmp=self._magick_input(src)
        try:
            cmd=['magick',str(inp),'-auto-orient','-rotate',str(degrees),'+repage']
            if ext in {'.jpg','.jpeg'}: cmd += ['-quality','95']
            cmd.append(str(dst)); self._cmd(cmd,dst)
        finally:
            if tmp: tmp.unlink(missing_ok=True)
        return dst

    def _vid_mp4(self,src,fast):
        dst=self._dest(src,'.mp4')
        if fast:
            try:
                self._ffmpeg(['-i',str(src),'-map','0','-c','copy','-movflags','+faststart',str(dst)],dst)
                return dst
            except Exception: dst.unlink(missing_ok=True)
        self._ffmpeg(['-i',str(src),'-map','0:v:0?','-map','0:a:0?','-vf','pad=ceil(iw/2)*2:ceil(ih/2)*2','-c:v','libx264','-preset','medium','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-movflags','+faststart',str(dst)],dst)
        return dst
    def _vid_webm(self,src,small):
        dst=self._dest(src,'.webm')
        self._ffmpeg(['-i',str(src),'-map','0:v:0?','-map','0:a:0?','-vf','pad=ceil(iw/2)*2:ceil(ih/2)*2','-c:v','libvpx-vp9','-crf','35' if small else '28','-b:v','0','-row-mt','1','-deadline','good','-cpu-used','4' if small else '2','-c:a','libopus','-b:a','96k' if small else '160k',str(dst)],dst)
        return dst
    def _vid_audio(self,src,ext,codec,bitrate):
        dst=self._dest(src,ext); self._ffmpeg(['-i',str(src),'-vn','-c:a',codec,'-b:a',bitrate,str(dst)],dst); return dst
    def _ffmpeg(self,args,dst):
        tmp=dst.with_name(dst.stem+'.part'+dst.suffix)
        args=[str(tmp) if x==str(dst) else x for x in args]
        try: self._cmd(['ffmpeg','-hide_banner','-y',*args],tmp); tmp.replace(dst)
        except Exception: tmp.unlink(missing_ok=True); raise

    def _ocr(self,paths):
        texts=[]
        for p in paths:
            inp,tmp=self._ocr_input(p)
            try:
                r=subprocess.run(['tesseract',str(inp),'stdout','-l','eng+nld'],capture_output=True,text=True)
                if r.returncode: raise RuntimeError(r.stderr.strip())
                texts.append(f'--- {p.name} ---\n{r.stdout.strip()}')
            finally:
                if tmp: tmp.unlink(missing_ok=True)
        self._copy('\n\n'.join(texts),'OCR-tekst gekopieerd')
    def _ocr_input(self,p):
        if p.suffix.lower() not in HEIF_EXTENSIONS: return p,None
        fd,name=tempfile.mkstemp(prefix='ws-ocr-',suffix='.png'); os.close(fd); tmp=Path(name)
        self._cmd(['heif-convert',str(p),str(tmp)],tmp); return tmp,tmp
    def _qr(self,paths,open_link):
        values=[]
        for p in paths:
            inp,tmp=self._ocr_input(p)
            try:
                r=subprocess.run(['zbarimg','--quiet','--raw',str(inp)],capture_output=True,text=True)
                if r.returncode not in (0,4): raise RuntimeError(r.stderr.strip())
                values += [x for x in r.stdout.splitlines() if x.strip()]
            finally:
                if tmp: tmp.unlink(missing_ok=True)
        if not values: raise RuntimeError('Geen QR-code of barcode gevonden.')
        self._copy('\n'.join(values),'QR-inhoud gekopieerd')
        if open_link:
            for v in values:
                if re.match(r'^https?://',v,re.I): subprocess.Popen(['xdg-open',v],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    def _metadata(self,paths):
        chunks=[]
        for p in paths:
            if shutil.which('exiftool'):
                r=subprocess.run(['exiftool',str(p)],capture_output=True,text=True)
            elif p.suffix.lower() in VIDEO_EXTENSIONS:
                r=subprocess.run(['ffprobe','-hide_banner',str(p)],capture_output=True,text=True)
                r.stdout=r.stderr
            else: raise RuntimeError('Installeer exiftool voor metadata.')
            chunks.append(f'--- {p.name} ---\n{r.stdout.strip()}')
        self._copy('\n\n'.join(chunks),'Metadata gekopieerd')
    def _hash(self,paths):
        lines=[]
        for p in paths:
            h=hashlib.sha256()
            with p.open('rb') as f:
                for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
            lines.append(f'{h.hexdigest()}  {p.name}')
        self._copy('\n'.join(lines),'SHA-256 gekopieerd')

    def _copy(self,text,title):
        if shutil.which('wl-copy'): subprocess.run(['wl-copy'],input=text,text=True,check=True)
        elif shutil.which('xclip'): subprocess.run(['xclip','-selection','clipboard'],input=text,text=True,check=True)
        else: raise RuntimeError('Geen clipboard-tool gevonden (wl-copy/xclip).')
        self._notify(title,text[:160] if text else 'Klaar')
    def _cmd(self,cmd,dst):
        if not shutil.which(cmd[0]): raise RuntimeError(f'Vereist programma ontbreekt: {cmd[0]}')
        r=subprocess.run(cmd,capture_output=True,text=True)
        if r.returncode:
            dst.unlink(missing_ok=True); raise RuntimeError((r.stderr or r.stdout).strip())
        if not dst.exists() or dst.stat().st_size==0: dst.unlink(missing_ok=True); raise RuntimeError('Uitvoerbestand is leeg of ontbreekt.')
    def _dest(self,src,ext):
        c=src.with_suffix(ext); i=1
        while c==src or c.exists(): c=src.with_name(f'{src.stem}-{i}{ext}'); i+=1
        return c
    def _named(self,src,suffix,ext):
        c=src.with_name(f'{src.stem}{suffix}{ext}'); i=1
        while c.exists(): c=src.with_name(f'{src.stem}{suffix}-{i}{ext}'); i+=1
        return c
    def _refresh(self,sources,outputs):
        for d in {p.parent for p in sources+outputs}:
            try:
                os.utime(d,None); m=d/'.workstation-tools-refresh'; m.touch(); m.unlink()
            except OSError: pass
        return False
    def _log(self,lines):
        LOG_PATH.parent.mkdir(parents=True,exist_ok=True); LOG_PATH.write_text('\n\n'.join(lines)+'\n')
    def _notify(self,title,msg,error=False):
        if shutil.which('notify-send'): subprocess.run(['notify-send','--app-name=Workstation Tools',f"--icon={'dialog-error' if error else 'applications-utilities'}",title,msg],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
