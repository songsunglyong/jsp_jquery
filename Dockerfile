FROM maven:3.9.11-eclipse-temurin-21 AS build
# KISA 72313 / ALAS2027-2026-372: Corretto 21.0.13.1.2 (Java 21.0.13.1+2).
ARG TARGETARCH
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) archive_arch=x64; checksum=2aaa2a9a43143b20ff0b28c8d0da27407b97dc40b160d9a2f60a26965815e948 ;; \
      arm64) archive_arch=aarch64; checksum=55751c47c7e3be3b33af43ccdcf3a6f4814d308390b7400477594d421bd16a53 ;; \
      *) echo "Unsupported Java architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl --fail --silent --show-error --location --retry 3 \
      "https://corretto.aws/downloads/resources/21.0.13.1.2/amazon-corretto-21.0.13.1.2-linux-${archive_arch}.tar.gz" \
      --output /tmp/java-security.tar.gz; \
    echo "$checksum  /tmp/java-security.tar.gz" | sha256sum --check -; \
    rm -rf /opt/java/openjdk; \
    mkdir -p /opt/java/openjdk; \
    tar -xzf /tmp/java-security.tar.gz -C /opt/java/openjdk --strip-components=1; \
    rm /tmp/java-security.tar.gz; \
    java -version 2>&1 | grep -F '21.0.13.1'
ENV JAVA_VERSION=21.0.13.1
WORKDIR /build
COPY pom.xml ./
COPY src ./src
RUN mvn -B -ntp clean package

FROM eclipse-temurin:21-jre-jammy
# KISA 72313 / ALAS2027-2026-372: Corretto 21.0.13.1.2 (Java 21.0.13.1+2).
ARG TARGETARCH
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) archive_arch=x64; checksum=2aaa2a9a43143b20ff0b28c8d0da27407b97dc40b160d9a2f60a26965815e948 ;; \
      arm64) archive_arch=aarch64; checksum=55751c47c7e3be3b33af43ccdcf3a6f4814d308390b7400477594d421bd16a53 ;; \
      *) echo "Unsupported Java architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl --fail --silent --show-error --location --retry 3 \
      "https://corretto.aws/downloads/resources/21.0.13.1.2/amazon-corretto-21.0.13.1.2-linux-${archive_arch}.tar.gz" \
      --output /tmp/java-security.tar.gz; \
    echo "$checksum  /tmp/java-security.tar.gz" | sha256sum --check -; \
    rm -rf /opt/java/openjdk; \
    mkdir -p /opt/java/openjdk; \
    tar -xzf /tmp/java-security.tar.gz -C /opt/java/openjdk --strip-components=1; \
    rm /tmp/java-security.tar.gz; \
    java -version 2>&1 | grep -F '21.0.13.1'
ENV JAVA_VERSION=21.0.13.1
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --no-create-home app
WORKDIR /app
COPY --from=build --chown=app:app /build/target/channel-erp.war ./channel-erp.war
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/channel-erp.war"]
