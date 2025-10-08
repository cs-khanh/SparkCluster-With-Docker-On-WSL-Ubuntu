#!/bin/bash

# Script to manage Spark streaming jobs
# Usage: ./streaming_manager.sh [start|stop|restart|status|stop-app <app-id>]

SPARK_MASTER="da-spark-master"

start_streaming() {
    echo "Starting Kafka Spark Streaming application..."
    make submit-streaming app=test_streaming_cluster.py
}

stop_streaming() {
    echo "Stopping all running Spark applications..."
    docker exec $SPARK_MASTER /bin/bash -c 'for app in $(spark-submit --status | grep RUNNING | cut -d " " -f1); do spark-submit --kill $app; done'
    echo "Waiting for applications to shut down..."
    sleep 3
    
    # Xử lý file .inprogress nếu job vẫn treo trong History Server
    echo "Checking for stuck .inprogress files..."
    INPROGRESS_COUNT=$(docker exec $SPARK_MASTER bash -c "ls -la /opt/spark-events/*.inprogress 2>/dev/null | wc -l")
    if [ "$INPROGRESS_COUNT" -gt "0" ]; then
        echo "Found $INPROGRESS_COUNT stuck .inprogress files. Cleaning up..."
        # Đổi tên các file .inprogress bằng cách bỏ phần đuôi .inprogress
        docker exec $SPARK_MASTER bash -c 'for f in /opt/spark-events/*.inprogress; do mv "$f" "${f%.inprogress}"; done'
        echo "Restarting History Server to refresh application status..."
        docker restart da-spark-history
        sleep 2
    fi
    
    echo "Status after stopping:"
    check_status
}

restart_streaming() {
    stop_streaming
    sleep 2
    start_streaming
}

check_status() {
    echo "Checking Spark application status..."
    
    # Kiểm tra các ứng dụng đang chạy trên Spark Master
    RUNNING_APPS=$(docker exec $SPARK_MASTER /bin/bash -c 'curl -s http://spark-master:8080/json/' | grep -o '"appId":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$RUNNING_APPS" ]; then
        echo "Không có ứng dụng nào đang chạy trên Spark Master"
    else
        echo "Ứng dụng đang chạy trên Spark Master:"
        echo "$RUNNING_APPS"
    fi
    
    # Kiểm tra các file event logs
    echo -e "\nEvent logs in /opt/spark-events:"
    docker exec $SPARK_MASTER ls -la /opt/spark-events/
    
    # Kiểm tra và hiển thị chi tiết về các file .inprogress
    INPROGRESS_FILES=$(docker exec $SPARK_MASTER bash -c "ls -la /opt/spark-events/*.inprogress 2>/dev/null || echo 'No .inprogress files'")
    if [[ "$INPROGRESS_FILES" != *"No .inprogress files"* ]]; then
        echo -e "\nCác file .inprogress (ứng dụng được coi là đang chạy):"
        echo "$INPROGRESS_FILES"
        echo -e "\nLưu ý: Nếu không có ứng dụng nào đang chạy nhưng vẫn còn file .inprogress,"
        echo "bạn có thể chạy 'make streaming-cleanup' để làm sạch các file này."
    fi
}

# Dừng một ứng dụng Spark cụ thể dựa trên application ID
stop_app() {
    if [ -z "$1" ]; then
        echo "Thiếu application ID. Sử dụng: $0 stop-app <app-id>"
        exit 1
    fi
    
    APP_ID=$1
    echo "Đang dừng ứng dụng Spark với ID: $APP_ID"
    docker exec $SPARK_MASTER spark-submit --master spark://spark-master:7077 --kill $APP_ID
    echo "Đã gửi lệnh kill cho ứng dụng $APP_ID"
    
    echo "Đợi ứng dụng dừng..."
    sleep 3
    
    # Kiểm tra xem có file .inprogress tương ứng không
    APP_LOG=$(docker exec $SPARK_MASTER bash -c "ls -la /opt/spark-events/$APP_ID*.inprogress 2>/dev/null || echo ''")
    if [ ! -z "$APP_LOG" ]; then
        echo "Đang làm sạch file log của ứng dụng..."
        docker exec $SPARK_MASTER bash -c "for f in /opt/spark-events/$APP_ID*.inprogress; do mv \"\$f\" \"\${f%.inprogress}\"; done"
        echo "Khởi động lại History Server..."
        docker restart da-spark-history
        sleep 2
    fi
    
    echo "Trạng thái sau khi dừng:"
    check_status
}

# Main
case "$1" in
    start)
        start_streaming
        ;;
    stop)
        stop_streaming
        ;;
    restart)
        restart_streaming
        ;;
    status)
        check_status
        ;;
    stop-app)
        stop_app "$2"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|stop-app <app-id>}"
        exit 1
esac

exit 0