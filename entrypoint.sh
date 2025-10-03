#!/bin/bash

SPARK_WORKLOAD=$1

echo "SPARK_WORKLOAD: $SPARK_WORKLOAD"

# Mặc định nếu không được cấu hình
SPARK_WORKER_CORES=${SPARK_WORKER_CORES:-1}
SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY:-1g}
SPARK_WORKER_WEBUI_PORT=${SPARK_WORKER_WEBUI_PORT:-8081}

echo "CORES: $SPARK_WORKER_CORES, MEMORY: $SPARK_WORKER_MEMORY"

if [ "$SPARK_WORKLOAD" == "master" ]; 
then
    start-master.sh -p 7077
elif [ "$SPARK_WORKLOAD" == "worker" ];
then
    # Không truyền tham số webui-port để Spark tự chọn port trống
    # Mặc định Spark sẽ sử dụng 8081, nếu bận sẽ tự tìm port trống tiếp theo
    start-worker.sh \
        --cores $SPARK_WORKER_CORES \
        --memory $SPARK_WORKER_MEMORY \
        spark://spark-master:7077
elif [ "$SPARK_WORKLOAD" == "history" ];
then
    start-history-server.sh
fi