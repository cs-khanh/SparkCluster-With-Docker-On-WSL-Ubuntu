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

# Build the Docker images
build:
	$(COMPOSE) build
build-nc:
	$(COMPOSE) build --no-cache

build-progress:
	$(COMPOSE) build --no-cache --progress=plain

down:
	$(COMPOSE) down --volumes

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
	docker exec $(SPARK_MASTER) spark-submit --master spark://spark-master:7077 --deploy-mode client ./apps/${app}