# Hướng dẫn sử dụng Spark History Server

Spark History Server là công cụ quan trọng giúp bạn theo dõi, phân tích và debug các ứng dụng Spark sau khi chúng đã hoàn thành việc thực thi. Tài liệu này sẽ hướng dẫn bạn cách sử dụng History Server hiệu quả.

## 1. Truy cập Spark History Server

Trong môi trường hiện tại, History Server được chạy trên cổng 18080:

```bash
# Mở History Server UI trong trình duyệt
make history-ui

# Hoặc truy cập thủ công qua URL
# http://localhost:18080
```

## 2. Các thành phần chính trong History Server UI

### a. Trang chủ (Applications)

Trang chủ hiển thị danh sách các ứng dụng Spark đã chạy, với các thông tin:
- **ID**: Định danh duy nhất của ứng dụng (ví dụ: app-20250926043453-0001)
- **Name**: Tên của ứng dụng
- **Cores**: Số lượng cores được sử dụng
- **User**: Người dùng đã submit ứng dụng
- **State**: Trạng thái của ứng dụng (completed, failed, etc.)
- **Duration**: Thời gian chạy
- **Completed**: Thời gian hoàn thành

### b. Chi tiết ứng dụng

Khi nhấp vào một ứng dụng, bạn sẽ thấy các tab sau:

#### Jobs
- Danh sách tất cả các jobs trong ứng dụng
- Thời gian bắt đầu, kết thúc và thời gian thực thi
- Trạng thái (succeeded, failed)
- Số stages trong mỗi job

#### Stages
- Danh sách tất cả các stages trong ứng dụng
- Số lượng tasks trong mỗi stage
- Thông tin về input/output
- Chi tiết về việc shuffle dữ liệu

#### Storage
- Thông tin về các RDD được cached
- Kích thước và mức độ lưu trữ (memory, disk)

#### Environment
- Thông tin về môi trường thực thi
- Các cấu hình Spark được sử dụng
- Các properties của JVM
- Các biến môi trường

#### Executors
- Danh sách các executors đã tham gia xử lý
- Thống kê về resource usage (CPU, memory)
- Thời gian hoạt động

#### SQL
- Nếu ứng dụng sử dụng Spark SQL, tab này hiển thị các SQL queries
- Execution plan và thời gian thực thi

## 3. Phân tích hiệu năng với History Server

### a. Phân tích Job và Stage

1. **Xác định stage chạy lâu nhất**:
   - Trong tab "Stages", sắp xếp theo "Duration" để tìm stages chạy lâu
   - Nhấp vào stage đó để xem chi tiết

2. **Phân tích chi tiết Stage**:
   - Xem "Summary Metrics" để hiểu về hiệu năng
   - Chú ý đến "Shuffle Read/Write" để xem lượng dữ liệu được di chuyển
   - Kiểm tra "Input" và "Output" để hiểu về lượng dữ liệu xử lý

3. **Kiểm tra skewed data**:
   - Trong chi tiết Stage, xem các task có thời gian thực thi chênh lệch lớn
   - Nếu có tasks chạy lâu hơn nhiều, có thể có vấn đề về data skew

### b. Timeline và Event đặc biệt

1. **Event Timeline**:
   - Hiển thị trực quan thời gian thực thi các task
   - Giúp phát hiện các khoảng thời gian chờ (idle time)

2. **DAG Visualization**:
   - Biểu đồ luồng dữ liệu giúp hiểu cách dữ liệu được xử lý
   - Xác định dependencies giữa các RDD

## 4. Debug lỗi ứng dụng

### a. Tìm lỗi trong Jobs và Stages

1. **Failed Jobs**:
   - Các jobs thất bại sẽ được đánh dấu màu đỏ
   - Nhấp vào để xem chi tiết lỗi

2. **Exception trong Tasks**:
   - Trong chi tiết Stage, tìm các tasks bị failed
   - Xem "Error" để biết chi tiết exception
   - Đọc stack trace để xác định vấn đề

### b. Logs và Metrics

1. **Executor Logs**:
   - Trong tab "Executors", bạn có thể xem logs của từng executor
   - Tìm các warning và error trong logs

2. **GC (Garbage Collection) Metrics**:
   - Xem thời gian GC trong tab "Executors"
   - GC time cao có thể chỉ ra vấn đề về memory pressure

## 5. Best practices khi sử dụng History Server

### a. Tổ chức ứng dụng

1. **Đặt tên có ý nghĩa cho ứng dụng**:
   ```python
   spark = SparkSession.builder \
       .appName("DataProcessingPipeline-UserAnalytics") \
       .getOrCreate()
   ```

2. **Sử dụng các metrics tùy chỉnh**:
   ```python
   with SparkSession.builder.appName("CustomMetricsExample").getOrCreate() as spark:
       accum = spark.sparkContext.accumulator(0)
       # Sử dụng accum để đếm các sự kiện quan trọng
   ```

### b. Cấu hình History Server

1. **Tăng mức độ chi tiết của logs**:
   ```properties
   # Thêm vào spark-defaults.conf
   spark.eventLog.enabled true
   spark.eventLog.logStageExecutorMetrics true
   spark.executor.processTreeMetrics.enabled true
   ```

2. **Cấu hình retention**:
   ```properties
   # Giữ logs trong 7 ngày
   spark.history.fs.cleaner.enabled true
   spark.history.fs.cleaner.maxAge 7d
   ```

## 6. Các trường hợp sử dụng phổ biến

### a. Performance tuning

1. **Xác định data skew**:
   - Kiểm tra distribution của task times trong stages
   - Tái cấu trúc partitions nếu có skew đáng kể

2. **Tối ưu memory usage**:
   - Xem "Peak Memory Usage" trong Executor metrics
   - Điều chỉnh cấu hình memory nếu cần

### b. Capacity planning

1. **Resource utilization**:
   - Xem CPU và memory usage của executors
   - Cấu hình lại số lượng executors hoặc cores/memory cho mỗi executor

2. **Job duration trends**:
   - Theo dõi thời gian chạy của các ứng dụng qua thời gian
   - Điều chỉnh cấu hình cluster dựa trên xu hướng

## 7. Kết hợp với các công cụ khác

History Server hoạt động tốt khi kết hợp với các công cụ monitoring khác:

1. **Ganglia/Prometheus/Grafana**:
   - Giám sát system metrics (CPU, memory, network, disk)
   - Tạo dashboards cho metrics hệ thống

2. **Log aggregation (ELK stack)**:
   - Thu thập logs từ tất cả các nodes
   - Tìm kiếm và phân tích logs

## 8. Khắc phục sự cố thường gặp

### a. Event logs không xuất hiện

Nếu các ứng dụng không hiển thị trong History Server:

1. Kiểm tra cấu hình spark.eventLog.enabled trong spark-defaults.conf
2. Xác nhận đường dẫn trong spark.eventLog.dir là chính xác
3. Kiểm tra quyền truy cập vào thư mục logs
4. Kiểm tra logs của History Server để tìm lỗi

### b. History Server chậm hoặc không phản hồi

1. Kiểm tra số lượng event logs (quá nhiều logs có thể làm chậm History Server)
2. Cấu hình tăng memory cho History Server
3. Cấu hình cleaner để tự động xóa logs cũ

## 9. Kết luận

Spark History Server là công cụ không thể thiếu để hiểu, phân tích và cải thiện hiệu năng của các ứng dụng Spark. Việc sử dụng hiệu quả History Server có thể giúp:

- Phát hiện và khắc phục bottlenecks trong code
- Tối ưu sử dụng tài nguyên (CPU, memory)
- Debug lỗi ứng dụng một cách hiệu quả
- Xác định cấu hình tốt nhất cho workload cụ thể

Hãy sử dụng History Server như một công cụ hàng ngày trong quá trình phát triển và vận hành các ứng dụng Spark để đảm bảo hiệu suất và độ tin cậy tối ưu.