from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import json

def main():
    # Tạo Spark Session với cấu hình cho cluster (không chỉ định master)
    # Để sử dụng cấu hình từ spark-submit thay vì hardcode trong code
    spark = SparkSession.builder \
        .appName("Kafka Spark Streaming Test - Cluster") \
        .config("spark.sql.streaming.checkpointLocation", "/opt/kafka-data/checkpoints") \
        .config("spark.sql.adaptive.enabled", "false") \
        .config("spark.eventLog.enabled", "true") \
        .config("spark.eventLog.dir", "file:/opt/spark-events") \
        .config("spark.streaming.ui.retainedBatches", "1000") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    
    print("=== Starting Kafka Spark Streaming Test (Cluster Mode) ===")
    
    # Định nghĩa schema cho dữ liệu JSON từ Kafka
    schema = StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("user_id", StringType(), True),
        StructField("product_id", StringType(), True),
        StructField("quantity", IntegerType(), True),
        StructField("price", DoubleType(), True),
        StructField("category", StringType(), True)
    ])
    
    # Đọc dữ liệu từ Kafka topic
    kafka_df = spark \
        .readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "kafka:9092") \
        .option("subscribe", "sales-events") \
        .option("startingOffsets", "latest") \
        .option("maxOffsetsPerTrigger", 1000) \
        .load()
    
    print("Successfully connected to Kafka!")
    
    # Parse JSON data từ Kafka - Đầu tiên cần chuyển value từ binary thành string
    json_df = kafka_df.select(
        col("key").cast("string"),
        col("value").cast("string").alias("value_string"),
        col("timestamp").alias("kafka_timestamp")
    )
    
    # Sau đó mới áp dụng from_json trên chuỗi đã chuyển đổi
    parsed_df = json_df.select(
        col("key"),
        col("kafka_timestamp"),
        from_json(col("value_string"), schema).alias("data")
    ).select(
        col("key"),
        col("kafka_timestamp"),
        col("data.*")
    )
    
    # Thêm xử lý tổng hợp dữ liệu theo category - chỉ chạy trên cluster khi có nhiều tài nguyên
    # Tính tổng doanh thu và số lượng sản phẩm theo danh mục trong cửa sổ 1 phút
    windowed_analytics = parsed_df \
        .withWatermark("kafka_timestamp", "1 minute") \
        .groupBy(
            window(col("kafka_timestamp"), "1 minute"),
            col("category")
        ) \
        .agg(
            sum("quantity").alias("total_quantity"),
            sum(col("price") * col("quantity")).alias("total_revenue"),
            count("*").alias("transaction_count")
        )
    
    # Output query 1: Ghi ra console để kiểm tra với số lượng nhỏ (giám sát)
    console_query = parsed_df \
        .writeStream \
        .outputMode("append") \
        .format("console") \
        .option("truncate", False) \
        .trigger(processingTime='10 seconds') \
        .start()
        
    # Output query 2: Ghi raw data ra file JSON
    file_query = parsed_df \
        .writeStream \
        .outputMode("append") \
        .format("json") \
        .option("path", "/opt/kafka-data/streaming-output") \
        .option("checkpointLocation", "/opt/kafka-data/checkpoints/file-sink") \
        .trigger(processingTime='30 seconds') \
        .start()
    
    # Output query 3: Ghi dữ liệu tổng hợp theo category vào một thư mục riêng
    analytics_query = windowed_analytics \
        .writeStream \
        .outputMode("append") \
        .format("json") \
        .option("path", "/opt/kafka-data/windowed-analytics") \
        .option("checkpointLocation", "/opt/kafka-data/checkpoints/analytics-sink") \
        .trigger(processingTime='1 minute') \
        .start()
    
    print("=== Streaming queries started ===")
    print("1. Console output - every 10 seconds (giám sát dữ liệu raw)")
    print("2. Raw data output - every 30 seconds to kafka-data/streaming-output") 
    print("3. Analytics output - every 1 minute to kafka-data/windowed-analytics")
    print("=== Press Ctrl+C to stop ===")
    
    try:
        # Chờ cho bất kỳ query nào hoàn thành
        spark.streams.awaitAnyTermination()
    except KeyboardInterrupt:
        print("\n=== Stopping streaming queries ===")
        # Đặt timeout để đảm bảo mọi thứ được dừng đúng cách
        console_query.stop()
        file_query.stop()
        analytics_query.stop()
        print("Waiting for queries to terminate completely...")
        try:
            # Đảm bảo các query dừng hoàn toàn
            console_query.awaitTermination(timeout=10000)
            file_query.awaitTermination(timeout=10000)
            analytics_query.awaitTermination(timeout=10000)
        except:
            pass
        print("All queries terminated")
        # Chờ thêm một chút thời gian để đảm bảo event logs được ghi đủ
        import time
        time.sleep(2)
        spark.stop()

if __name__ == "__main__":
    main()