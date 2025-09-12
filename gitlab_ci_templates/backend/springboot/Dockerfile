FROM registry.cloudaes.com/base-images/maven:3.6.3-openjdk-17-slim AS builder
WORKDIR /app
ARG BRANCH=''
ARG NEXUS_USER \
    NEXUS_PASS

ENV MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true \
-Dmaven.wagon.http.ssl.allowall=true \
-Dmaven.wagon.http.ssl.ignore.validity.dates=true \
-Dmaven.resolver.transport=wagon"
COPY ./nexus-artifacthub/settings-docker.xml /root/.m2/settings.xml

COPY . .

COPY ./src/main/resources/application-${BRANCH}.properties ./src/main/resources/application.properties

RUN sh -c '\
  if [ ! -f ./.mvn/wrapper/maven-wrapper.properties ]; then \
    echo "Configuring Maven Wrapper..."; \
    mkdir -p ./.mvn/wrapper; \
    curl -sSL -o ./.mvn/wrapper/maven-wrapper.properties https://raw.githubusercontent.com/takari/maven-wrapper/master/.mvn/wrapper/maven-wrapper.properties; \
  else \
    echo "Maven Wrapper already configured"; \
  fi && \
  chmod +x mvnw && \
  ./mvnw dependency:go-offline -s /root/.m2/settings.xml && \
  ./mvnw clean package -DskipTests -s /root/.m2/settings.xml'


FROM openjdk:17-oracle

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

RUN useradd -ms /bin/bash appuser

USER appuser

EXPOSE 9091

ENTRYPOINT ["java", "-jar", "./app.jar"]