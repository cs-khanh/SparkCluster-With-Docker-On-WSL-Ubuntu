# Ví dụ cấu hình worker với tài nguyên khác nhau

## 1. Cấu hình cơ bản với một worker

```bash
# Khởi động cluster với 1 worker, 2 cores và 2GB RAM
make run-config WORKERS=1 CORES=2 MEMORY=2g
```

## 2. Cấu hình với nhiều worker

```bash
# Khởi động cluster với 3 worker, mỗi worker có 2 cores và 2GB RAM
make run-config WORKERS=3 CORES=2 MEMORY=2g
```

## 3. Khởi động cluster ở chế độ detached (chạy ngầm)

```bash
# Khởi động cluster với 3 worker, mỗi worker có 2 cores và 3GB RAM ở chế độ detached
make run-config-d WORKERS=3 CORES=2 MEMORY=3g
```

## 4. Cấu hình cho môi trường sản xuất

```bash
# Khởi động cluster với 5 worker, mỗi worker có 4 cores và 8GB RAM
make run-config-d WORKERS=5 CORES=4 MEMORY=8g
```

## 5. Kiểm tra cấu hình worker

Sau khi khởi động cluster, bạn có thể mở Spark Master UI để kiểm tra cấu hình của các worker:

```bash
make ui
```

Hoặc mở trình duyệt và truy cập địa chỉ: http://localhost:8080

## Lưu ý quan trọng:

1. **Giá trị memory phải có đơn vị**: Sử dụng `g` cho gigabyte, `m` cho megabyte.
   - Ví dụ: `MEMORY=2g` (2GB) hoặc `MEMORY=512m` (512MB)

2. **Cores nên phù hợp với máy thật**: Không nên cấu hình số cores vượt quá số lõi vật lý/logic của máy chủ.

3. **Giám sát hiệu suất**: Sau khi cấu hình, hãy kiểm tra trên Spark Master UI để xác nhận cấu hình đã được áp dụng.

4. **Cân nhắc cấu hình Docker**: Nếu bạn đang sử dụng Docker Desktop, đảm bảo bạn đã phân bổ đủ tài nguyên cho Docker Engine (trong Docker Desktop Settings).