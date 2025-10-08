# Hướng dẫn Kafka Streaming với Apache Spark

Tài liệu này hướng dẫn chi tiết cách thiết lập và chạy ứng dụng Spark Structured Streaming với Kafka trong môi trường Docker.

## Tổng quan về hệ thống

Hệ thống bao gồm các thành phần:

- **Apache Spark**: Cluster với 1 master và nhiều worker nodes
- **Apache Kafka**: Message broker để xử lý dữ liệu streaming
- **Zookeeper**: Quản lý cấu hình và đồng bộ cho Kafka
- **Spark History Server**: Lưu trữ và hiển thị thông tin của các ứng dụng Spark

## Cài đặt và khởi động hệ thống
```bash
#build --no-cache
make build-nc
```
### Xóa tất cả data trong thư mục kafka-data
```bash

sudo rm -rf ./kafka-data/*

```

### Khởi động Cluster

```bash
# Khởi động Spark Cluster với 3 worker, mỗi worker có 2 cores và 2GB RAM
make run-config WORKERS=3 CORES=2 MEMORY=2g
```

### Tạo Kafka Topic

Trước khi chạy ứng dụng streaming, cần tạo Kafka topic:

```bash
make create-kafka-topic
```

Lệnh này sẽ tạo topic "sales-events" với 3 partition.
## 3. Chuẩn bị thư mục dữ liệu

Đảm bảo thư mục kafka-data có quyền ghi cho container:

## 4. Cấp quyền cho thư mục kafka-data
```bash
sudo chmod -R 777 ./kafka-data
## Chạy ứng dụng Streaming

### Khởi chạy ứng dụng Spark Streaming

```bash
make submit-streaming app=test_streaming_cluster.py
```

Lệnh này sẽ khởi chạy ứng dụng Spark Structured Streaming kết nối với Kafka. Lệnh này đã được cấu hình để tự động thêm package Kafka connector cho Spark, cụ thể là:
```
org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0
```

### Phát sinh dữ liệu test

Để tạo dữ liệu mẫu và gửi vào Kafka, mở một terminal mới và chạy:

```bash
make start-producer
```

Lệnh này sẽ chạy script Python để tạo dữ liệu mẫu về các sự kiện bán hàng và gửi vào topic "sales-events".

### Giám sát dữ liệu Kafka

Để xem các thông điệp trong Kafka:

```bash
make kafka-console-consumer
```

## Xem kết quả

### Đầu ra của ứng dụng Streaming

Ứng dụng Spark Streaming được cấu hình để:

1. **Hiển thị dữ liệu raw trên console**: Cập nhật mỗi 10 giây
2. **Ghi raw data**: Ghi vào `/opt/kafka-data/streaming-output` định dạng JSON, cập nhật mỗi 30 giây
3. **Ghi dữ liệu tổng hợp**: Ghi vào `/opt/kafka-data/windowed-analytics` dạng JSON, cập nhật mỗi 1 phút

### Kiểm tra output files

```bash
make check-streaming-data
```

Lệnh này sẽ hiển thị các file đầu ra và checkpoints.

### Xóa dữ liệu streaming

```bash
make clean-streaming-data
```

Lệnh này sẽ xóa tất cả dữ liệu output và checkpoints.

## Giám sát và Debug

### Spark UI

- **Spark Master UI**: http://localhost:8080
- **Spark History Server**: http://localhost:18080

### Xem logs

```bash
# Xem logs của master node
make logs-master

# Xem logs của history server
make logs-history

# Xem logs của Kafka
docker logs sparkcluster-kafka
```

## Cấu trúc dữ liệu

### Schema dữ liệu input

Dữ liệu được gửi từ Kafka có cấu trúc:

```json
{
  "timestamp": "2025-10-08T04:30:00",
  "user_id": "user_123",
  "product_id": "electronics_laptop_42",
  "quantity": 2,
  "price": 1299.99,
  "category": "Electronics"
}
```

### Xử lý dữ liệu trong Streaming App

Ứng dụng streaming thực hiện:

1. **Đọc dữ liệu từ Kafka**: Kết nối đến broker và đọc messages
2. **Chuyển đổi dữ liệu**: Parse JSON và cast types
3. **Window-based Aggregation**: Tính tổng số lượng và doanh thu theo danh mục trong cửa sổ 1 phút

## Troubleshooting

### Lỗi liên quan đến Kafka Connection

Nếu gặp lỗi kết nối đến Kafka:

1. Đảm bảo Kafka đã được khởi động: `docker ps | grep kafka`
2. Kiểm tra topic đã được tạo: `make kafka-list-topics`
3. Kiểm tra Kafka logs: `docker logs sparkcluster-kafka`

### Lỗi "Data source not found: kafka"

Đây là lỗi thường gặp khi thiếu package Kafka connector:

1. Luôn sử dụng `make submit-streaming` thay vì `make submit` để chạy ứng dụng streaming
2. Package cần thiết: `org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0`

### Lỗi Output Mode không hỗ trợ

Lưu ý rằng:
- Format JSON chỉ hỗ trợ output mode "append" và "complete"
- Không hỗ trợ mode "update" với JSON

## Những điểm cần lưu ý

1. **Mount Volumes**: Thư mục `kafka-data` trong host được mount vào container Kafka và cũng là nơi ứng dụng streaming lưu dữ liệu
   
2. **History Server**: Log của ứng dụng streaming sẽ xuất hiện trong History Server khi ứng dụng kết thúc, hoặc theo định kỳ trong file `.inprogress`

3. **Phiên bản tương thích**: Đảm bảo phiên bản Spark (3.4.0) và Kafka connector phải tương thích với nhau