# Kiểm chứng hỗ trợ Windows

Ngày: 2026-10-31. Phạm vi: bản Windows chạy trực tiếp bằng Windows PowerShell
5.1, giữ nguyên các script Linux. Mã nguồn và kiểm thử nằm trên branch
`feat/windows-support`.

## Tiêu chí chấp nhận

| Tiêu chí | Triển khai | Bằng chứng hiện có |
| --- | --- | --- |
| Chọn vùng màn hình, Esc/chuột phải huỷ | `windows/ScreenCapture.cs` | Biên dịch đạt; cần thử tương tác trên Windows |
| OCR một/nhiều ảnh, mặc định `vie+eng` | `ocr-copy.ps1`, `windows/OcrCopy.psm1` | OCR thật tiếng Việt/Anh và ghép nhiều ảnh đạt trong Windows CI |
| Giữ Unicode trong đường dẫn và kết quả | Đọc file UTF-8, script có BOM, truyền tham số native | Kiểm thử Unicode/escape, OCR thật, clipboard và stdout launcher đạt |
| Clipboard còn sau exit; lỗi/huỷ giữ clipboard cũ | Clipboard Unicode có persist/retry, chỉ ghi khi OCR thành công | Persist và trường hợp ảnh trống/file lỗi đạt trong Windows CI; huỷ chọn cần thử thủ công |
| Cài/cài lại/gỡ theo tài khoản; giữ file không liên quan | `install.ps1`, `uninstall.ps1` | Cài lại giữ phím tắt đã đổi, dùng cấu hình lưu, gỡ hai lần và giữ file khác đạt trong Windows CI |
| Luồng Linux giữ nguyên | Không sửa `ocr-copy`, `install.sh`, `uninstall.sh` | ShellCheck và kiểm tra cú pháp đạt |

## Đã thực hiện

Kiểm chứng local dùng Linux, PowerShell 7.6.9 và Tesseract 5.3.0. Kiểm chứng
Windows tự động chạy trên GitHub Actions `windows-latest`, Windows PowerShell
5.1 và Tesseract 5.4.0. Chưa thao tác giao diện trong phiên người dùng
Windows 10/11.

| Kiểm tra | Kết quả |
| --- | --- |
| `pwsh -NoProfile -File ./tests/windows.tests.ps1` | Đạt 25 kiểm tra lõi: parser/BOM, escape tham số, UTF-8, mã lỗi, engine/ngôn ngữ thiếu, file literal, retry `--psm 6`, ảnh trống, lỗi OCR và kết quả tạm cũ |
| `tests/windows.tests.ps1 -Desktop` trong Windows CI | Đạt 49 kiểm tra tổng cộng, gồm 25 kiểm tra lõi và kiểm thử tích hợp Windows |
| PSScriptAnalyzer trên các file `.ps1`/`.psm1` | Không có Error/Warning; quy tắc cú pháp tương thích PowerShell 5.1 không báo lỗi |
| Biên dịch `windows/ScreenCapture.cs` với reference assemblies .NET Framework 4.8 | Đạt, không có chẩn đoán biên dịch |
| OCR ảnh thật bằng `Get-OcrText`, `vie+eng`, tên ảnh/thư mục có dấu, khoảng trắng và `[]` | Đọc đúng “Xin chào Việt Nam” và “Windows OCR test 123” |
| `shellcheck install.sh uninstall.sh ocr-copy` với ShellCheck 0.11.0 | Đạt |
| `sh -n ocr-copy install.sh uninstall.sh` | Đạt |

Kiểm tra tích hợp Windows xác nhận phóng to ảnh GDI+, OCR, clipboard, stdout
và shortcut COM. Overlay được biên dịch; tương tác chụp màn hình, phím tắt
toàn cục, thông báo và DPI còn cần thử thủ công.

## Kiểm tra Windows tự động

Workflow `.github/workflows/windows.yml` chạy trên `windows-latest`, cài
Tesseract cùng dữ liệu `vie` đã kiểm tra SHA-256, rồi chạy:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tests\windows.tests.ps1 -Desktop
```

Bộ kiểm thử biên dịch overlay, tạo ảnh bằng GDI+, OCR thật tiếng Việt/Anh,
phóng to ảnh, ghép nhiều ảnh, đọc clipboard sau khi tiến trình OCR đã thoát,
giữ clipboard khi ảnh trống/file lỗi, và kiểm tra cài/cài lại/gỡ cùng launcher
`.cmd`. File cài đặt nằm trong thư mục tạm; shortcut Start đã có được khôi
phục sau kiểm thử. Bộ kiểm thử ghi clipboard của phiên đang dùng.

Trạng thái: **đạt**, kiểm chứng commit `7a18c4a`:

- [Windows CI: 49 kiểm tra đạt](https://github.com/nguyenduchoan/ocr-copy/actions/runs/41189222409).
- [ShellCheck: đạt](https://github.com/nguyenduchoan/ocr-copy/actions/runs/41189222414).

## Kiểm tra thủ công còn cần thực hiện

Thực hiện trong phiên desktop Windows 10 và Windows 11 trước khi xác nhận
bản phát hành đã được kiểm thử đầy đủ:

- [ ] Cài bằng tài khoản thường với Tesseract có `vie` và `eng`; mở từ Start.
- [ ] Nhấn Ctrl+Alt+T, kéo chọn vùng có chữ và dán đúng vào Notepad/trình duyệt.
- [ ] Nhấn Esc, chuột phải và chọn vùng rất nhỏ; không đổi clipboard, không
  để lại overlay hoặc ảnh tạm.
- [ ] Chọn từ trái sang phải và từ phải sang trái; crop không chứa lớp phủ.
- [ ] Thử một màn hình tại DPI 100%, 150%, 200%.
- [ ] Thử nhiều màn hình có DPI khác nhau, màn hình ở bên trái/phía trên màn
  hình chính và vùng chọn đi qua ranh giới màn hình.
- [ ] Xem thông báo thành công, hộp thoại lỗi và chế độ `-NoNotify`.
- [ ] Đổi phím tắt trong Properties, cài lại và xác nhận phím đã đổi được giữ.
- [ ] Gỡ hai lần; chỉ xoá file/shortcut của ứng dụng, giữ Tesseract và file khác.

Không đánh dấu các mục Windows là đạt chỉ dựa vào kiểm tra trên Linux.
