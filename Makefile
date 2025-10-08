# Variables
PROJECT_NAME=sparkcluster
COMPOSE=docker compose
SPARK_MASTER=da-spark-master
SPARK_WORKER=da-spark-worker
SPARK_HISTORY=da-spark-history

# Default target
help:
	@echo "Available commands:"
	@echo "  make build       - Build Docker images"
	@echo "  make start       - Start Spark cluster (in detached mode)"
	@echo "  make start-fg    - Start Spark cluster (in foreground)"
	@echo "  make stop        - Stop Spark cluster"
	@echo "  make restart     - Restart Spark cluster"
	@echo "  make clean       - Clean up containers, volumes and networks"
	@echo "  make logs        - Display logs from all containers"
	@echo "  make logs-master - Display logs from master node"
	@echo "  make logs-worker - Display logs from worker node"
	@echo "  make logs-history - Display logs from history server"
	@echo "  make shell-master - Open a shell in the master container"
	@echo "  make shell-worker - Open a shell in the worker container"
	@echo "  make shell-history - Open a shell in the history server container"
	@echo "  make status      - Show status of containers"
	@echo "  make ui          - Open Spark Master UI in browser (requires xdg-open)"
	@echo "  make history-ui   - Open Spark History Server UI in browser (requires xdg-open)"
	@echo "  make worker-ports - Hiển thị danh sách cổng của các Worker WebUI"
	@echo "  make run         - Start Spark cluster (foreground)"
	@echo "  make run-d       - Start Spark cluster (detached/background)"
	@echo "  make run-scaled  - Start Spark cluster with 3 workers (foreground, down trước)"
	@echo "  make run-workers WORKERS=<số lượng> - Start Spark cluster với số worker tùy chọn (down trước)"
	@echo "  make run-workers-d WORKERS=<số lượng> - Start Spark cluster với số worker tùy chọn (detached, down trước)"
	@echo "  make scale-workers WORKERS=<số lượng> - Scale worker lên số lượng chỉ định (không down trước)"
	@echo "  make run-config WORKERS=<số lượng> CORES=<số cores> MEMORY=<bộ nhớ> - Start cluster với số worker và cấu hình chỉ định"
	@echo "  make run-config-d WORKERS=<số lượng> CORES=<số cores> MEMORY=<bộ nhớ> - Start cluster (detached) với cấu hình"
	@echo ""
	@echo "Kafka Streaming commands:"
	@echo "  make create-kafka-topic - Create Kafka topic for streaming"
	@echo "  make submit-streaming   - Submit basic streaming application (local mode)"
	@echo "  make submit-streaming-cluster - Submit advanced streaming application (cluster mode)"
	@echo "  make start-producer     - Start Kafka producer to generate test data"
	@echo "  make streaming-start    - Start streaming application with proper management"
	@echo "  make streaming-stop     - Stop all running streaming applications properly"
	@echo "  make streaming-stop-app app=<app-id> - Stop a specific Spark application by ID"
	@echo "  make streaming-restart  - Restart streaming applications"
	@echo "  make streaming-status   - Check status of streaming applications"
	@echo "  make streaming-cleanup  - Clean up stuck .inprogress files and restart History Server"
	@echo "  make kafka-console-consumer - Monitor Kafka messages"
	@echo "  make kafka-list-topics  - List all Kafka topics"
	@echo "  make check-streaming-data - Check streaming output files in kafka-data"
	@echo "  make clean-streaming-data - Clean all streaming output data"

# Build the Docker images
build:
	$(COMPOSE) build
build-nc:
	$(COMPOSE) build --no-cache

build-progress:
	$(COMPOSE) build --no-cache --progress=plain

down:
	$(COMPOSE) down --volumes
	
force-down:
	$(COMPOSE) down --volumes
	docker rm -f $$(docker ps -a -q --filter "name=sparkcluster" --filter "name=da-spark") 2>/dev/null || true

run:
	make down && $(COMPOSE) up

run-scaled:
	make down && $(COMPOSE) up --scale spark-worker=3

# Chạy với số worker tùy chọn (sử dụng: make run-workers WORKERS=5)
run-workers:
	@if [ -z "$(WORKERS)" ]; then \
		echo "Sử dụng: make run-workers WORKERS=<số lượng>"; \
	else \
		make down && $(COMPOSE) up --scale spark-worker=$(WORKERS); \
	fi
		
# Chạy với số worker tùy chọn không down trước (sử dụng: make scale-workers WORKERS=5)
scale-workers:
	@if [ -z "$(WORKERS)" ]; then \
		echo "Sử dụng: make scale-workers WORKERS=<số lượng>"; \
	else \
		$(COMPOSE) up --scale spark-worker=$(WORKERS); \
	fi

# Chạy với số worker tùy chọn ở chế độ detached (sử dụng: make run-workers-d WORKERS=5)
run-workers-d:
	@if [ -z "$(WORKERS)" ]; then \
		echo "Sử dụng: make run-workers-d WORKERS=<số lượng>"; \
	else \
		make down && $(COMPOSE) up -d --scale spark-worker=$(WORKERS); \
	fi

# Khởi động cluster với cấu hình core và memory tùy chỉnh
# Sử dụng: make run-config WORKERS=3 CORES=2 MEMORY=2g
run-config:
	@if [ -z "$(WORKERS)" ] || [ -z "$(CORES)" ] || [ -z "$(MEMORY)" ]; then \
		echo "Sử dụng: make run-config WORKERS=<số lượng> CORES=<số cores> MEMORY=<bộ nhớ, ví dụ: 2g>"; \
	else \
		make down && SPARK_WORKER_CORES=$(CORES) SPARK_WORKER_MEMORY=$(MEMORY) $(COMPOSE) up --scale spark-worker=$(WORKERS); \
	fi

# Khởi động cluster với cấu hình core và memory tùy chỉnh ở chế độ detached
# Sử dụng: make run-config-d WORKERS=3 CORES=2 MEMORY=2g
run-config-d:
	@if [ -z "$(WORKERS)" ] || [ -z "$(CORES)" ] || [ -z "$(MEMORY)" ]; then \
		echo "Sử dụng: make run-config-d WORKERS=<số lượng> CORES=<số cores> MEMORY=<bộ nhớ, ví dụ: 2g>"; \
	else \
		make down && SPARK_WORKER_CORES=$(CORES) SPARK_WORKER_MEMORY=$(MEMORY) $(COMPOSE) up -d --scale spark-worker=$(WORKERS); \
	fi

run-d:
	make down && $(COMPOSE) up -d

stop:
	$(COMPOSE) stop

# Display logs from history server
logs-history:
	$(COMPOSE) logs --tail=100 -f spark-history-server

# Open a shell in the history server container
shell-history:
	docker exec -it $(SPARK_HISTORY) /bin/bash

# Open Spark History Server UI in browser (Linux only)
history-ui:
	xdg-open http://localhost:18080 || echo "Could not open browser. Please visit http://localhost:18080 manually."

# Open Spark Master UI in browser (Linux only)
ui:
	xdg-open http://localhost:8080 || echo "Could not open browser. Please visit http://localhost:8080 manually."

# Display logs for all containers
logs:
	$(COMPOSE) logs --tail=100 -f

# Display logs for master
logs-master:
	$(COMPOSE) logs --tail=100 -f $(SPARK_MASTER)

# Display logs for a specific worker by ID (sử dụng: make logs-worker-id ID=1)
logs-worker-id:
	@if [ -z "$(ID)" ]; then \
		echo "Sử dụng: make logs-worker-id ID=<container_id>"; \
	else \
		$(COMPOSE) logs --tail=100 -f sparkcluster-spark-worker-$(ID); \
	fi

# Display logs for all workers
logs-worker:
	$(COMPOSE) logs --tail=100 -f spark-worker

# Open shell in master container
shell-master:
	docker exec -it $(SPARK_MASTER) /bin/bash

# Open shell in a specific worker by ID (sử dụng: make shell-worker-id ID=1)
shell-worker-id:
	@if [ -z "$(ID)" ]; then \
		echo "Sử dụng: make shell-worker-id ID=<container_id>"; \
	else \
		docker exec -it sparkcluster-spark-worker-$(ID) /bin/bash; \
	fi

# Open shell in the first worker (legacy support for backwards compatibility)
shell-worker:
	@WORKER_CONTAINER=$$(docker ps --filter "name=spark-worker" --format "{{.Names}}" | head -n 1); \
	if [ -z "$$WORKER_CONTAINER" ]; then \
		echo "Không tìm thấy worker container nào đang chạy"; \
	else \
		echo "Đang mở shell trong container $$WORKER_CONTAINER"; \
		docker exec -it $$WORKER_CONTAINER /bin/bash; \
	fi

status:
	$(COMPOSE) ps

# Hiển thị danh sách cổng của Worker WebUI
worker-ports:
	@echo "Danh sách cổng WebUI của các Worker:"
	@docker ps --filter "name=spark-worker" --format "table {{.Names}}\t{{.Ports}}" | grep -v "^CONTAINER"

submit:
	@if [ -z "$(app)" ]; then \
		echo "Sử dụng: make submit app=<tên_file_ứng_dụng>, ví dụ: make submit app=example.py"; \
	else \
		docker exec $(SPARK_MASTER) spark-submit --master spark://spark-master:7077 --deploy-mode client /opt/spark/apps/$(app); \
	fi

# Kafka streaming commands
create-kafka-topic:
	./create_kafka_topic.sh

start-producer:
	docker exec -it $(SPARK_MASTER) python3 ./apps/kafka_producer.py

# Quản lý streaming jobs
streaming-start:
	./streaming_manager.sh start

streaming-stop:
	./streaming_manager.sh stop

streaming-restart:
	./streaming_manager.sh restart

streaming-status:
	./streaming_manager.sh status

# Dừng một ứng dụng Spark cụ thể dựa trên application ID
streaming-stop-app:
	@if [ -z "$(app)" ]; then \
		echo "Sử dụng: make streaming-stop-app app=<application-id>, ví dụ: make streaming-stop-app app=app-20251008045016-0001"; \
	else \
		./streaming_manager.sh stop-app $(app); \
	fi
	
# Dọn dẹp các file inprogress và khởi động lại History Server
streaming-cleanup:
	@echo "Cleaning up stuck .inprogress files and restarting History Server..."
	@docker exec $(SPARK_MASTER) bash -c 'for f in /opt/spark-events/*.inprogress; do mv "$$f" "$${f%.inprogress}" 2>/dev/null; done || true'
	@docker restart $(SPARK_HISTORY)
	@echo "Waiting for History Server to restart..."
	@sleep 3
	@echo "Done! Please refresh your History Server UI."

submit-streaming:
	@if [ -z "$(app)" ]; then \
		echo "Sử dụng: make submit-streaming app=<tên_file_ứng_dụng>, ví dụ: make submit-streaming app=test_streaming_cluster.py"; \
	else \
		docker exec $(SPARK_MASTER) spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0 --master spark://spark-master:7077 --deploy-mode client /opt/spark/apps/$(app); \
	fi

# Kafka utilities
kafka-console-consumer:
	docker exec -it $(shell docker ps -qf "name=sparkcluster-kafka") /usr/bin/kafka-console-consumer \
		--topic sales-events \
		--bootstrap-server localhost:9092 \
		--from-beginning

kafka-list-topics:
	docker exec -it $(shell docker ps -qf "name=sparkcluster-kafka") /usr/bin/kafka-topics \
		--list --bootstrap-server localhost:9092

# Check streaming output data
check-streaming-data:
	@echo "=== Raw streaming data ==="
	@ls -la ./kafka-data/streaming-output/ 2>/dev/null || echo "No raw data yet"
	@echo ""
	@echo "=== Windowed analytics data ==="  
	@ls -la ./kafka-data/windowed-analytics/ 2>/dev/null || echo "No analytics data yet"
	@echo ""
	@echo "=== Checkpoints ==="
	@ls -la ./kafka-data/checkpoints/ 2>/dev/null || echo "No checkpoints yet"

clean-streaming-data:
	@echo "Cleaning streaming output data..."
	@rm -rf ./kafka-data/streaming-output/ ./kafka-data/windowed-analytics/ ./kafka-data/checkpoints/
	@echo "Done!"

# Lệnh để kiểm tra cấu hình Java và hệ thống trước khi chạy
check-env:
	@echo "Checking Java and system configuration on master..."
	docker exec $(SPARK_MASTER) /bin/bash -c "java -XX:+PrintFlagsFinal -version | grep -E 'MaxHeapSize|InitialHeapSize'"
	docker exec $(SPARK_MASTER) /bin/bash -c "free -h && df -h && ulimit -a"
	@echo "\nChecking Java and system configuration on worker 1..."
	docker exec sparkcluster-spark-worker-1 /bin/bash -c "java -XX:+PrintFlagsFinal -version | grep -E 'MaxHeapSize|InitialHeapSize'"
	docker exec sparkcluster-spark-worker-1 /bin/bash -c "free -h && df -h && ulimit -a"
