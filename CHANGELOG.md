# Nhật ký thay đổi

Mọi thay đổi đáng chú ý được ghi ở đây. Định dạng theo
[Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), số phiên bản theo
[Semantic Versioning](https://semver.org/lang/vi/).

## [Chưa phát hành]

### Thêm

- Bản Windows 10/11: `ocr-copy.ps1` và launcher `ocr-copy.cmd`, chọn vùng màn
  hình (Esc/chuột phải để huỷ), OCR một/nhiều file ảnh và clipboard Unicode.
- `install.ps1`/`uninstall.ps1`: cài/gỡ theo tài khoản hiện tại, lưu cấu hình
  Tesseract/ngôn ngữ, shortcut Start và phím tắt Ctrl+Alt+T.
- Kiểm tra dữ liệu ngôn ngữ trước khi OCR, giữ đầu ra UTF-8 và thử lại bằng
  `--psm 6` khi không thấy chữ; không thay đổi bản Linux.
- Hướng dẫn Windows và workflow kiểm thử Windows PowerShell 5.1.

## [1.0.0] - 2026-10-29

### Thêm

- Lệnh `ocr-copy`: kéo chọn vùng màn hình hoặc đọc file ảnh, nhận dạng chữ và
  copy vào clipboard.
- Mặc định nhận dạng tiếng Việt và tiếng Anh, đổi ngôn ngữ bằng `OCR_LANG`.
- Phóng to ảnh gấp đôi trước khi nhận dạng, thử lại với `--psm 6` khi không
  thấy chữ.
- Thông báo kèm đoạn đầu của chữ đã copy.
- `install.sh`: cài gói qua APT, cài lệnh, thêm mục chuột phải trong Files và
  phím tắt Super+Shift+T.
- `uninstall.sh`: gỡ những gì `install.sh` đã thêm, giữ lại các gói APT.

[Chưa phát hành]: https://github.com/nguyenduchoan/ocr-copy/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/nguyenduchoan/ocr-copy/releases/tag/v1.0.0
