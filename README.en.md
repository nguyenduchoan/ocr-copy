# ocr-copy

[![ShellCheck](https://github.com/nguyenduchoan/ocr-copy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/nguyenduchoan/ocr-copy/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[Tiếng Việt](README.md) | **English**

Copy text from anything on your screen on Linux, like Live Text on macOS.

Press **Super+Shift+T**, drag over any part of the screen (an image, a video, a
PDF, a web page, an app window…) and paste with **Ctrl+V**. `ocr-copy` reads the
text in that area with [Tesseract][tesseract] and puts it on the clipboard.
Everything runs on your machine; no image ever leaves it.

## Features

- Recognizes Vietnamese (with diacritics) and English by default (`vie+eng`);
  any other Tesseract language works too.
- Three ways to use it: a keyboard shortcut, a right-click entry in Files
  (Nautilus) and the command line.
- Works on both Wayland and Xorg.
- Shows a notification with the start of the copied text.
- Offline: no account, no API key.
- Just a few short POSIX shell scripts, easy to read and change.

## Requirements

- Debian 12 or 13 with GNOME. Debian-based distributions such as Ubuntu may
  work but have not been tested.
- `sudo` rights to install these packages:

| Package | Used for |
| --- | --- |
| `tesseract-ocr`, `tesseract-ocr-vie` | Text recognition |
| `gnome-screenshot` | Selecting a screen area |
| `wl-clipboard`, `xclip` | Copying to the clipboard |
| `libnotify-bin` | Notifications |
| `python3-gi`, `gir1.2-gdkpixbuf-2.0` | Upscaling the image before recognition |

## Installation

Run it as your normal user, without `sudo`. The script asks for your password
when it installs packages.

**From source:**

```sh
git clone https://github.com/nguyenduchoan/ocr-copy.git
cd ocr-copy
./install.sh
```

**From a release:** download `ocr-copy-<version>.tar.gz` from the
[Releases][releases] page, open a terminal in its folder and run:

```sh
tar -xzf ocr-copy-*.tar.gz
./ocr-copy/install.sh
```

`install.sh` will:

1. Install the packages above with APT.
2. Copy the command to `~/.local/bin/ocr-copy`.
3. Add a **Scripts > Copy chữ từ ảnh** right-click entry in Files.
4. Bind Super+Shift+T. Custom shortcuts you already made in Settings >
   Keyboard are kept.

To update, get the new version (`git pull` or a newer release) and run
`install.sh` again.

If `~/.local/bin` did not exist before, log out and back in so the `ocr-copy`
command is found in the terminal.

## Usage

### Shortcut

Press **Super+Shift+T**, drag over the text, then paste with **Ctrl+V**. Press
Esc to cancel.

To change the key, go to Settings > Keyboard > View and Customize Shortcuts >
Custom Shortcuts > **Copy chữ từ ảnh**.

### Files (Nautilus)

Select one or more images, right-click > **Scripts** > **Copy chữ từ ảnh**. Text
from several images is joined with a blank line between them.

### Command line

```sh
ocr-copy                             # select a screen area
ocr-copy image.png                   # read one image
ocr-copy page1.png page2.jpg         # several images at once
ocr-copy receipt.png > receipt.txt   # the text is also printed to stdout
ocr-copy --help
```

Messages and notifications are in Vietnamese.

## Configuration

The `OCR_LANG` environment variable sets the recognition languages and defaults
to `vie+eng`:

```sh
OCR_LANG=eng ocr-copy image.png
```

Plain English text is usually recognized more accurately with `eng`. Other
languages need the matching `tesseract-ocr-<code>` package, for example
Japanese:

```sh
sudo apt install tesseract-ocr-jpn
OCR_LANG=jpn+eng ocr-copy image.png
```

List installed languages with `tesseract --list-langs`.

To make the shortcut use another language, change its command in Settings to
`env OCR_LANG=eng /home/<you>/.local/bin/ocr-copy`. Running `install.sh` again
resets it.

## How it works

1. `gnome-screenshot --area` lets you drag over an area and saves it as a
   temporary image.
2. The image is upscaled 2x with GdkPixbuf. Screen text is only around 96 DPI,
   and Tesseract reads small glyphs far better when they are larger. Images over
   4 megapixels are left as they are.
3. Tesseract reads the text using `OCR_LANG`. If it finds nothing, the script
   retries treating the whole image as one block of text (`--psm 6`), which
   catches areas holding a single line.
4. The text goes to the clipboard through `xclip` when XWayland is available,
   otherwise through `wl-copy`. On GNOME Wayland, `wl-copy` hangs when started
   from a shortcut because it has no keyboard focus. GNOME shares the XWayland
   clipboard with every app, so the text pastes anywhere.
5. A notification shows the start of the copied text. Temporary files are
   removed right away.

## Uninstall

From the source folder (or the folder extracted from a release):

```sh
./uninstall.sh
```

This removes the command, the shortcut and the right-click entry. Packages
installed with APT stay, since other apps may use them.

## Troubleshooting

- **Nothing happens on the shortcut:** check that it is still listed in
  Settings > Keyboard, then run `ocr-copy` in a terminal to see the error.
- **"Thiếu lệnh …" (missing command):** run `install.sh` again to install the
  packages.
- **"Không tìm thấy chữ trong ảnh" (no text found):** the area is too small,
  the text too blurry, handwritten, or on a busy background. Try a slightly
  larger area.
- **Wrong letters or diacritics:** zoom in on the content (Ctrl++) before
  selecting. For English-only text, use `OCR_LANG=eng`.

If it still fails, please [open an issue][issues] with your environment
details.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md); issues and
pull requests in English are fine.

## License

[MIT](LICENSE)

## Acknowledgements

[Tesseract OCR][tesseract], [gnome-screenshot][gnome-screenshot],
[wl-clipboard][wl-clipboard] and [xclip][xclip].

[tesseract]: https://github.com/tesseract-ocr/tesseract
[gnome-screenshot]: https://gitlab.gnome.org/GNOME/gnome-screenshot
[wl-clipboard]: https://github.com/bugaevc/wl-clipboard
[xclip]: https://github.com/astrand/xclip
[releases]: https://github.com/nguyenduchoan/ocr-copy/releases
[issues]: https://github.com/nguyenduchoan/ocr-copy/issues
