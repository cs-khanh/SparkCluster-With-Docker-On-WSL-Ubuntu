from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, col, lower, regexp_replace, count

def main():
    # Khởi tạo Spark Session
    spark = SparkSession.builder \
        .appName("Word Count") \
        .config("spark.eventLog.enabled", "true") \
        .config("spark.eventLog.dir", "file:/opt/spark-events") \
        .getOrCreate()
    
    # Đường dẫn input và output (đường dẫn trong cluster)
    input_path = "/opt/spark/data/chipotle.tsv"
    output_path = "/opt/spark/data/out_wordcount_1"
    
    # Đọc file văn bản
    df = spark.read.text(input_path)
    
    # Xử lý text: chuyển về chữ thường, loại bỏ dấu câu, tách từ
    words_df = df.select(
        explode(
            split(
                regexp_replace(lower(col("value")), "[^a-zA-Z0-9\\s]", ""), "\\s+"
            )
        ).alias("word")
    )
    
    # Đếm số lần xuất hiện của mỗi từ
    word_counts = words_df.groupBy("word").agg(count("*").alias("count")).orderBy(col("count").desc())
    
    # Hiển thị kết quả
    print("Word counts:")
    word_counts.show(20)
    
    # Lưu kết quả
    word_counts.write.mode("overwrite").csv(output_path)
    
    print(f"Results saved to {output_path}")
    spark.stop()

if __name__ == "__main__":
    main()