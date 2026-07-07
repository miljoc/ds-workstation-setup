import * as Workspace from "resource:///org/gnome/shell/ui/workspace.js";
import {
  Extension,
  gettext as _,
} from "resource:///org/gnome/shell/extensions/extension.js";

let _originalAcceptDrop = null;
let _settings = null;

export default class MoveInstanceExtension extends Extension {
  enable() {
    _settings = this.getSettings();
    _originalAcceptDrop = Workspace.Workspace.prototype.acceptDrop;

    Workspace.Workspace.prototype.acceptDrop = function (source) {
      let app = source.app || (source.getApp ? source.getApp() : null);

      if (app && _settings) {
        let windows = app.get_windows();
        let whitelist = _settings.get_strv("whitelist");

        let hasMatchedWMClass = windows.some((window) => {
          let wmClass = window.get_wm_class();
          return (
            wmClass &&
            whitelist.some((item) =>
              wmClass.toLowerCase().includes(item.toLowerCase()),
            )
          );
        });

        let isSingleInstance = !app.can_open_new_window() || hasMatchedWMClass;

        if (isSingleInstance && windows.length > 0) {
          let windowToMove =
            windows.find((w) => w.get_window_type() === 0) || windows[0];
          if (windowToMove) {
            windowToMove.change_workspace(this.metaWorkspace);
            return true;
          }
        }
      }
      return _originalAcceptDrop.apply(this, arguments);
    };
  }

  disable() {
    if (_originalAcceptDrop) {
      Workspace.Workspace.prototype.acceptDrop = _originalAcceptDrop;
    }
    _originalAcceptDrop = null;
    _settings = null;
  }
}
