#requires -Version 5.1
[CmdletBinding()]
param([switch]$Desktop, [string]$TesseractPath)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('ocr-copy-tests-' + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($fixture)
$script:checks = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}

function Assert-Exception {
    param([scriptblock]$Action, [string]$Pattern)
    $message = ''
    try { & $Action | Out-Null }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match $Pattern) "Không gặp lỗi mong đợi '$Pattern': $message"
}

try {
    # Parse all scripts and guard the encoding required by Windows PowerShell 5.1.
    $scripts = Get-ChildItem -LiteralPath $repo -Recurse -File |
        Where-Object { $_.Extension -in @('.ps1', '.psm1') }
    foreach ($file in $scripts) {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        Assert-True ($errors.Count -eq 0) "Lỗi cú pháp: $($file.Name): $errors"
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        Assert-True (($bytes[0..2] -join ',') -eq '239,187,191') "Thiếu UTF-8 BOM: $($file.Name)"
    }

    $modulePath = Join-Path $repo 'windows/OcrCopy.psm1'
    $module = Import-Module $modulePath -Force -PassThru
    $hostExecutable = (Get-Process -Id $PID).Path
    $echoScript = Join-Path $fixture 'echo.ps1'
    [System.IO.File]::WriteAllText($echoScript, @'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
foreach ($argument in $args) {
    [Console]::WriteLine([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($argument)))
}
[Console]::Error.Write('Lỗi thử nghiệm tiếng Việt')
exit 7
'@, (New-Object System.Text.UTF8Encoding $true))
    $arguments = @('có dấu và khoảng trắng', 'embedded"quote', 'backslash\"quote', '', 'trailing\', '[literal]')
    $processResult = Invoke-OcrProcess $hostExecutable (@('-NoProfile', '-File', $echoScript) + $arguments)
    Assert-True ($processResult.ExitCode -eq 7) 'Không giữ mã lỗi từ tiến trình con.'
    $expected = @($arguments | ForEach-Object { [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($_)) })
    Assert-True (($processResult.Output.TrimEnd() -split '\r?\n' -join ',') -ceq ($expected -join ',')) 'Sai escape tham số native.'
    Assert-True ($processResult.Error -ceq 'Lỗi thử nghiệm tiếng Việt') 'Đọc stderr sai UTF-8.'
    Assert-True ((Resolve-OcrTesseract $hostExecutable) -eq $hostExecutable) 'Không nhận đường dẫn engine chỉ định.'
    Assert-Exception { Resolve-OcrTesseract (Join-Path $fixture 'missing.exe') } 'Không tìm thấy Tesseract'

    # Feed controlled engine replies through the real language/OCR logic.
    & $module {
        $script:Calls = New-Object 'System.Collections.Generic.List[object]'
        $script:Replies = New-Object System.Collections.Queue
        function script:ConvertTo-OcrImage { param($Path, $Destination) [void]$Destination; return $Path }
        function script:Invoke-OcrProcess {
            param($FilePath, $ArgumentList)
            [void]$FilePath
            $script:Calls.Add($ArgumentList)
            if ($ArgumentList[0] -eq '--list-langs') {
                return [pscustomobject]@{ ExitCode = 0; Output = "List of available languages (3):`neng`nvie`nscript/Latin`n"; Error = '' }
            }
            $reply = $script:Replies.Dequeue()
            if ($null -ne $reply.Text) {
                [System.IO.File]::WriteAllText(($ArgumentList[1] + '.txt'), $reply.Text,
                    (New-Object System.Text.UTF8Encoding $false))
            }
            [pscustomobject]@{ ExitCode = $reply.Code; Output = ''; Error = 'Engine error details' }
        }
    }
    function Initialize-Reply {
        param([object[]]$Replies)
        & $module {
            param($Items)
            $script:Calls.Clear()
            $script:Replies.Clear()
            foreach ($item in $Items) { $script:Replies.Enqueue($item) }
        } $Replies
    }
    Assert-OcrLanguage 'fake' 'vie+eng'
    Assert-OcrLanguage 'fake' 'script/Latin'
    Assert-Exception { Assert-OcrLanguage 'fake' 'eng+missing' } 'Thiếu dữ liệu ngôn ngữ: missing'
    Assert-Exception { Assert-OcrLanguage 'fake' 'eng --psm 6' } 'Ngôn ngữ không hợp lệ'
    $image = Join-Path $fixture 'ảnh có dấu [1].png'
    [System.IO.File]::WriteAllText($image, 'fixture')
    $ocrArguments = @{ Path = $image; TesseractPath = 'fake'; Language = 'vie+eng'; WorkDirectory = $fixture }
    Initialize-Reply @(@{ Text = "Xin chào Việt Nam`n"; Code = 0 })
    Assert-True ((Get-OcrText @ocrArguments) -ceq 'Xin chào Việt Nam') 'OCR làm mất dấu tiếng Việt.'
    $calls = & $module { ,$script:Calls.ToArray() }
    Assert-True ($calls.Count -eq 1 -and $calls[0][0] -ceq $image) 'Không giữ nguyên đường dẫn literal.'
    Initialize-Reply @(@{ Text = " `n"; Code = 0 }, @{ Text = "Một dòng`n"; Code = 0 })
    Assert-True ((Get-OcrText @ocrArguments) -ceq 'Một dòng') 'Không thử lại ảnh một dòng.'
    $calls = & $module { ,$script:Calls.ToArray() }
    Assert-True ($calls.Count -eq 2 -and ($calls[1] -join ' ') -match '--psm 6') 'Sai chế độ nhận dạng dự phòng.'
    Initialize-Reply @(@{ Text = ''; Code = 0 }, @{ Text = ''; Code = 0 })
    Assert-True ([string]::IsNullOrEmpty((Get-OcrText @ocrArguments))) 'Ảnh trống phải trả kết quả rỗng.'
    Initialize-Reply @(@{ Text = $null; Code = 1 })
    Assert-Exception { Get-OcrText @ocrArguments } 'Engine error details'
    # A prior result file must never be mistaken for fresh output after engine failure.
    [System.IO.File]::WriteAllText((Join-Path $fixture 'result.txt'), 'stale')
    Initialize-Reply @(@{ Text = $null; Code = 0 })
    Assert-Exception { Get-OcrText @ocrArguments } 'Tesseract không tạo kết quả'
    Assert-Exception { Get-OcrText -Path (Join-Path $fixture 'missing.png') -WorkDirectory $fixture } 'Không đọc được file ảnh'
    Write-Output "Đạt kiểm thử lõi ($script:checks kiểm tra)."

    if ($Desktop) {
        if ($env:OS -ne 'Windows_NT') { throw '-Desktop cần Windows và một phiên desktop.' }
        if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') { throw 'Chạy kiểm thử bằng powershell.exe -STA.' }
        $module = Import-Module $modulePath -Force -PassThru
        Add-Type -AssemblyName System.Drawing, System.Windows.Forms
        # Compile the same overlay used by the real shortcut, without displaying it in CI.
        Add-Type -LiteralPath (Join-Path $repo 'windows/ScreenCapture.cs') -ReferencedAssemblies System.Windows.Forms.dll, System.Drawing.dll
        $engine = Resolve-OcrTesseract $TesseractPath
        Assert-OcrLanguage $engine 'vie+eng'
        $image = Join-Path $fixture 'ảnh có dấu [1].png'
        $blank = Join-Path $fixture 'blank.png'
        $vietnamese = Join-Path $fixture 'tiếng Việt.png'
        $bitmap = New-Object System.Drawing.Bitmap 1000, 160
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $font = New-Object System.Drawing.Font 'Arial', 38
        try {
            $graphics.Clear([System.Drawing.Color]::White)
            $bitmap.Save($blank, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.DrawString('Xin chào Việt Nam', $font, [System.Drawing.Brushes]::Black, 20, 35)
            $bitmap.Save($vietnamese, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.Clear([System.Drawing.Color]::White)
            $graphics.DrawString('WINDOWS OCR TEST 123', $font, [System.Drawing.Brushes]::Black, 20, 35)
            $bitmap.Save($image, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $graphics.Dispose(); $font.Dispose(); $bitmap.Dispose() }
        $scaledPath = & $module { param($InputPath, $OutputPath) ConvertTo-OcrImage $InputPath $OutputPath } $image (Join-Path $fixture 'scaled-check.png')
        $scaled = [System.Drawing.Image]::FromFile($scaledPath)
        try { Assert-True ($scaled.Width -eq 2000 -and $scaled.Height -eq 320) 'Phóng to ảnh không chạy trên Windows.' }
        finally { $scaled.Dispose() }
        $entry = Join-Path $repo 'ocr-copy.ps1'
        $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $entry,
            $image, $image, '-Language', 'eng', '-TesseractPath', $engine, '-NoNotify')
        Assert-True ($result.ExitCode -eq 0) "OCR thật thất bại: $($result.Error)"
        $copied = [System.Windows.Forms.Clipboard]::GetText()
        Assert-True ($copied -ceq "WINDOWS OCR TEST 123`r`n`r`nWINDOWS OCR TEST 123") 'Sai ghép nhiều ảnh hoặc clipboard không tồn tại sau exit.'
        Assert-True ($result.Output.TrimEnd() -ceq $copied) 'stdout khác clipboard.'
        $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $entry,
            $vietnamese, '-Language', 'vie+eng', '-TesseractPath', $engine, '-NoNotify')
        Assert-True ($result.ExitCode -eq 0 -and $result.Output.TrimEnd() -ceq 'Xin chào Việt Nam') 'OCR thật không giữ đúng dấu tiếng Việt.'
        Assert-True ([System.Windows.Forms.Clipboard]::GetText() -ceq 'Xin chào Việt Nam') 'Clipboard không giữ đúng dấu tiếng Việt.'
        $sentinel = 'Giữ nguyên clipboard khi lỗi'
        [System.Windows.Forms.Clipboard]::SetDataObject($sentinel, $true)
        foreach ($badImage in @($blank, (Join-Path $fixture 'missing.png'))) {
            $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $entry,
                $badImage, '-Language', 'eng', '-TesseractPath', $engine, '-NoNotify')
            Assert-True ($result.ExitCode -eq 1) 'OCR lỗi phải trả exit code 1.'
            Assert-True ([System.Windows.Forms.Clipboard]::GetText() -ceq $sentinel) 'OCR lỗi làm thay đổi clipboard.'
        }

        # Sandbox installed files; preserve any pre-existing Start Menu shortcut.
        $oldLocalAppData = $env:LOCALAPPDATA
        $shortcutPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'ocr-copy.lnk'
        $shortcutBackup = $null
        if (Test-Path -LiteralPath $shortcutPath) {
            $shortcutBackup = [System.IO.File]::ReadAllBytes($shortcutPath)
            Remove-Item -LiteralPath $shortcutPath -Force
        }
        try {
            $env:LOCALAPPDATA = Join-Path $fixture 'app data'
            $installed = Join-Path $env:LOCALAPPDATA 'Programs/ocr-copy'
            for ($attempt = 0; $attempt -lt 2; $attempt++) {
                $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                    (Join-Path $repo 'install.ps1'), '-TesseractPath', $engine, '-Language', 'eng')
                Assert-True ($result.ExitCode -eq 0) "Cài/cài lại lỗi: $($result.Error)"
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $null
                try {
                    $shortcut = $shell.CreateShortcut($shortcutPath)
                    # WSH can return modifiers in a different order than the setter.
                    $hotkey = (($shortcut.Hotkey -split '\+' | Sort-Object) -join '+').ToUpperInvariant()
                    if ($attempt -eq 0) {
                        Assert-True ($hotkey -eq 'ALT+CTRL+T') "Không gán đúng phím tắt mặc định: $($shortcut.Hotkey)"
                        $shortcut.Hotkey = 'CTRL+ALT+Y'
                        $shortcut.Save()
                    }
                    else { Assert-True ($hotkey -eq 'ALT+CTRL+Y') "Cài lại làm mất phím tắt đã đổi: $($shortcut.Hotkey)" }
                }
                finally {
                    if ($shortcut) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) }
                    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
                }
            }
            Assert-True (Test-Path -LiteralPath $shortcutPath) 'Thiếu shortcut Start.'
            $settings = Get-Content (Join-Path $installed 'settings.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            Assert-True ($settings.Language -eq 'eng' -and $settings.TesseractPath -eq $engine) 'Không lưu cấu hình cài đặt.'
            $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File',
                (Join-Path $installed 'ocr-copy.ps1'), $image, '-NoNotify')
            Assert-True ($result.ExitCode -eq 0 -and $result.Output -match 'WINDOWS OCR TEST 123') 'Bản đã cài không dùng được cấu hình lưu.'
            [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
            $launcherOutput = & (Join-Path $installed 'ocr-copy.cmd') $image -NoNotify
            Assert-True ($LASTEXITCODE -eq 0 -and ($launcherOutput -join "`n") -match 'WINDOWS OCR TEST 123') 'Launcher .cmd không chạy từ thư mục khác.'
            $launcherOutput = & (Join-Path $installed 'ocr-copy.cmd') $vietnamese -Language 'vie+eng' -NoNotify
            Assert-True ($LASTEXITCODE -eq 0 -and ($launcherOutput -join "`n").TrimEnd() -ceq 'Xin chào Việt Nam') 'stdout của launcher sai Unicode.'
            [System.IO.File]::WriteAllText((Join-Path $installed 'keep.txt'), 'keep')
            $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $installed 'uninstall.ps1'))
            Assert-True ($result.ExitCode -eq 0) "Gỡ lỗi: $($result.Error)"
            Assert-True (Test-Path -LiteralPath (Join-Path $installed 'keep.txt')) 'Gỡ xoá nhầm file khác.'
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $installed 'ocr-copy.ps1'))) 'Gỡ còn sót lệnh.'
            Assert-True (-not (Test-Path -LiteralPath $shortcutPath)) 'Gỡ còn sót phím tắt.'
            $result = Invoke-OcrProcess $hostExecutable @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $repo 'uninstall.ps1'))
            Assert-True ($result.ExitCode -eq 0) 'Gỡ lần thứ hai bị lỗi.'
        }
        finally {
            $env:LOCALAPPDATA = $oldLocalAppData
            if ($null -ne $shortcutBackup) { [System.IO.File]::WriteAllBytes($shortcutPath, $shortcutBackup) }
            elseif (Test-Path -LiteralPath $shortcutPath) { Remove-Item -LiteralPath $shortcutPath -Force }
        }
        Write-Output "Đạt kiểm thử Windows ($script:checks kiểm tra tổng cộng)."
    }
}
finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
