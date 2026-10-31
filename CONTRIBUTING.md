# Đóng góp cho ocr-copy

Cảm ơn bạn đã quan tâm! Issue và pull request bằng tiếng Việt hay tiếng Anh đều
được. (Issues and pull requests in English are welcome too.)

## Báo lỗi

Hãy [tạo issue](https://github.com/nguyenduchoan/ocr-copy/issues/new/choose) và
ghi kèm:

- Hệ điều hành: phiên bản Debian/GNOME và Wayland/Xorg, hoặc phiên bản Windows
  cùng PowerShell/Tesseract.
- Những gì in ra khi chạy `ocr-copy` trong Terminal.
- Nếu chữ bị nhận dạng sai: ảnh gốc (nếu không có thông tin riêng tư) và kết quả
  nhận được.

## Viết code

- Script Linux dùng `#!/bin/sh` và chỉ dùng cú pháp POSIX, không dùng tính
  năng riêng của Bash. Script Windows tương thích Windows PowerShell 5.1;
  lưu `.ps1`/`.psm1` bằng UTF-8 có BOM để giữ đúng tiếng Việt.
- Comment trong code viết bằng tiếng Anh. Thông báo hiện cho người dùng viết
  bằng tiếng Việt có dấu.
- Chạy [ShellCheck](https://www.shellcheck.net/) trước khi gửi pull request.
  GitHub Actions cũng tự chạy lệnh này cho mỗi pull request:

  ```sh
  shellcheck install.sh uninstall.sh ocr-copy
  ```

- Ghi thay đổi vào mục `[Chưa phát hành]` trong [CHANGELOG.md](CHANGELOG.md).

## Thử nghiệm

Chạy thẳng từ thư mục mã nguồn mà không cần cài:

```sh
./ocr-copy anh-co-chu.png
./ocr-copy   # kéo chọn vùng màn hình
```

Nếu sửa phần chụp màn hình, clipboard hoặc phím tắt, hãy thử bằng phím tắt
Super+Shift+T sau khi chạy `./install.sh`, trên cả phiên Wayland và Xorg nếu có
thể. Lệnh chạy từ phím tắt không có focus bàn phím, nên có lỗi chỉ xuất hiện khi
chạy theo cách này.

Với Windows, kiểm tra logic lõi bằng PowerShell (chạy được cả trên Linux với
PowerShell 7):

```powershell
pwsh -NoProfile -File ./tests/windows.tests.ps1
```

Trên Windows có Tesseract và dữ liệu `vie+eng`, kiểm tra OCR thật, clipboard sau
khi tiến trình kết thúc, cài/cài lại/gỡ và biên dịch overlay:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tests\windows.tests.ps1 -Desktop
```

Bộ kiểm thử này ghi clipboard và tạm thay shortcut Start của ocr-copy, sau đó
khôi phục shortcut đã có. Nên chạy trong phiên Windows dùng để kiểm thử.
GitHub Actions chạy cùng lệnh trên Windows PowerShell 5.1. Thử thủ công thêm
Ctrl+Alt+T, Esc, chuột phải, thông báo, nhiều màn hình và DPI 100%/150%/200%
theo [bản ghi kiểm chứng](docs/windows-validation.md).

## Phát hành (dành cho người duy trì)

1. Chuyển mục `[Chưa phát hành]` trong `CHANGELOG.md` thành phiên bản mới kèm
   ngày, cập nhật các liên kết ở cuối file.
2. Gắn tag và đẩy lên:

   ```sh
   git tag -a v1.0.0 -m v1.0.0
   git push origin v1.0.0
   ```

3. Tạo file phát hành rồi đăng lên trang Releases:

   ```sh
   git archive --format=tar.gz --prefix=ocr-copy/ -o ocr-copy-1.0.0.tar.gz v1.0.0
   gh release create v1.0.0 ocr-copy-1.0.0.tar.gz --title v1.0.0 \
       --notes 'Xem CHANGELOG.md để biết các thay đổi.'
   ```

   File `.gitattributes` loại các file chỉ dùng khi phát triển (`.github/`,
   `.gitignore`, …) ra khỏi file phát hành.
