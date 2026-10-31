# ocr-copy

[![ShellCheck](https://github.com/nguyenduchoan/ocr-copy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/nguyenduchoan/ocr-copy/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[Tiếng Việt](README.md) | **English**

Copy text from anything on your screen on Linux and Windows, like Live Text on macOS.

Press **Super+Shift+T**, drag over any part of the screen (an image, a video, a
PDF, a web page, an app window…) and paste with **Ctrl+V**. `ocr-copy` reads the
text in that area with [Tesseract][tesseract] and puts it on the clipboard.
Everything runs on your machine; no image ever leaves it.

**Windows 10/11:** use the PowerShell version with **Ctrl+Alt+T**. See
[Windows setup](#windows-1011). The shell commands below target Linux/GNOME.

## Features

- Recognizes Vietnamese (with diacritics) and English by default (`vie+eng`);
  any other Tesseract language works too.
- Linux: a keyboard shortcut, a right-click entry in Files (Nautilus) and the
  command line; works on Wayland and Xorg.
- Windows 10/11: screen selection, one or more image files, Unicode clipboard,
  a Start shortcut and Ctrl+Alt+T; no WSL or Python required.
- Shows a notification with the start of the copied text.
- Offline: no account, no API key.
- POSIX shell scripts on Linux; PowerShell and Windows Forms on Windows.

## Windows 10/11

Requires Windows PowerShell 5.1 (the built-in `powershell.exe`), a desktop
session, and Tesseract 5 with `vie` and `eng` language data. Windows 10 version
1703 or newer is required for the screen selection DPI APIs.

1. Install Tesseract using the [Windows installer linked by Tesseract][windows-tesseract].
   Select **Vietnamese** in **Additional language data**; keep English enabled.
   Alternatively use `winget install --id UB-Mannheim.TesseractOCR --exact --interactive`
   and select the same languages in the setup wizard. Installing Tesseract may
   require administrator rights; installing ocr-copy does not.
2. Clone or download this repository. Open PowerShell in its folder and run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

3. Open **ocr-copy** from Start, or press **Ctrl+Alt+T**, drag over text and paste
   with **Ctrl+V**. Esc or right-click cancels and preserves the clipboard.

The installer copies the scripts to the current user's
`$env:LOCALAPPDATA\Programs\ocr-copy`, stores the selected engine/language in
`settings.json`, and creates a Start shortcut. It does not add a persistent
background process or change PATH. Run the installer again to update; a custom
shortcut key set in Properties is preserved.

To use the source directly or read image files:

```powershell
.\ocr-copy.cmd
.\ocr-copy.cmd .\image.png
.\ocr-copy.cmd '.\page 1.png' .\page2.jpg
.\ocr-copy.cmd .\image.png -Language eng -NoNotify
.\ocr-copy.cmd -Help
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
.\ocr-copy.cmd .\image.png -NoNotify | Out-File .\text.txt -Encoding utf8
```

Set `OutputEncoding` before piping the launcher's output in Windows PowerShell
5.1 so it decodes UTF-8 correctly. The clipboard uses Unicode directly.

`-Language` overrides `OCR_LANG`, then the saved installer setting; the default
is `vie+eng`. `-TesseractPath` similarly overrides `OCR_TESSERACT` and the saved
engine path. Without a saved path, ocr-copy searches PATH and the standard
Tesseract installation folders. For example:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
    -TesseractPath (Join-Path $env:ProgramFiles 'Tesseract-OCR\tesseract.exe') `
    -Language eng
```

To change the shortcut, find ocr-copy in Start, choose **Open file location**,
then edit **Properties > Shortcut key**. If Ctrl+Alt+T is already used, select
another key there. A newly created shortcut may require signing out and back
in before its hotkey is recognized. There is no Explorer right-click
integration in this version.

To uninstall, run this from the source folder:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

If the source is no longer available, run the `uninstall.ps1` in the installed
folder. It removes only ocr-copy files and its shortcut, keeping Tesseract and
unrelated files. `-ExecutionPolicy Bypass` applies only to the launched
PowerShell process; it does not change the system execution policy.

For missing language errors, rerun the Tesseract installer and add the required
languages, or copy the matching `.traineddata` from the [official models][tessdata]
into its `tessdata` folder. Set `TESSDATA_PREFIX` only if you deliberately use a
different data folder. Run `ocr-copy.cmd` in a terminal to see errors; append
`-NoNotify` to suppress notifications/error dialogs during scripting.

Automated core checks and a Windows integration workflow are included. The
interactive selector, hotkey, notifications, and mixed-DPI/multiple-monitor
behavior still require manual validation on Windows; see the
[validation record](docs/windows-validation.md).

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
[windows-tesseract]: https://tesseract-ocr.github.io/tessdoc/Installation.html#windows
[tessdata]: https://github.com/tesseract-ocr/tessdata_fast
