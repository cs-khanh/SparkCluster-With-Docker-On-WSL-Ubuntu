from pyspark.sql import SparkSession
from pyspark.sql.functions import col, rand, expr, desc, sum as spark_sum
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, DateType
from datetime import datetime, timedelta

# Khởi tạo Spark Session với log level thấp hơn để xem thông tin về executor
spark = SparkSession.builder \
    .appName("Data Generator and Analysis") \
    .config("spark.executor.memory", "1g") \
    .getOrCreate()

# Hiển thị thông tin về Spark application
sc = spark.sparkContext
print(f"Spark Application ID: {sc.applicationId}")
print(f"Spark Web UI URL: {sc.uiWebUrl}")
print(f"Number of Executors: {sc._jsc.sc().getExecutorMemoryStatus().size() - 1}")  # -1 cho driver

# Định nghĩa schema cho dữ liệu
schema = StructType([
    StructField("user_id", StringType(), False),
    StructField("name", StringType(), False),
    StructField("age", IntegerType(), False),
    StructField("email", StringType(), False),
    StructField("country", StringType(), False),
    StructField("registration_date", DateType(), False),
    StructField("purchase_count", IntegerType(), False),
    StructField("total_spent", DoubleType(), False)
])

# Các giá trị mẫu - sử dụng trực tiếp trong biểu thức SQL
countries = ["Vietnam", "USA", "Japan", "China", "Singapore", "Thailand", "Australia", "France", "Germany", "UK"]

# Hàm tạo dữ liệu mẫu
def generate_sample_data(num_rows=1000000):
    print(f"Generating {num_rows} rows of sample data...")
    
    # Sử dụng range để tạo DataFrame với số lượng hàng cần thiết
    df = spark.range(num_rows)
    
    # Tạo user_id
    df = df.withColumn("user_id", expr("concat('USER_', id)"))
    
    # Tạo name đơn giản
    df = df.withColumn("name", expr("concat('User_', cast(id as string))"))
    
    # Tạo age từ 18-70
    df = df.withColumn("age", expr("cast(rand() * 52 + 18 as int)"))
    
    # Tạo email
    df = df.withColumn("email", expr("concat('user', id, '@example.com')"))
    
    # Tạo country
    country_array = ', '.join([f"'{c}'" for c in countries])
    df = df.withColumn("country", expr(f"array({country_array})[cast(rand() * {len(countries)} as int)]"))
    
    # Tạo registration_date (trong 3 năm gần đây)
    start_date = datetime.now() - timedelta(days=3*365)
    days_range = 3 * 365
    df = df.withColumn("registration_date", 
                      expr(f"date_add('{start_date.strftime('%Y-%m-%d')}', cast(rand() * {days_range} as int))"))
    
    # Tạo purchase_count (0-100)
    df = df.withColumn("purchase_count", expr("cast(rand() * 100 as int)"))
    
    # Tạo total_spent (0-10000)
    df = df.withColumn("total_spent", expr("cast(rand() * 10000 as double)"))
    
    # Chọn các cột theo schema
    return df.select(schema.fieldNames())

# Tạo dữ liệu mẫu
df_users = generate_sample_data(1000000)  # Tạo 1 triệu bản ghi

# Hiển thị thông tin và mẫu dữ liệu
print(f"Generated {df_users.count()} rows of data")
print("Schema:")
df_users.printSchema()

print("Sample data:")
df_users.show(5)

# Lưu dữ liệu vào định dạng Parquet
output_path = "/opt/spark/data/users_large.parquet"
print(f"Saving data to {output_path}...")
df_users.write.mode("overwrite").parquet(output_path)
print("Data saved successfully!")

# Phân tích dữ liệu
print("\n--- DATA ANALYSIS ---\n")

# Đọc lại từ Parquet file để kiểm tra và phân tích
df_loaded = spark.read.parquet(output_path)
print(f"Successfully loaded {df_loaded.count()} rows from Parquet")

# Phân tích 1: Thống kê theo quốc gia
print("\nUser statistics by country:")
country_stats = df_loaded.groupBy("country").agg(
    spark_sum("purchase_count").alias("total_purchases"),
    spark_sum("total_spent").alias("total_revenue"),
    expr("count(*)").alias("user_count")
).orderBy(desc("total_revenue"))

country_stats.show()

# Phân tích 2: Phân phối độ tuổi
print("\nAge distribution:")
df_loaded.groupBy("age").count().orderBy("age").show()

# Phân tích 3: Top 10 người dùng chi tiêu nhiều nhất
print("\nTop 10 highest spending users:")
df_loaded.orderBy(desc("total_spent")).select("user_id", "name", "country", "total_spent").show(10)

# Phân tích 4: Phân tích theo ngày đăng ký
print("\nRegistration trends (by month):")
df_loaded.withColumn("reg_month", expr("date_format(registration_date, 'yyyy-MM')")) \
    .groupBy("reg_month") \
    .count() \
    .orderBy("reg_month") \
    .show(24)  # Hiển thị 24 tháng gần nhất

# In thông tin chi tiết về thực thi
print("\n--- SPARK EXECUTION INFO ---\n")
print(f"Spark Application ID: {sc.applicationId}")

# In thông tin về worker đang chạy (cách an toàn hơn)
print("Active Worker Nodes:")
worker_hosts = []
for executor in sc._jsc.sc().statusTracker().getExecutorInfos():
    try:
        if executor.host() not in worker_hosts and executor.host() != "driver":
            worker_hosts.append(executor.host())
            print(f"  Worker on {executor.host()}")
    except:
        pass

# Đóng Spark Session
spark.stop()
print("Spark session closed.")