#!/bin/bash

# Script để tạo Kafka topic cho streaming test

echo "Checking running containers..."
docker ps | grep -i kafka

echo "Creating Kafka topic: sales-events"

# Tìm container Kafka
KAFKA_CONTAINER=$(docker ps -qf "name=sparkcluster-kafka")

if [ -z "$KAFKA_CONTAINER" ]; then
    echo "ERROR: Không tìm thấy container Kafka!"
    echo "Kiểm tra lại tên container Kafka đang chạy:"
    docker ps | grep -E 'NAME|kafka|NAMES'
    exit 1
fi

# Tạo topic với 3 partitions và replication factor 1
docker exec -it $KAFKA_CONTAINER /usr/bin/kafka-topics \
    --create \
    --topic sales-events \
    --bootstrap-server localhost:9092 \
    --partitions 3 \
    --replication-factor 1

echo "Topic created successfully!"

# Liệt kê tất cả các topics
echo "Available topics:"
docker exec -it $KAFKA_CONTAINER /usr/bin/kafka-topics \
    --list \
    --bootstrap-server localhost:9092

echo "Done!"