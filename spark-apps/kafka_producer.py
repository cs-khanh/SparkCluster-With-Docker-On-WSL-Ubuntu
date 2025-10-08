import json
import time
import random
from datetime import datetime
from kafka import KafkaProducer

def create_sample_data():
    """Tạo dữ liệu mẫu cho sales events"""
    categories = ["Electronics", "Clothing", "Books", "Home", "Sports", "Food"]
    products = {
        "Electronics": ["laptop", "phone", "tablet", "headphones", "camera"],
        "Clothing": ["shirt", "pants", "jacket", "shoes", "hat"],
        "Books": ["novel", "textbook", "magazine", "comic", "biography"],
        "Home": ["furniture", "kitchen", "decoration", "lighting", "bedding"],
        "Sports": ["ball", "equipment", "clothing", "shoes", "accessories"],
        "Food": ["snacks", "drinks", "fruits", "vegetables", "meat"]
    }
    
    category = random.choice(categories)
    product = random.choice(products[category])
    
    return {
        "timestamp": datetime.now().isoformat(),
        "user_id": f"user_{random.randint(1, 1000)}",
        "product_id": f"{category.lower()}_{product}_{random.randint(1, 100)}",
        "quantity": random.randint(1, 5),
        "price": round(random.uniform(10.0, 500.0), 2),
        "category": category
    }

def main():
    # Cấu hình Kafka Producer
    producer = KafkaProducer(
        bootstrap_servers=['kafka:9092'],
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        key_serializer=lambda v: str(v).encode('utf-8') if v else None
    )
    
    topic_name = 'sales-events'
    
    print(f"Starting to send data to Kafka topic: {topic_name}")
    print("Press Ctrl+C to stop...")
    
    try:
        message_count = 0
        while True:
            # Tạo dữ liệu mẫu
            data = create_sample_data()
            key = data['user_id']
            
            # Gửi message tới Kafka
            future = producer.send(topic_name, key=key, value=data)
            
            # Đợi xác nhận
            try:
                record_metadata = future.get(timeout=10)
                message_count += 1
                print(f"Message {message_count} sent: {data['category']} - ${data['price']:.2f}")
                
            except Exception as e:
                print(f"Failed to send message: {e}")
            
            # Đợi 1-3 giây trước khi gửi message tiếp theo
            time.sleep(random.uniform(1, 3))
            
    except KeyboardInterrupt:
        print(f"\n=== Stopped. Sent {message_count} messages ===")
    finally:
        producer.close()

if __name__ == "__main__":
    main()