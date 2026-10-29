# Nhật ký thay đổi

Mọi thay đổi đáng chú ý được ghi ở đây. Định dạng theo
[Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), số phiên bản theo
[Semantic Versioning](https://semver.org/lang/vi/).

## [Chưa phát hành]

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
