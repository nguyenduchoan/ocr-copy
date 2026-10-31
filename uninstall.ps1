#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
try {
    if ($env:OS -ne 'Windows_NT') { throw 'Script này dành cho Windows 10/11. Trên Debian/GNOME, chạy ./uninstall.sh.' }
    $destination = Join-Path $env:LOCALAPPDATA 'Programs\ocr-copy'
    $shortcutPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'ocr-copy.lnk'
    # Remove only our shortcut, even if the user has replaced it since installation.
    if (Test-Path -LiteralPath $shortcutPath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $null
        try {
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $ownedArgument = '(?:^|\s)-File\s+"' + [regex]::Escape((Join-Path $destination 'ocr-copy.ps1')) + '"(?:\s|$)'
            if ($shortcut.Arguments -match $ownedArgument) {
                Remove-Item -LiteralPath $shortcutPath -Force
            }
        }
        finally {
            if ($shortcut) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) }
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
        }
    }
    # Keep unrelated files and the separately installed Tesseract/language data.
    foreach ($relative in @('ocr-copy.ps1', 'ocr-copy.cmd', 'uninstall.ps1', 'LICENSE', 'settings.json',
            'windows\OcrCopy.psm1', 'windows\ScreenCapture.cs')) {
        $target = Join-Path $destination $relative
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
    }
    foreach ($directory in @((Join-Path $destination 'windows'), $destination)) {
        if ((Test-Path -LiteralPath $directory -PathType Container) -and
            @(Get-ChildItem -LiteralPath $directory -Force).Count -eq 0) {
            Remove-Item -LiteralPath $directory -Force
        }
    }
    Write-Output 'Đã gỡ ocr-copy và phím tắt Windows. Tesseract cùng dữ liệu ngôn ngữ được giữ lại.'
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
