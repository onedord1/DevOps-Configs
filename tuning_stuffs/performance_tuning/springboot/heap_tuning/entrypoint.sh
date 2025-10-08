#!/bin/bash
exec java \
    -XX:+UseContainerSupport \
    -XX:+UseZGC \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+UseTransparentHugePages \
    -XX:ZAllocationSpikeTolerance=5 \
    -XX:+ZProactive \
    -XX:ZUncommitDelay=30 \
    -XX:ZCollectionInterval=5 \
    -Xms100m \
    -Xmx800m \
    -XX:MinHeapFreeRatio=5 \
    -XX:MaxHeapFreeRatio=10 \
    -XX:MaxMetaspaceSize=350m \
    -XX:MaxDirectMemorySize=64m \
    -Xlog:gc*,gc+heap=info \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=/tmp/heapdump.hprof \
    -javaagent:/opt/opentelemetry-javaagent.jar \
    -Dotel.traces.exporter=otlp \
    -Dotel.metrics.exporter=otlp \
    -Dotel.logs.exporter=otlp \
    -Dotel.exporter.otlp.endpoint=http://localhost:9317 \
    -Dotel.exporter.otlp.protocol=grpc \
    -Dotel.exporter.otlp.headers=Authorization=Basic%20$(echo -n ${SIGNOZ_USERNAME}:${SIGNOZ_PASSWORD} | base64 -w 0) \
    -Dotel.sampler.probability=0.5 \
    -Dotel.resource.attributes=service.name=${SERVICE_NAME:-qa-bmdsalesbe},deployment.environment=${DEPLOYMENT_ENV:-qa} \
    -Dotel.instrumentation.jdbc-datasource.enabled=true \
    -Dotel.instrumentation.hikaricp.enabled=true \
    -Dotel.instrumentation.spring-data.enabled=true \
    -Dotel.instrumentation.jdbc-statement-sanitizer.enabled=true \
    -Dotel.instrumentation.logback-appender.enabled=true \
    -Dotel.instrumentation.jdbc.experimental-span-attributes=true \
    -Dotel.instrumentation.spring-jdbc.enabled=true \
    -jar app.jar





























# #!/bin/bash
# exec java \
#     -XX:+UseContainerSupport \
#     -XX:+UseZGC \
#     -XX:+UnlockExperimentalVMOptions \
#     -XX:+UseTransparentHugePages \
#     -XX:ZAllocationSpikeTolerance=5 \
#     -XX:+ZProactive \
#     -XX:ZUncommitDelay=60 \
#     -XX:ZCollectionInterval=5 \
#     -XX:MaxRAMPercentage=60.0 \
#     -XX:InitialRAMPercentage=5.0 \
#     -XX:MinHeapFreeRatio=5 \
#     -XX:MaxHeapFreeRatio=10 \
#     -XX:MaxMetaspaceSize=192m \
#     -XX:MaxDirectMemorySize=32m \
#     -Xlog:gc*,gc+heap=info \
#     -XX:+HeapDumpOnOutOfMemoryError \
#     -XX:HeapDumpPath=/tmp/heapdump.hprof \
#     -javaagent:/opt/opentelemetry-javaagent.jar \
#     -Dotel.traces.exporter=otlp \
#     -Dotel.metrics.exporter=otlp \
#     -Dotel.logs.exporter=otlp \
#     -Dotel.exporter.otlp.endpoint=http://localhost:9317 \
#     -Dotel.exporter.otlp.protocol=grpc \
#     -Dotel.exporter.otlp.headers=Authorization=Basic%20$(echo -n ${SIGNOZ_USERNAME}:${SIGNOZ_PASSWORD} | base64 -w 0) \
#     -Dotel.sampler.probability=1.0 \
#     -Dotel.resource.attributes=service.name=${SERVICE_NAME:-qa-bmdsalesbe},deployment.environment=${DEPLOYMENT_ENV:-qa} \
#     -Dotel.instrumentation.jdbc-datasource.enabled=true \
#     -Dotel.instrumentation.hikaricp.enabled=true \
#     -Dotel.instrumentation.spring-data.enabled=true \
#     -Dotel.instrumentation.jdbc-statement-sanitizer.enabled=true \
#     -Dotel.instrumentation.logback-appender.enabled=true \
#     -Dotel.instrumentation.jdbc.experimental-span-attributes=true \
#     -Dotel.instrumentation.spring-jdbc.enabled=true \
#     -jar app.jar