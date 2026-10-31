# Shared OCR functions; desktop integration stays in the Windows entry point.
Set-StrictMode -Version 2.0

function Resolve-OcrTesseract {
    param([string]$Path)

    if ($Path) {
        $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($item -and -not $item.PSIsContainer) { return $item.FullName }
        throw "Không tìm thấy Tesseract: $Path"
    }

    $command = Get-Command tesseract -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($command) { return $command.Source }

    foreach ($root in @($env:ProgramW6432, $env:ProgramFiles, ${env:ProgramFiles(x86)},
            $env:LOCALAPPDATA)) {
        if (-not $root) { continue }
        foreach ($relative in @('Tesseract-OCR\tesseract.exe', 'Programs\Tesseract-OCR\tesseract.exe')) {
            $candidate = Join-Path $root $relative
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
        }
    }
    throw 'Thiếu Tesseract. Cài Tesseract và dữ liệu vie, eng theo mục Windows trong README.md.'
}

function Invoke-OcrProcess {
    param([string]$FilePath, [string[]]$ArgumentList)

    # Use CRT argument quoting, including embedded quotes and trailing backslashes.
    # Process avoids Windows PowerShell 5.1 treating native stderr as a fatal error.
    $quoted = foreach ($argument in $ArgumentList) {
        '"' + [regex]::Replace(
            [regex]::Replace($argument, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
    }
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $FilePath
    $info.Arguments = $quoted -join ' '
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $info.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        # Drain both pipes before waiting, so verbose errors cannot deadlock OCR.
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = $stdout.GetAwaiter().GetResult()
            Error = $stderr.GetAwaiter().GetResult()
        }
    }
    finally { $process.Dispose() }
}

function Assert-OcrLanguage {
    param([string]$TesseractPath, [string]$Language)

    if ($Language -notmatch '^[A-Za-z0-9_/]+(\+[A-Za-z0-9_/]+)*$') {
        throw 'Ngôn ngữ không hợp lệ. Ví dụ: vie+eng, eng hoặc jpn+eng.'
    }
    $result = Invoke-OcrProcess $TesseractPath @('--list-langs')
    if ($result.ExitCode -ne 0) {
        throw "Không đọc được danh sách ngôn ngữ Tesseract: $($result.Error.Trim())"
    }
    $available = @($result.Output -split '\r?\n' | ForEach-Object { $_.Trim() })
    $missing = @($Language -split '\+' | Where-Object { $available -cnotcontains $_ })
    if ($missing.Count -gt 0) {
        throw (('Thiếu dữ liệu ngôn ngữ: {0}. Cài file .traineddata tương ứng vào tessdata; ' +
            'xem README.md. Có thể dùng -Language eng nếu chỉ cần tiếng Anh.') -f ($missing -join ', '))
    }
}

function ConvertTo-OcrImage {
    param([string]$Path, [string]$Destination)

    $image = $null
    $scaled = $null
    $graphics = $null
    try {
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($Path)
        if ([long]$image.Width * $image.Height -gt 4000000) { return $Path }
        $scaled = New-Object System.Drawing.Bitmap ($image.Width * 2), ($image.Height * 2)
        $scaled.SetResolution(192, 192)
        $graphics = [System.Drawing.Graphics]::FromImage($scaled)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.DrawImage($image, 0, 0, $scaled.Width, $scaled.Height)
        $scaled.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
        return $Destination
    }
    catch {
        # Upscaling is optional; Tesseract also supports formats GDI+ cannot read.
        return $Path
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($scaled) { $scaled.Dispose() }
        if ($image) { $image.Dispose() }
    }
}

function Get-OcrText {
    param([string]$Path, [string]$TesseractPath, [string]$Language, [string]$WorkDirectory)

    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $item -or $item.PSIsContainer -or $item.PSProvider.Name -ne 'FileSystem') {
        throw "Không đọc được file ảnh: $Path"
    }
    $inputImage = ConvertTo-OcrImage $item.FullName (Join-Path $WorkDirectory 'scaled.png')
    $outputBase = Join-Path $WorkDirectory 'result'
    $outputFile = "$outputBase.txt"
    foreach ($mode in @('auto', 'block')) {
        Remove-Item -LiteralPath $outputFile -Force -ErrorAction SilentlyContinue
        $arguments = @($inputImage, $outputBase, '-l', $Language, '-c', 'page_separator=')
        if ($mode -eq 'block') { $arguments += @('--psm', '6') }
        $result = Invoke-OcrProcess $TesseractPath $arguments
        if ($result.ExitCode -ne 0) {
            throw "Lỗi khi nhận dạng chữ trong '$Path': $($result.Error.Trim())"
        }
        if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
            throw "Tesseract không tạo kết quả cho file: $Path"
        }
        # Read the UTF-8 file directly instead of decoding native stdout via an ANSI code page.
        $text = [System.IO.File]::ReadAllText($outputFile, [System.Text.Encoding]::UTF8)
        $text = $text.TrimEnd([char[]]"`r`n`f")
        if (-not [string]::IsNullOrWhiteSpace($text)) { return $text }
    }
    return ''
}

Export-ModuleMember -Function Resolve-OcrTesseract, Invoke-OcrProcess, Assert-OcrLanguage, Get-OcrText
