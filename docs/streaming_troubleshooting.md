# Quản lý Spark Streaming Jobs và Giải quyết vấn đề hiển thị "Running" trong History Server

## Vấn đề

Khi dừng một Spark Structured Streaming job bằng Ctrl+C, đôi khi job vẫn hiển thị là "running" trong Spark History Server. Điều này xảy ra vì Spark không có đủ thời gian để dọn dẹp và đóng các event log một cách đúng đắn, dẫn đến History Server không biết rằng job đã thực sự kết thúc.

## Nguyên nhân

1. **Structured Streaming là continuous application**: Khác với các Spark job thông thường, Structured Streaming chạy liên tục cho đến khi được dừng một cách rõ ràng.
   
2. **Tín hiệu SIGINT (Ctrl+C) xử lý không hoàn chỉnh**: Khi nhấn Ctrl+C, đôi khi tín hiệu này bị hệ thống xử lý trước khi đến được mã Python, ngăn cản việc thực hiện các bước dọn dẹp cần thiết.

3. **Event logs không được đóng đúng cách**: File event log kết thúc với phần mở rộng `.inprogress`, cho biết History Server rằng ứng dụng vẫn đang chạy.

## Giải pháp đã thực hiện

1. **Cải thiện graceful termination trong mã**:
   - Thêm timeout cho việc dừng các streaming query
   - Đợi cho đến khi các query được dừng hoàn toàn
   - Thêm sleep để đảm bảo event logs được ghi đầy đủ

2. **Tạo script quản lý streaming (streaming_manager.sh)**:
   - `./streaming_manager.sh start`: Khởi động streaming job
   - `./streaming_manager.sh stop`: Dừng mọi streaming job đang chạy một cách đúng đắn
   - `./streaming_manager.sh restart`: Khởi động lại streaming job
   - `./streaming_manager.sh status`: Kiểm tra trạng thái của các jobs

3. **Thêm các lệnh make mới**:
   - `make streaming-start`: Khởi động streaming an toàn
   - `make streaming-stop`: Dừng tất cả các streaming job đang chạy
   - `make streaming-stop-app app=<app-id>`: Dừng một streaming job cụ thể theo ID
   - `make streaming-restart`: Khởi động lại streaming
   - `make streaming-status`: Kiểm tra trạng thái chi tiết của các job
   - `make streaming-cleanup`: Làm sạch các file `.inprogress` và khởi động lại History Server

## Cách sử dụng

Thay vì chạy trực tiếp `make submit-streaming app=test_streaming_cluster.py`, hãy sử dụng các lệnh quản lý streaming sau:

1. **Khởi động streaming**:
   ```bash
   make streaming-start
   ```

2. **Kiểm tra trạng thái chi tiết**:
   ```bash
   make streaming-status
   ```
   Lệnh này sẽ hiển thị:
   - Danh sách các ứng dụng đang chạy trên Spark Master
   - Tất cả các file event log trong thư mục `/opt/spark-events/`
   - Các file `.inprogress` (ứng dụng được coi là đang chạy)

3. **Dừng tất cả các streaming job**:
   ```bash
   make streaming-stop
   ```

4. **Dừng một streaming job cụ thể dựa trên ID**:
   ```bash
   # Cú pháp:
   make streaming-stop-app app=<application-id>
   
   # Ví dụ:
   make streaming-stop-app app=app-20251008045016-0001
   ```
   Lệnh này đặc biệt hữu ích khi có nhiều ứng dụng Spark chạy đồng thời và bạn chỉ muốn dừng một ứng dụng cụ thể.

5. **Khởi động lại streaming**:
   ```bash
   make streaming-restart
   ```

6. **Làm sạch các file `.inprogress` treo**:
   ```bash
   make streaming-cleanup
   ```
   Sử dụng lệnh này khi bạn thấy các file `.inprogress` trong output của `make streaming-status` nhưng không có ứng dụng nào đang thực sự chạy.

## Xử lý thủ công khi job treo

Nếu vẫn có job hiện thị là "running" trong History Server sau khi dùng `streaming-stop`:

1. **Sử dụng lệnh mới để làm sạch trạng thái**:
   ```bash
   make streaming-cleanup
   ```
   Lệnh này sẽ tự động:
   - Chuyển các file `.inprogress` thành `.completed`
   - Khởi động lại History Server để làm mới trạng thái

2. **Hoặc nếu muốn xử lý thủ công**:
   ```bash
   # Kiểm tra và kill các ứng dụng đang chạy
   docker exec da-spark-master spark-submit --status
   docker exec da-spark-master spark-submit --kill <application-id>
   
   # Đổi tên file .inprogress bằng cách xóa phần đuôi .inprogress
   docker exec da-spark-master bash -c 'for f in /opt/spark-events/*.inprogress; do mv "$f" "${f%.inprogress}"; done'
   
   # Khởi động lại History Server
   docker restart da-spark-history
   ```

## Định dạng ID ứng dụng Spark

Trong Spark, ID ứng dụng có định dạng như sau:
```
app-YYYYMMDDhhmmss-nnnn
```
Trong đó:
- `YYYY`: Năm
- `MM`: Tháng
- `DD`: Ngày
- `hh`: Giờ
- `mm`: Phút
- `ss`: Giây
- `nnnn`: Số thứ tự của ứng dụng

Ví dụ: `app-20251008045016-0001` là ứng dụng được khởi chạy vào ngày 08/10/2025 lúc 04:50:16, và là ứng dụng thứ 0001 trong ngày.

## Xác định và xử lý các trường hợp job "zombie"

Job "zombie" là các Spark job đã kết thúc thực tế nhưng vẫn hiển thị là "running" trong History Server. Để xác định các job này:

1. **Kiểm tra trạng thái chi tiết**:
   ```bash
   make streaming-status
   ```

2. **Phân tích output**:
   - Nếu output hiển thị "Không có ứng dụng nào đang chạy trên Spark Master" nhưng có các file `.inprogress`, đây là dấu hiệu của job "zombie"

3. **Xử lý**:
   - Nếu biết chính xác ID ứng dụng: `make streaming-stop-app app=<app-id>`
   - Nếu muốn làm sạch tất cả: `make streaming-cleanup`

## Lưu ý quan trọng

- Luôn dùng `make streaming-stop` hoặc `make streaming-stop-app` thay vì Ctrl+C để dừng streaming job
- Nếu job vẫn hiển thị là "running" trong History Server, hãy dùng `make streaming-cleanup`
- Kiểm tra output của `make streaming-status` để xác định trạng thái thực sự của các job
- Để tránh lỗi checkpoint, hãy xóa các checkpoint cũ nếu bạn thay đổi logic xử lý dữ liệu: `make clean-streaming-data`

## Cách hoạt động của History Server và Event Log

- Khi một Spark application chạy, nó tạo ra một file event log với đuôi `.inprogress`
- Khi application kết thúc một cách bình thường, Spark sẽ bỏ đuôi `.inprogress` khỏi tên file
- Nếu application bị buộc dừng đột ngột (như với Ctrl+C), file log vẫn giữ đuôi `.inprogress`
- History Server sử dụng đuôi file này để xác định trạng thái của application
- Lệnh `streaming-cleanup` giải quyết vấn đề bằng cách thủ công bỏ đuôi `.inprogress` khỏi tên file

## Các tình huống thường gặp và cách giải quyết

| Tình huống | Triệu chứng | Giải pháp |
|------------|-------------|-----------|
| Job bị dừng bởi Ctrl+C | Job hiển thị là "running" trong History Server | `make streaming-cleanup` |
| Nhiều job trong trạng thái "running" | Nhiều file `.inprogress` | `make streaming-cleanup` |
| Cần dừng một job cụ thể | Job với application-ID đã biết đang chạy | `make streaming-stop-app app=<app-id>` |
| Checkpoint errors | Lỗi khi khởi động streaming lại | `make clean-streaming-data` và khởi động lại |
| History Server không hiển thị log mới | Không thấy ứng dụng mới trong UI | `docker restart da-spark-history` |
| Streaming không nhận dữ liệu | Không thấy output mới trong thư mục đích | Kiểm tra producer với `make start-producer` |

## Các lệnh hữu ích khác

### Theo dõi log của Spark Master
```bash
make logs-master
```

### Theo dõi log của History Server
```bash
make logs-history
```

### Kiểm tra dữ liệu streaming output
```bash
make check-streaming-data
```

### Giám sát tin nhắn Kafka trực tiếp
```bash
make kafka-console-consumer
```

### Làm sạch dữ liệu streaming output và checkpoint
```bash
make clean-streaming-data
```

## Workflow khuyến nghị

1. **Khởi động cluster và Kafka**:
   - Kiểm tra trạng thái: `make status`
   - Nếu chưa chạy: `make run-d`

2. **Khởi động streaming**:
   - `make streaming-start`
   - Kiểm tra trạng thái: `make streaming-status`

3. **Phát sinh dữ liệu test**:
   - `make start-producer`

4. **Theo dõi output**:
   - `make check-streaming-data`
   - Hoặc theo dõi console: `make logs-master`

5. **Dừng streaming một cách đúng đắn**:
   - `make streaming-stop` hoặc `make streaming-stop-app app=<app-id>`

6. **Làm sạch trạng thái nếu cần**:
   - `make streaming-cleanup`

## Tổng kết

Trong môi trường Spark Streaming, việc quản lý trạng thái của các job và đảm bảo History Server hiển thị chính xác là rất quan trọng. Các công cụ và hướng dẫn trong tài liệu này giúp bạn:

1. **Quản lý streaming job một cách hiệu quả**:
   - Khởi động, dừng, và theo dõi trạng thái các job
   - Xử lý từng job riêng biệt khi cần thiết

2. **Xử lý các vấn đề phổ biến**:
   - Jobs "zombie" vẫn hiển thị là "running"
   - File event log bị mắc kẹt với đuôi `.inprogress`
   - Lỗi checkpoint khi khởi động lại

3. **Hiểu cách hoạt động bên trong của Spark**:
   - Cơ chế event logging của Spark
   - Cách History Server xác định trạng thái job
   - Quy trình dừng graceful cho streaming applications

Nhớ rằng việc luôn sử dụng các lệnh quản lý (`streaming-start`, `streaming-stop`, `streaming-status`) thay vì gọi trực tiếp `spark-submit` sẽ giúp tránh được nhiều vấn đề trạng thái không nhất quán.