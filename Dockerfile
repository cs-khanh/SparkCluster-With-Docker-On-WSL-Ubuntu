FROM python:3.11-bullseye

ARG SPARK_VERSION=3.4.0

RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        sudo \
        curl \
        vim \
        unzip \
        rsync \
        openjdk-11-jdk \
        build-essential \
        software-properties-common \
        ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"} 

ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}

RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}

WORKDIR ${SPARK_HOME}

# Sao chép file Spark từ máy local vào container
# COPY ./lib-spark/spark-3.4.0-bin-hadoop3.tgz /tmp/

# Giải nén Spark vào /opt/spark
# RUN tar -xvzf /tmp/spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 && \
#     rm -f /tmp/spark-${SPARK_VERSION}-bin-hadoop3.tgz
RUN curl -L https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

COPY requirements.txt .

RUN pip3 install -r requirements.txt

ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_HOME="/opt/spark"
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV PYSPARK_PYTHON python3

COPY conf/spark-defaults.conf "${SPARK_HOME}/conf"
COPY conf/log4j.properties "${SPARK_HOME}/conf"
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

COPY entrypoint.sh .

ENTRYPOINT ["./entrypoint.sh"]

