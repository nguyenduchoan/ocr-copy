# Sử dụng ocr-copy trên Windows 10/11

Bản Windows chạy trực tiếp bằng PowerShell, dùng Tesseract giống bản Linux.
Bạn có thể kéo chọn vùng màn hình hoặc đọc nhiều ảnh, rồi dán chữ bằng Ctrl+V.
OCR chạy offline; cài Tesseract và dữ liệu ngôn ngữ chỉ cần làm một lần.

## Yêu cầu

- Windows 10 từ phiên bản 1703 hoặc Windows 11, có phiên desktop đang mở.
- Windows PowerShell 5.1 (`powershell.exe`, có sẵn trên Windows).
- Tesseract 5 cùng dữ liệu `vie` và `eng` để nhận dạng tiếng Việt, tiếng Anh.
- Không cần WSL, Python hay ứng dụng chạy nền thường trực.

## Cài đặt

1. Cài Tesseract từ [bộ cài Windows được tài liệu Tesseract giới thiệu][tesseract-windows].
   Trong **Additional language data**, chọn **Vietnamese** và giữ dữ liệu
   English. Bước cài Tesseract có thể yêu cầu quyền quản trị.

   Nếu dùng winget, mở trình cài tương tác để chọn đủ ngôn ngữ:

   ```powershell
   winget install --id UB-Mannheim.TesseractOCR --exact --interactive
   ```

2. Tải repo bằng Git hoặc **Code > Download ZIP**, rồi giải nén. Mở PowerShell
   ở thư mục có `install.ps1` và chạy bằng tài khoản thường:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

3. Mở **ocr-copy** trong Start hoặc nhấn **Ctrl+Alt+T**, kéo chọn chữ rồi dán
   bằng **Ctrl+V**. Esc hoặc chuột phải huỷ thao tác, giữ nguyên clipboard.

Script kiểm tra đủ Tesseract/ngôn ngữ trước khi cài, chép ứng dụng vào
`$env:LOCALAPPDATA\Programs\ocr-copy` và tạo shortcut trong Start cho tài
khoản hiện tại. `settings.json` ở thư mục cài lưu đường dẫn Tesseract và ngôn
ngữ; dòng lệnh và shortcut cùng dùng cấu hình này. PATH được giữ nguyên.
Chạy lại cùng lệnh để cập nhật; phím tắt đã đổi trong Properties được giữ lại.

Nếu cài Tesseract ở thư mục riêng, truyền đường dẫn file `tesseract.exe`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
    -TesseractPath (Join-Path $env:ProgramFiles 'Tesseract-OCR\tesseract.exe')
```

Chỉ cần tiếng Anh thì cài và lưu cấu hình `eng`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Language eng
```

`-ExecutionPolicy Bypass` chỉ áp dụng cho tiến trình PowerShell được mở bằng
lệnh đó, không đổi chính sách thực thi của hệ thống. Nếu máy được quản lý
bằng chính sách của tổ chức, hãy làm theo chính sách cho phép chạy script của
máy đó.

## Dòng lệnh

Có thể dùng ngay từ thư mục mã nguồn, sau khi cài Tesseract:

```powershell
.\ocr-copy.cmd                              # kéo chọn vùng màn hình
.\ocr-copy.cmd .\anh.png                    # một ảnh
.\ocr-copy.cmd '.\trang 1.png' .\trang2.jpg  # nhiều ảnh, giữ đúng thứ tự
.\ocr-copy.cmd .\anh.png -Language eng       # chỉ nhận dạng tiếng Anh
.\ocr-copy.cmd -Help
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
.\ocr-copy.cmd .\anh.png -NoNotify | Out-File .\chu.txt -Encoding utf8
```

Dòng đặt `OutputEncoding` giúp Windows PowerShell 5.1 đọc đúng stdout UTF-8
của launcher khi chuyển kết quả sang file. Clipboard dùng Unicode trực tiếp.

Trong bản đã cài, gọi launcher bằng:

```powershell
& "$env:LOCALAPPDATA\Programs\ocr-copy\ocr-copy.cmd" .\anh.png
```

Chữ của nhiều ảnh được nối bằng dòng trống, copy vào clipboard dạng Unicode
và in ra stdout. Ảnh không có chữ được bỏ qua; nếu mọi ảnh đều trống hoặc có
file lỗi, lệnh trả mã lỗi 1 và giữ clipboard hiện tại. Thành công hoặc huỷ
chọn trả mã 0. File tạm được xoá khi kết thúc.

Launcher dùng Windows PowerShell với STA để thao tác clipboard. Nếu muốn gọi
script trực tiếp:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\ocr-copy.ps1 .\anh.png
```

## Cấu hình

| Tuỳ chọn | Thứ tự ưu tiên |
| --- | --- |
| Ngôn ngữ | `-Language`, biến `OCR_LANG`, `settings.json`, rồi `vie+eng` |
| Tesseract | `-TesseractPath`, biến `OCR_TESSERACT`, `settings.json`, rồi PATH/thư mục cài phổ biến |
| Thông báo | Thêm `-NoNotify` để tắt cả thông báo thành công và hộp thoại lỗi |

Ví dụ đặt ngôn ngữ cho phiên PowerShell hiện tại:

```powershell
$env:OCR_LANG = 'eng'
.\ocr-copy.cmd .\anh.png
Remove-Item Env:OCR_LANG
```

Biến môi trường đặt trong Terminal chỉ áp dụng cho tiến trình con của
Terminal đó. Để đổi ngôn ngữ của shortcut Start, chạy lại `install.ps1` với
`-Language` tương ứng.

Đổi phím tắt: tìm **ocr-copy** trong Start, chọn **Open file location**, mở
**Properties > Shortcut key**. Nếu Ctrl+Alt+T đã được ứng dụng khác sử dụng,
hãy chọn phím khác ở đây. Windows có thể cần đăng xuất rồi đăng nhập lại để
nhận phím tắt mới; vẫn có thể mở bằng Start ngay.

Phiên bản này chưa thêm menu chuột phải trong File Explorer. Luồng chuột phải
Nautilus ở bản Linux vẫn hoạt động như trước.

## Gỡ cài đặt

Chạy từ thư mục mã nguồn:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Nếu đã xoá thư mục mã nguồn:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File "$env:LOCALAPPDATA\Programs\ocr-copy\uninstall.ps1"
```

Script chỉ xoá các file của ocr-copy và shortcut của nó. Tesseract, dữ liệu
ngôn ngữ và file khác bạn tự đặt vào thư mục cài được giữ lại.

## Xử lý sự cố

- **Thiếu Tesseract:** cài Tesseract rồi chạy lại. Nếu dùng thư mục riêng,
  truyền `-TesseractPath` hoặc đặt biến `OCR_TESSERACT`.
- **Thiếu dữ liệu ngôn ngữ:** chạy lại bộ cài Tesseract và thêm Vietnamese,
  hoặc lấy `vie.traineddata`/`eng.traineddata` từ
  [kho dữ liệu chính thức][tessdata] rồi chép vào thư mục `tessdata` của
  Tesseract. Chỉ dùng `TESSDATA_PREFIX` khi chủ động chọn thư mục dữ liệu riêng.
- **Phím tắt không chạy:** thử mở ocr-copy trong Start. Kiểm tra phím tắt trùng
  trong Properties; đăng xuất/đăng nhập nếu cần.
- **Không thấy chữ hoặc nhận sai dấu:** chọn vùng rộng hơn hoặc phóng to nội
  dung. Dùng `-Language eng` cho văn bản thuần tiếng Anh.
- **Clipboard đang bận:** script thử lại trong thời gian ngắn. Nếu vẫn lỗi,
  đóng cửa sổ clipboard đang giữ quyền rồi chạy lại.
- **Cần xem lỗi:** chạy `ocr-copy.cmd` trong Terminal; thêm `-NoNotify` nếu
  không muốn hộp thoại lỗi khi chạy tự động.

Xem [bản ghi kiểm chứng](windows-validation.md) để biết các kiểm tra đã chạy
và những thao tác còn cần thử trên Windows thực.

[tesseract-windows]: https://tesseract-ocr.github.io/tessdoc/Installation.html#windows
[tessdata]: https://github.com/tesseract-ocr/tessdata_fast
