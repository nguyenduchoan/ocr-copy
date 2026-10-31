#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$TesseractPath = $env:OCR_TESSERACT,
    [string]$Language = $env:OCR_LANG
)

$ErrorActionPreference = 'Stop'
try {
    if ($env:OS -ne 'Windows_NT') { throw 'Script này dành cho Windows 10/11. Trên Debian/GNOME, chạy ./install.sh.' }
    Import-Module (Join-Path $PSScriptRoot 'windows\OcrCopy.psm1') -Force
    if (-not $Language) { $Language = 'vie+eng' }
    $tesseract = Resolve-OcrTesseract $TesseractPath
    Assert-OcrLanguage $tesseract $Language

    $destination = Join-Path $env:LOCALAPPDATA 'Programs\ocr-copy'
    $desktopScript = Join-Path $destination 'ocr-copy.ps1'
    $files = @('ocr-copy.ps1', 'ocr-copy.cmd', 'uninstall.ps1', 'LICENSE',
        'windows\OcrCopy.psm1', 'windows\ScreenCapture.cs')
    foreach ($relative in $files) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $relative) -PathType Leaf)) {
            throw "Thiếu file trong bộ cài: $relative. Hãy tải và giải nén đầy đủ repo."
        }
    }
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $desktopScript
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $null
    try {
        $startMenu = [Environment]::GetFolderPath('Programs')
        [void][System.IO.Directory]::CreateDirectory($startMenu)
        $shortcutPath = Join-Path $startMenu 'ocr-copy.lnk'
        $existingShortcut = Test-Path -LiteralPath $shortcutPath
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $ownedArgument = '(?:^|\s)-File\s+"' + [regex]::Escape($desktopScript) + '"(?:\s|$)'
        if ($existingShortcut -and $shortcut.Arguments -notmatch $ownedArgument) {
            throw 'Shortcut ocr-copy trong Start đang thuộc ứng dụng khác. Đổi tên shortcut đó rồi chạy lại.'
        }
        [void][System.IO.Directory]::CreateDirectory((Join-Path $destination 'windows'))
        foreach ($relative in $files) {
            $source = Join-Path $PSScriptRoot $relative
            $target = Join-Path $destination $relative
            if ([System.IO.Path]::GetFullPath($source) -ne [System.IO.Path]::GetFullPath($target)) {
                Copy-Item -LiteralPath $source -Destination $target -Force
            }
        }
        # Store data, not a command string, so the shortcut and CLI share defaults.
        $settings = @{ TesseractPath = $tesseract; Language = $Language } | ConvertTo-Json
        [System.IO.File]::WriteAllText((Join-Path $destination 'settings.json'), $settings,
            (New-Object System.Text.UTF8Encoding $true))
        $shortcut.TargetPath = $powershell
        $shortcut.Arguments = $arguments
        $shortcut.WorkingDirectory = $destination
        $shortcut.Description = 'Kéo chọn vùng màn hình và copy chữ'
        if (-not $existingShortcut) { $shortcut.Hotkey = 'CTRL+ALT+T' }
        $shortcut.Save()
    }
    finally {
        if ($shortcut) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) }
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
    }
    Write-Output 'Đã cài ocr-copy cho tài khoản hiện tại. Mở ocr-copy trong Start hoặc nhấn Ctrl+Alt+T.'
    Write-Output 'Đổi phím tắt: Start > ocr-copy > Open file location > Properties > Shortcut key.'
    Write-Output "Lệnh dùng trong Terminal: & `"$destination\ocr-copy.cmd`" [ẢNH...]"
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
