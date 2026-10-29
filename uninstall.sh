#!/bin/sh

# Remove what install.sh added for the current user. Packages stay, since other apps may use them.
set -eu

bin=$HOME/.local/bin/ocr-copy
nautilus_script="${XDG_DATA_HOME:-$HOME/.local/share}/nautilus/scripts/Copy chữ từ ảnh"
media_keys=org.gnome.settings-daemon.plugins.media-keys
kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ocr-copy/

if gsettings list-keys "$media_keys" >/dev/null 2>&1; then
    list=$(gsettings get "$media_keys" custom-keybindings |
        sed "s|'$kb'||; s|\[, |[|; s|, , |, |; s|, \]|]|")
    [ "$list" != '[]' ] || list='@as []'
    gsettings set "$media_keys" custom-keybindings "$list"
    for key in name command binding; do
        gsettings reset "$media_keys.custom-keybinding:$kb" "$key"
    done
fi

rm -f "$nautilus_script" "$bin"
printf '%s\n' 'Đã gỡ ocr-copy, phím tắt Super+Shift+T và mục chuột phải trong Files.'
