#!/bin/sh

# Install ocr-copy for the current user: packages, command, Files menu entry and shortcut.
set -eu

cd "$(dirname "$0")"

bin=$HOME/.local/bin/ocr-copy
nautilus_script="${XDG_DATA_HOME:-$HOME/.local/share}/nautilus/scripts/Copy chữ từ ảnh"
media_keys=org.gnome.settings-daemon.plugins.media-keys
kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ocr-copy/

if [ "$(id -u)" -eq 0 ]; then
    printf '%s\n' 'Hãy chạy bằng tài khoản thường, không dùng sudo. Script sẽ tự hỏi mật khẩu khi cần.' >&2
    exit 1
fi

printf '%s\n' 'Đang cài các gói cần thiết (nhập mật khẩu sudo nếu được hỏi)...'
sudo apt-get update
sudo apt-get install -y tesseract-ocr tesseract-ocr-vie gnome-screenshot \
    wl-clipboard xclip libnotify-bin python3-gi gir1.2-gdkpixbuf-2.0

install -Dm755 ocr-copy "$bin"
mkdir -p "${nautilus_script%/*}"
ln -sfn "$bin" "$nautilus_script"
printf '%s\n' "Đã cài lệnh vào $bin và mục chuột phải trong Files."

if gsettings list-keys "$media_keys" >/dev/null 2>&1; then
    # Append to the user's own shortcuts instead of replacing them.
    list=$(gsettings get "$media_keys" custom-keybindings)
    case $list in
        *"'$kb'"*) ;;
        '@as []'|'[]') gsettings set "$media_keys" custom-keybindings "['$kb']" ;;
        *) gsettings set "$media_keys" custom-keybindings "${list%]}, '$kb']" ;;
    esac
    schema=$media_keys.custom-keybinding:$kb
    gsettings set "$schema" name 'Copy chữ từ ảnh'
    gsettings set "$schema" command "$bin"
    gsettings set "$schema" binding '<Shift><Super>t'
    printf '%s\n' 'Đã gán phím tắt Super+Shift+T.'
else
    printf '%s\n' 'Không tìm thấy GNOME nên chưa gán phím tắt. Hãy tự gán phím tắt chạy lệnh:' "  $bin"
fi

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) printf '%s\n' 'Lệnh ocr-copy sẽ dùng được trong Terminal sau khi đăng xuất và đăng nhập lại.' ;;
esac
printf '%s\n' 'Hoàn tất. Nhấn Super+Shift+T rồi kéo chọn vùng có chữ để copy.'
