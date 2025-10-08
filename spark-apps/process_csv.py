from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, avg, desc
import logging

# Thiết lập log level để giảm log
logging.getLogger("org").setLevel(logging.ERROR)
logging.getLogger("akka").setLevel(logging.ERROR)

# Khởi tạo Spark Session với cấu hình tối ưu
spark = SparkSession.builder \
    .appName("CSV Data Processing") \
    .getOrCreate()

try:
    # Đọc dữ liệu CSV từ thư mục data với các tùy chọn tối ưu
    print("Reading CSV data...")
    df = spark.read \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .option("mode", "PERMISSIVE") \
        .option("nullValue", "") \
        .csv("/opt/spark/data/users.csv")
    
    print(f"Loaded DataFrame with {df.count()} rows")
    print("Schema:")
    df.printSchema()
    
    # Hiển thị dữ liệu
    print("Sample data:")
    df.show()
    
    # Thống kê cơ bản
    print("Basic statistics:")
    df.describe().show()
    
    # Thống kê theo quốc gia
    print("Users by country:")
    country_stats = df.groupBy("country").agg(
        count("user_id").alias("user_count"),
        avg("age").alias("avg_age")
    ).orderBy(desc("user_count"))
    
    country_stats.show()
    
    # Lọc theo độ tuổi
    print("Users older than 35:")
    older_users = df.filter(col("age") > 35)
    older_users.show()
    
    # Lưu kết quả thống kê
    output_path = "/opt/spark/data/country_stats"
    print(f"Saving country statistics to {output_path}")
    country_stats.write.mode("overwrite").parquet(output_path)
    
    # Hiển thị Spark UI URL để người dùng có thể truy cập
    print("========================================")
    print("Spark Master UI:    http://localhost:8080")
    print("Spark History UI:   http://localhost:18080")
    print("========================================")

except Exception as e:
    print(f"An error occurred: {e}")
    
finally:
    # Kết thúc Spark Session
    print("Stopping Spark Session...")
    spark.stop()
    print("CSV processing finished")