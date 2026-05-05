# syntax=docker/dockerfile:1.7
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.41.8
ARG ANDROID_SDK_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK_VERSION=28.2.13676358
ARG CMDLINE_TOOLS_VERSION=13114758

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    GRADLE_USER_HOME=/opt/gradle-home \
    PUB_CACHE=/opt/pub-cache \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/36.0.0:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        clang \
        cmake \
        curl \
        file \
        git \
        libglu1-mesa \
        libc6-dev \
        libstdc++6 \
        ninja-build \
        openjdk-17-jdk \
        pkg-config \
        rsync \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools ${GRADLE_USER_HOME} ${PUB_CACHE} \
    && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" -o /tmp/android-cmdline-tools.zip \
    && unzip -q /tmp/android-cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/android-cmdline-tools.zip

RUN yes | sdkmanager --licenses >/dev/null \
    && sdkmanager \
        "cmdline-tools;latest" \
        "platform-tools" \
        "platforms;android-${ANDROID_SDK_PLATFORM}" \
        "build-tools;${ANDROID_BUILD_TOOLS}" \
        "ndk;${ANDROID_NDK_VERSION}"

RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz \
    && mkdir -p /opt \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && flutter config --no-analytics \
    && flutter precache --android \
    && flutter doctor -v

RUN useradd --create-home --shell /bin/bash builder \
    && chown -R builder:builder ${ANDROID_HOME} ${FLUTTER_HOME} ${GRADLE_USER_HOME} ${PUB_CACHE}

USER builder
WORKDIR /workspace

ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["flutter --version"]