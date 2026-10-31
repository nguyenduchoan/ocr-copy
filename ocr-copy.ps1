#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$ImagePath = @(),
    [string]$Language = $env:OCR_LANG,
    [string]$TesseractPath = $env:OCR_TESSERACT,
    [switch]$NoNotify,
    [Alias('h')][switch]$Help
)

$ErrorActionPreference = 'Stop'
if ($Help) {
    @'
Cách dùng trên Windows: .\ocr-copy.ps1 [ẢNH...] [-Language vie+eng] [-NoNotify]

  .\ocr-copy.ps1                        Kéo chọn vùng màn hình; Esc để huỷ.
  .\ocr-copy.ps1 anh.png                Nhận dạng một ảnh và copy chữ.
  .\ocr-copy.ps1 trang1.png trang2.jpg   Nối chữ của nhiều ảnh bằng dòng trống.
  .\ocr-copy.ps1 -Help                  Hiển thị hướng dẫn này.

Mặc định: vie+eng; đổi bằng -Language hoặc biến OCR_LANG.
Chỉ định tesseract.exe bằng -TesseractPath hoặc biến OCR_TESSERACT.
Chữ được copy vào clipboard và in ra stdout. -NoNotify tắt thông báo.
Sau install.ps1: mở ocr-copy trong Start hoặc nhấn Ctrl+Alt+T.
'@
    exit 0
}

function Show-OcrNotification {
    param([string]$Message, [switch]$Failure, [switch]$Disabled)
    if ($Disabled) { return }
    try {
        if ($Failure) {
            [void][System.Windows.Forms.MessageBox]::Show($Message, 'ocr-copy',
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        $icon = New-Object System.Windows.Forms.NotifyIcon
        try {
            $icon.Icon = [System.Drawing.SystemIcons]::Information
            $icon.Text = 'ocr-copy'
            $icon.Visible = $true
            $icon.ShowBalloonTip(2000, 'Đã copy chữ vào clipboard', $Message,
                [System.Windows.Forms.ToolTipIcon]::Info)
            $until = [DateTime]::UtcNow.AddMilliseconds(2000)
            while ([DateTime]::UtcNow -lt $until) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 50
            }
        }
        finally { $icon.Dispose() }
    }
    catch {
        # Notifications must not discard an otherwise successful OCR result.
        Write-Verbose "Không hiển thị được thông báo: $($_.Exception.Message)"
    }
}

$workDirectory = $null
try {
    if ($env:OS -ne 'Windows_NT') { throw 'Trên Linux hãy dùng ./ocr-copy; ocr-copy.ps1 dành cho Windows 10/11.' }
    if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
        throw 'Cần chế độ STA. Chạy bằng powershell.exe -NoProfile -STA -File .\ocr-copy.ps1 [ẢNH...]'
    }
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    Import-Module (Join-Path $PSScriptRoot 'windows\OcrCopy.psm1') -Force
    $settingsPath = Join-Path $PSScriptRoot 'settings.json'
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $Language) { $Language = $settings.Language }
        if (-not $TesseractPath) { $TesseractPath = $settings.TesseractPath }
    }
    if (-not $Language) { $Language = 'vie+eng' }
    $tesseract = Resolve-OcrTesseract $TesseractPath
    Assert-OcrLanguage $tesseract $Language

    $workDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('ocr-copy-' + [guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($workDirectory)
    if ($ImagePath.Count -eq 0) {
        if (-not ('OcrCopy.RegionSelector' -as [type])) {
            Add-Type -LiteralPath (Join-Path $PSScriptRoot 'windows\ScreenCapture.cs') -ReferencedAssemblies System.Windows.Forms.dll, System.Drawing.dll
        }
        $shot = Join-Path $workDirectory 'shot.png'
        if (-not [OcrCopy.RegionSelector]::SaveSelection($shot, 'Kéo chọn vùng có chữ. Esc hoặc chuột phải để huỷ.')) { exit 0 }
        $ImagePath = @($shot)
    }

    $parts = New-Object 'System.Collections.Generic.List[string]'
    foreach ($image in $ImagePath) {
        $text = Get-OcrText -Path $image -TesseractPath $tesseract -Language $Language -WorkDirectory $workDirectory
        if (-not [string]::IsNullOrWhiteSpace($text)) { $parts.Add($text) }
    }
    if ($parts.Count -eq 0) { throw 'Không tìm thấy chữ trong ảnh.' }
    $outputText = $parts -join "`r`n`r`n"
    $data = New-Object System.Windows.Forms.DataObject
    $data.SetText($outputText, [System.Windows.Forms.TextDataFormat]::UnicodeText)
    # Persist after exit and retry briefly if another application owns the clipboard.
    [System.Windows.Forms.Clipboard]::SetDataObject($data, $true, 10, 100)
    Write-Output $outputText
    $preview = $outputText -replace '\s+', ' '
    if ($preview.Length -gt 160) { $preview = $preview.Substring(0, 160) + '…' }
    Show-OcrNotification $preview -Disabled:$NoNotify
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    Show-OcrNotification $_.Exception.Message -Failure -Disabled:$NoNotify
    exit 1
}
finally {
    if ($workDirectory -and (Test-Path -LiteralPath $workDirectory)) {
        Remove-Item -LiteralPath $workDirectory -Recurse -Force
    }
}
