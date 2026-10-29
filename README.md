# ocr-copy

[![ShellCheck](https://github.com/nguyenduchoan/ocr-copy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/nguyenduchoan/ocr-copy/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Tiếng Việt** | [English](README.en.md)

Copy chữ từ ảnh trên Linux, giống Live Text trên macOS.

Nhấn **Super+Shift+T**, kéo chọn một vùng bất kỳ trên màn hình (ảnh, video,
PDF, trang web, cửa sổ ứng dụng…) rồi dán bằng **Ctrl+V**. `ocr-copy` nhận dạng
chữ (OCR) trong vùng đó bằng [Tesseract][tesseract] và copy vào clipboard. Mọi
thứ chạy trên máy của bạn, ảnh không được gửi đi đâu cả.

## Tính năng

- Nhận dạng tiếng Việt có dấu và tiếng Anh (`vie+eng`), đổi được sang ngôn ngữ
  khác.
- Ba cách dùng: phím tắt, chuột phải trong Files (Nautilus) và dòng lệnh.
- Chạy được trên cả Wayland lẫn Xorg.
- Hiện thông báo kèm đoạn đầu của chữ vừa copy.
- Chạy offline, không cần tài khoản hay API key.
- Chỉ gồm vài script shell POSIX ngắn, dễ đọc và dễ sửa.

## Yêu cầu

- Debian 12 hoặc 13 với giao diện GNOME. Các bản phân phối dựa trên Debian như
  Ubuntu có thể chạy được nhưng chưa được thử.
- Quyền `sudo` để cài các gói sau:

| Gói | Dùng để |
| --- | --- |
| `tesseract-ocr`, `tesseract-ocr-vie` | Nhận dạng chữ |
| `gnome-screenshot` | Kéo chọn vùng màn hình |
| `wl-clipboard`, `xclip` | Copy vào clipboard |
| `libnotify-bin` | Hiện thông báo |
| `python3-gi`, `gir1.2-gdkpixbuf-2.0` | Phóng to ảnh trước khi nhận dạng |

## Cài đặt

Chạy bằng tài khoản thường, không thêm `sudo`. Script tự hỏi mật khẩu khi cài
gói.

**Từ mã nguồn:**

```sh
git clone https://github.com/nguyenduchoan/ocr-copy.git
cd ocr-copy
./install.sh
```

**Từ file phát hành:** tải `ocr-copy-<phiên bản>.tar.gz` ở trang
[Releases][releases], mở Terminal ở thư mục chứa file rồi chạy:

```sh
tar -xzf ocr-copy-*.tar.gz
./ocr-copy/install.sh
```

`install.sh` sẽ:

1. Cài các gói ở bảng trên qua APT.
2. Chép lệnh vào `~/.local/bin/ocr-copy`.
3. Thêm mục chuột phải **Scripts > Copy chữ từ ảnh** trong Files.
4. Gán phím tắt Super+Shift+T. Các phím tắt bạn tự tạo trong Settings >
   Keyboard được giữ nguyên.

Để cập nhật, lấy bản mới (`git pull` hoặc tải file phát hành mới) rồi chạy lại
`install.sh`.

Nếu trước đó chưa có thư mục `~/.local/bin`, hãy đăng xuất rồi đăng nhập lại để
gõ được lệnh `ocr-copy` trong Terminal.

## Cách dùng

### Phím tắt

Nhấn **Super+Shift+T**, kéo chọn vùng có chữ, rồi dán bằng **Ctrl+V**. Nhấn Esc
để huỷ.

Muốn đổi phím tắt thì vào Settings > Keyboard > View and Customize Shortcuts >
Custom Shortcuts > **Copy chữ từ ảnh**.

### Files (Nautilus)

Chọn một hoặc nhiều ảnh, chuột phải > **Scripts** > **Copy chữ từ ảnh**. Chữ
của các ảnh được nối với nhau, cách nhau một dòng trống.

### Dòng lệnh

```sh
ocr-copy                          # kéo chọn vùng màn hình
ocr-copy anh.png                  # nhận dạng một ảnh
ocr-copy trang1.png trang2.jpg    # nhiều ảnh cùng lúc
ocr-copy hoadon.png > hoadon.txt  # chữ cũng được in ra stdout
ocr-copy --help
```

## Cấu hình

Biến môi trường `OCR_LANG` chọn ngôn ngữ nhận dạng, mặc định là `vie+eng`:

```sh
OCR_LANG=eng ocr-copy anh.png
```

Văn bản thuần tiếng Anh thường được nhận dạng chính xác hơn với `eng`. Ngôn ngữ
khác cần cài thêm gói `tesseract-ocr-<mã>`, ví dụ tiếng Nhật:

```sh
sudo apt install tesseract-ocr-jpn
OCR_LANG=jpn+eng ocr-copy anh.png
```

Xem các ngôn ngữ đã cài bằng `tesseract --list-langs`.

Để phím tắt dùng ngôn ngữ khác, sửa lệnh của phím tắt trong Settings thành
`env OCR_LANG=eng /home/<tên-bạn>/.local/bin/ocr-copy`. Chạy lại `install.sh`
sẽ đặt lệnh về như cũ.

## Cách hoạt động

1. `gnome-screenshot --area` cho bạn kéo chọn vùng rồi lưu thành ảnh tạm.
2. Ảnh được phóng to gấp đôi bằng GdkPixbuf. Chữ trên màn hình chỉ khoảng
   96 DPI, phóng to giúp Tesseract đọc chữ nhỏ chính xác hơn nhiều. Ảnh lớn hơn
   4 megapixel được giữ nguyên.
3. Tesseract nhận dạng chữ theo `OCR_LANG`. Nếu không thấy chữ, script thử lại
   và coi cả ảnh là một khối chữ (`--psm 6`), nhờ vậy đọc được cả vùng chỉ có
   một dòng.
4. Chữ được đưa vào clipboard qua `xclip` khi có XWayland, nếu không thì qua
   `wl-copy`. Trên GNOME Wayland, `wl-copy` bị treo khi chạy từ phím tắt vì
   không có focus bàn phím. GNOME dùng chung clipboard XWayland cho mọi ứng
   dụng nên dán ở đâu cũng được.
5. Một thông báo hiện đoạn đầu của chữ đã copy. File tạm được xoá ngay sau đó.

## Gỡ cài đặt

Trong thư mục mã nguồn (hoặc thư mục giải nén từ file phát hành):

```sh
./uninstall.sh
```

Script gỡ lệnh, phím tắt và mục chuột phải. Các gói đã cài qua APT được giữ lại
vì ứng dụng khác có thể đang dùng.

## Xử lý sự cố

- **Nhấn phím tắt không thấy gì:** kiểm tra phím tắt còn trong Settings >
  Keyboard không, rồi chạy `ocr-copy` trong Terminal để xem thông báo lỗi.
- **"Thiếu lệnh …":** chạy lại `install.sh` để cài đủ gói.
- **"Không tìm thấy chữ trong ảnh":** vùng chọn quá nhỏ, chữ quá mờ, chữ viết
  tay hoặc nền quá rối. Thử chọn rộng hơn một chút.
- **Sai dấu hoặc sai chữ:** phóng to nội dung (Ctrl++) trước khi chọn vùng. Nếu
  văn bản chỉ có tiếng Anh, dùng `OCR_LANG=eng`.

Nếu vẫn lỗi, hãy [tạo issue][issues] kèm thông tin môi trường.

## Đóng góp

Mọi đóng góp đều được hoan nghênh. Xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Giấy phép

[MIT](LICENSE)

## Cảm ơn

[Tesseract OCR][tesseract], [gnome-screenshot][gnome-screenshot],
[wl-clipboard][wl-clipboard] và [xclip][xclip].

[tesseract]: https://github.com/tesseract-ocr/tesseract
[gnome-screenshot]: https://gitlab.gnome.org/GNOME/gnome-screenshot
[wl-clipboard]: https://github.com/bugaevc/wl-clipboard
[xclip]: https://github.com/astrand/xclip
[releases]: https://github.com/nguyenduchoan/ocr-copy/releases
[issues]: https://github.com/nguyenduchoan/ocr-copy/issues
