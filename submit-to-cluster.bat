# Batch file cho máy Windows để submit job vào Spark cluster và lưu history log
# Lưu file này với tên submit-to-cluster.bat trên máy Windows của bạn

@echo off
set SPARK_MASTER=spark://10.10.11.71:7077
set SPARK_HOME=C:\path\to\your\spark

echo Submitting job to Spark cluster at %SPARK_MASTER%
echo Application: %1
echo Input file: %2
echo Output directory: %3

REM Đảm bảo đường dẫn file trong cluster là chính xác
set CLUSTER_INPUT=/opt/spark/data/%~nx2
set CLUSTER_OUTPUT=/opt/spark/data/output/%~n3

REM Submit spark job
"%SPARK_HOME%\bin\spark-submit" ^
  --master %SPARK_MASTER% ^
  --deploy-mode client ^
  --conf spark.eventLog.enabled=true ^
  --conf spark.eventLog.dir=file:/opt/spark-events ^
  --conf spark.driver.host=<IP-của-máy-Windows> ^
  --conf spark.submit.deployMode=client ^
  --conf spark.driver.bindAddress=0.0.0.0 ^
  --conf spark.blockManager.port=38000 ^
  --conf spark.driver.port=38001 ^
  --conf spark.fileserver.port=38002 ^
  --conf spark.broadcast.port=38003 ^
  --conf spark.replClassServer.port=38004 ^
  %1 %CLUSTER_INPUT% %CLUSTER_OUTPUT%

echo Job submitted!
echo Check history server at http://10.10.11.71:18080