/* extension.js */

import GLib from 'gi://GLib';
import St from 'gi://St';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';

const Indicator = GObject.registerClass(
class Indicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, _('dev tools'));
        this.Clipboard = St.Clipboard.get_default();

        this.add_child(new St.Icon({
            icon_name: 'preferences-system-symbolic',
            style_class: 'system-status-icon',
        }));

        this.addUUIDUtils();
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this.addTimeUtils();
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this.addRC4Utils();
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this.addBase64Utils();
    }

    addUUIDUtils() {
        const baseMenuItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        const container = createContainer('UUID');
        const button = new St.Button({
            label: _('Copy random UUID'),
            can_focus: true,
            track_hover: true,
            style_class: 'button',
        });

        button.connect('clicked', copyUUID(this.Clipboard, this.menu));
        container.add_child(button);
        baseMenuItem.add_child(container);
        this.menu.addMenuItem(baseMenuItem);
    }

    addTimeUtils() {
        const baseMenuItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        const container = createContainer('Time Utilities');

        const copyTimeButton = new St.Button({
            label: _('Copy current time in seconds'),
            can_focus: true,
            track_hover: true,
            style_class: 'button',
        });

        copyTimeButton.connect('clicked', copyTimeInSeconds(this.Clipboard, this.menu));
        container.add_child(copyTimeButton);
        container.add_child(new St.Bin({style_class: 'spacer'}));

        const entry = new St.Entry({hint_text: 'enter unix timestamp in utc'});
        container.add_child(entry);

        const copySpacer1 = new St.Bin({style_class: 'spacer'});
        const copyRowUTC = createCopyRow(this.Clipboard, this.menu);
        const copySpacer2 = new St.Bin({style_class: 'spacer'});
        const copyRowLocal = createCopyRow(this.Clipboard, this.menu);

        entry.connect(
            'key_release_event',
            calculateDateTimeFromTimestamp(entry, container, copyRowUTC, copySpacer1, copySpacer2, copyRowLocal)
        );

        baseMenuItem.add_child(container);
        this.menu.addMenuItem(baseMenuItem);
    }

    addBase64Utils() {
        const baseMenuItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        const container = createContainer('Base64 Utilities');

        const base64Entry = new St.Entry({hint_text: 'enter base64 string to convert'});
        container.add_child(base64Entry);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const buttonContainer = new St.BoxLayout({x_expand: true});

        const downIcon = new St.Icon({icon_name: 'go-down-symbolic', icon_size: 14});
        const base64ToClearButton = new St.Button({
            can_focus: true,
            track_hover: true,
            style_class: 'button',
            child: downIcon,
        });

        const upIcon = new St.Icon({icon_name: 'go-up-symbolic', icon_size: 14});
        const clearToBase64Button = new St.Button({
            can_focus: true,
            track_hover: true,
            style_class: 'button',
            child: upIcon,
        });

        const cleartextEntry = new St.Entry({hint_text: 'enter clear text string to convert'});

        base64ToClearButton.connect('clicked', () => {
            cleartextEntry.set_text(base64decode(base64Entry.text));
        });

        clearToBase64Button.connect('clicked', () => {
            base64Entry.set_text(base64encode(cleartextEntry.text));
        });

        buttonContainer.add_child(new St.Bin({x_expand: true}));
        buttonContainer.add_child(base64ToClearButton);
        buttonContainer.add_child(new St.Bin({style_class: 'gap'}));
        buttonContainer.add_child(clearToBase64Button);
        buttonContainer.add_child(new St.Bin({x_expand: true}));

        container.add_child(buttonContainer);
        container.add_child(new St.Bin({style_class: 'gap'}));
        container.add_child(cleartextEntry);

        baseMenuItem.add_child(container);
        this.menu.addMenuItem(baseMenuItem);
    }

    addRC4Utils() {
        const baseMenuItem = new PopupMenu.PopupBaseMenuItem({reactive: false});
        const container = createContainer('RC4 Utilities');

        const encryptTitle = new St.Label({text: 'Encrypt clear text to base64 cipher'});
        container.add_child(encryptTitle);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const encryptTextEntry = new St.Entry({
            hint_text: 'enter clear text',
            x_expand: true,
        });
        container.add_child(encryptTextEntry);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const encryptKeyEntry = new St.Entry({
            hint_text: 'enter encryption key',
            x_expand: true,
        });
        container.add_child(encryptKeyEntry);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const encryptButton = new St.Button({
            label: _('Encrypt'),
            can_focus: true,
            track_hover: true,
            style_class: 'button',
        });

        const encryptOutputButton = new St.Button({
            label: _('click encrypted result to copy'),
            can_focus: true,
            track_hover: true,
            style_class: 'button',
            x_expand: true,
        });

        encryptOutputButton.connect('clicked', () => {
            const value = encryptOutputButton.get_label();

            if (!value || value === _('click encrypted result to copy'))
                return;

            this.Clipboard.set_text(St.ClipboardType.CLIPBOARD, value);
            Main.notify(`${value} copied to clipboard...`);
            this.menu.toggle();
        });

        encryptButton.connect('clicked', () => {
            const clearText = encryptTextEntry.get_text();
            const key = encryptKeyEntry.get_text();

            if (!key) {
                Main.notify(_('RC4 encryption key is required'));
                return;
            }

            const encrypted = rc4encryptToBase64(clearText, key);
            encryptOutputButton.set_label(encrypted);
        });

        container.add_child(encryptButton);
        container.add_child(new St.Bin({style_class: 'gap'}));
        container.add_child(encryptOutputButton);
        container.add_child(new St.Bin({style_class: 'spacer'}));

        const decryptTitle = new St.Label({text: 'Decrypt base64 cipher to clear text'});
        container.add_child(decryptTitle);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const decryptCipherEntry = new St.Entry({
            hint_text: 'enter base64 cipher text',
            x_expand: true,
        });
        container.add_child(decryptCipherEntry);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const decryptKeyEntry = new St.Entry({
            hint_text: 'enter decryption key',
            x_expand: true,
        });
        container.add_child(decryptKeyEntry);
        container.add_child(new St.Bin({style_class: 'gap'}));

        const decryptButton = new St.Button({
            label: _('Decrypt'),
            can_focus: true,
            track_hover: true,
            style_class: 'button',
        });

        const decryptOutputButton = new St.Button({
            label: _('click decrypted result to copy'),
            can_focus: true,
            track_hover: true,
            style_class: 'button',
            x_expand: true,
        });

        decryptOutputButton.connect('clicked', () => {
            const value = decryptOutputButton.get_label();

            if (!value || value === _('click decrypted result to copy'))
                return;

            this.Clipboard.set_text(St.ClipboardType.CLIPBOARD, value);
            Main.notify(`${value} copied to clipboard...`);
            this.menu.toggle();
        });

        decryptButton.connect('clicked', () => {
            const cipherText = decryptCipherEntry.get_text();
            const key = decryptKeyEntry.get_text();

            if (!key) {
                Main.notify(_('RC4 decryption key is required'));
                return;
            }

            const decrypted = rc4decryptFromBase64(cipherText, key);
            decryptOutputButton.set_label(decrypted);
        });

        container.add_child(decryptButton);
        container.add_child(new St.Bin({style_class: 'gap'}));
        container.add_child(decryptOutputButton);

        baseMenuItem.add_child(container);
        this.menu.addMenuItem(baseMenuItem);
    }
});

const createContainer = title => {
    const container = new St.BoxLayout({vertical: true, x_expand: true});
    container.add_child(new St.Label({text: title, style_class: 'title'}));
    return container;
};

const createCopyRow = (clipboard, menu) => {
    const row = new St.BoxLayout({style_class: 'row'});
    const label = new St.Label({text: '', x_expand: true});
    row.add_child(label);

    const copyIcon = new St.Icon({icon_name: 'edit-copy-symbolic', icon_size: 14});
    const copyButton = new St.Button({
        can_focus: true,
        track_hover: true,
        style_class: 'button',
        child: copyIcon,
    });

    copyButton.connect('clicked', () => {
        clipboard.set_text(St.ClipboardType.CLIPBOARD, label.get_text());
        Main.notify(`${label.get_text()} copied to clipboard...`);
        menu.toggle();
    });

    row.add_child(copyButton);
    return {row, label};
};

const copyUUID = (clipboard, menu) => () => {
    const uuid = GLib.uuid_string_random();
    clipboard.set_text(St.ClipboardType.CLIPBOARD, uuid);
    Main.notify(`${uuid} copied to clipboard...`);
    menu.toggle();
};

const copyTimeInSeconds = (clipboard, menu) => () => {
    const seconds = `${Math.floor(GLib.get_real_time() / 1000 / 1000)}`;
    clipboard.set_text(St.ClipboardType.CLIPBOARD, seconds);
    Main.notify(`${seconds} copied to clipboard...`);
    menu.toggle();
};

const calculateDateTimeFromTimestamp = (entry, container, utcRow, copySpacer1, copySpacer2, localRow) => () => {
    const unixTimestamp = parseInt(entry.text);

    if (isNaN(unixTimestamp)) {
        container.remove_child(copySpacer1);
        container.remove_child(utcRow.row);
        container.remove_child(copySpacer2);
        container.remove_child(localRow.row);
    } else {
        container.add_child(copySpacer1);
        container.add_child(utcRow.row);
        container.add_child(copySpacer2);
        container.add_child(localRow.row);

        const dateTime = GLib.DateTime.new_from_unix_utc(unixTimestamp);
        utcRow.label.set_text(dateTime.format_iso8601());

        const localTimeZone = GLib.TimeZone.new_local();
        const offsetInSeconds = localTimeZone.get_offset(unixTimestamp);
        const localDateTime = dateTime.add_seconds(offsetInSeconds).to_timezone(localTimeZone);

        localRow.label.set_text(localDateTime.format_iso8601());
    }

    return true;
};

const BASE64_STRING = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

const base64encode = string => {
    let output = '';
    const stringSafe = `${string}\0\0\0`;

    for (let index = 0; index < string.length; index += 3) {
        let value = 0;

        for (let i = 0; i < 3; i++)
            value = value * 256 + stringSafe.charCodeAt(index + i);

        const n = Math.min(string.length - index, 3);

        for (let i = 0; i < 4; i++)
            output += i <= n ? BASE64_STRING[Math.floor(value / Math.pow(64, 3 - i)) % 64] : '=';
    }

    return output;
};

const base64decode = string => {
    let output = '';

    for (let index = 0; index < string.length; index += 4) {
        let value = 0;
        let n = 3;

        for (let i = 0; i < 4; i++) {
            n -= string[index + i] === '=' ? 1 : 0;
            value = value * 64 + (string[index + i] === '=' ? 0 : BASE64_STRING.indexOf(string[index + i]));
        }

        for (let i = 0; i < n; i++)
            output += String.fromCharCode(Math.floor(value / Math.pow(256, 2 - i)) % 256);
    }

    return output;
};

const rc4keystream = (data, key) => {
    const s = [];

    for (let i = 0; i < 256; i++)
        s[i] = i;

    let j = 0;

    for (let i = 0; i < 256; i++) {
        j = (j + s[i] + key.charCodeAt(i % key.length)) % 256;
        [s[i], s[j]] = [s[j], s[i]];
    }

    let i = 0;
    j = 0;
    let output = '';

    for (let index = 0; index < data.length; index++) {
        i = (i + 1) % 256;
        j = (j + s[i]) % 256;
        [s[i], s[j]] = [s[j], s[i]];

        const keyByte = s[(s[i] + s[j]) % 256];
        output += String.fromCharCode(data.charCodeAt(index) ^ keyByte);
    }

    return output;
};

const rc4encryptToBase64 = (clearText, key) => {
    const encrypted = rc4keystream(clearText, key);
    return base64encode(encrypted);
};

const rc4decryptFromBase64 = (cipherText, key) => {
    const decodedCipher = base64decode(cipherText);
    return rc4keystream(decodedCipher, key);
};

export default class DevExtension extends Extension {
    enable() {
        this._indicator = new Indicator();
        Main.panel.addToStatusArea(this.metadata.uuid, this._indicator);

        this._mutterSettings = new Gio.Settings({schema_id: 'org.gnome.mutter'});
        this._previousOverlayKey = this._mutterSettings.get_string('overlay-key');
        this._mutterSettings.set_string('overlay-key', '');

        this._settings = this.getSettings();

        Main.wm.addKeybinding(
            'walker-shortcut',
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            () => {
                GLib.spawn_command_line_async('walker');
            }
        );
    }

    disable() {
        Main.wm.removeKeybinding('walker-shortcut');

        if (this._mutterSettings && this._previousOverlayKey !== null) {
            this._mutterSettings.set_string('overlay-key', this._previousOverlayKey);
            this._mutterSettings = null;
        }

        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }

        this._settings = null;
    }
}