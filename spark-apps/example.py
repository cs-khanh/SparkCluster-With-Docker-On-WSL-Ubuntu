from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, rand
import time

# Khởi tạo Spark Session
spark = SparkSession.builder \
    .appName("SparkExample") \
    .getOrCreate()

# Thông báo khi bắt đầu
print("========================================")
print("Spark application started")
print("========================================")

try:
    # Tạo DataFrame với 100,000 dòng dữ liệu ngẫu nhiên
    print("Generating random data...")
    
    # Tạo dữ liệu mẫu có cấu trúc
    data = [(i, f"user_{i % 100}", i * 10.0) for i in range(100000)]
    columns = ["id", "name", "value"]
    
    # Tạo DataFrame từ dữ liệu
    df = spark.createDataFrame(data, columns)
    
    print(f"Created DataFrame with {df.count()} rows")
    print("Schema:")
    df.printSchema()
    
    # Hiển thị một vài dòng dữ liệu
    print("Sample data:")
    df.show(5)
    
    # Thực hiện một số phép biến đổi
    print("Performing transformations...")
    
    # Lọc các giá trị > 50000
    filtered_df = df.filter(col("value") > 500000)
    print(f"Filtered rows with value > 500000: {filtered_df.count()}")
    
    # Thống kê theo nhóm
    from pyspark.sql.functions import sum as sum_
    grouped_df = df.groupBy("name").agg(count("id").alias("count"), 
                                         (sum_("value") / 1000).alias("value_k"))
    
    print("Group by results:")
    grouped_df.orderBy(col("count").desc()).show(10)
    
    # Lưu dữ liệu vào thư mục data để xem sau
    output_path = "/opt/spark/data/example_output"
    print(f"Saving results to {output_path}")
    
    # Hiển thị số lượng partition để debug
    print(f"DataFrame has {grouped_df.rdd.getNumPartitions()} partitions")
    
    try:
        # Giảm số lượng partition để tránh lỗi khi ghi nhiều file nhỏ
        print("Coalescing partitions to 1 for simpler output...")
        grouped_df = grouped_df.coalesce(1)
        print("Writing data to parquet files...")
        grouped_df.write.mode("overwrite").parquet(output_path)
        print("Successfully wrote data to parquet files!")
        
        # Kiểm tra output đã tạo
        import os
        if os.path.exists(output_path):
            files = os.listdir(output_path)
            print(f"Output directory contains {len(files)} files/directories:")
            for f in files:
                print(f"  - {f}")
        else:
            print(f"WARNING: Output directory {output_path} does not exist after write operation!")
        
        # Đọc lại dữ liệu để kiểm tra
        read_df = spark.read.parquet(output_path)
        print(f"Read back data from {output_path}, row count: {read_df.count()}")
    except Exception as e:
        print(f"ERROR writing to {output_path}: {e}")
        import traceback
        traceback.print_exc()
    
    # Cố tình tạo ra một thao tác tốn tài nguyên để thấy được Spark xử lý phân tán
    print("Running a resource-intensive operation...")
    complex_df = df.crossJoin(df.select("id").limit(10))
    print(f"Generated a large DataFrame through cross join: {complex_df.count()} rows")
    
    # Hiển thị Spark UI URL để người dùng có thể truy cập
    print("========================================")
    print("Spark Master UI:    http://localhost:8080")
    print("Spark History UI:   http://localhost:18080")
    print("========================================")
    
    # Dừng một chút để người dùng có thời gian xem UI
    print("Waiting for 30 seconds before finishing the job...")
    time.sleep(30)

except Exception as e:
    print(f"An error occurred: {e}")
    
finally:
    # Kết thúc Spark Session
    print("Stopping Spark Session...")
    spark.stop()
    print("Spark application finished")