# Hướng dẫn truy cập Worker UI trong môi trường nhiều Worker

Khi bạn chạy nhiều Worker nodes trong Spark Cluster, mỗi Worker sẽ cần một cổng riêng biệt cho WebUI của nó. 
Để tránh xung đột cổng, chúng tôi đã cấu hình hệ thống để:

1. Mỗi Worker tự động sử dụng cổng khác nhau cho WebUI
2. Docker sẽ tự động map các cổng nội bộ 8081 của các Worker ra các cổng khác nhau trên host

## Kiểm tra cổng WebUI của các Worker

Để xem danh sách các Worker đang chạy và cổng WebUI tương ứng, sử dụng lệnh:

```bash
make worker-ports
```

Kết quả sẽ hiển thị dạng:
```
Danh sách cổng WebUI của các Worker:
sparkcluster-spark-worker-1   0.0.0.0:49153->8081/tcp
sparkcluster-spark-worker-2   0.0.0.0:49154->8081/tcp
sparkcluster-spark-worker-3   0.0.0.0:49155->8081/tcp
```

## Truy cập Worker UI

1. Sau khi biết được cổng của Worker (ví dụ: 49153), bạn có thể truy cập WebUI của Worker đó bằng cách mở trình duyệt và nhập địa chỉ:
   ```
   http://localhost:49153
   ```

2. Bạn cũng có thể xem thông tin của tất cả các Worker thông qua Spark Master UI:
   ```bash
   make ui
   ```
   Hoặc truy cập: `http://localhost:8080`

## Lưu ý quan trọng

- Các cổng được ánh xạ sẽ thay đổi mỗi khi bạn khởi động lại cluster
- Luôn sử dụng `make worker-ports` để xác định cổng hiện tại của các Worker
- Spark Master UI (cổng 8080) luôn hiển thị danh sách tất cả các Worker và có liên kết đến WebUI của từng Worker