FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG TZ=Europe/Copenhagen
ARG GECKODRIVER_VERSION=0.36.0

ENV TZ=${TZ}
ENV PATH="/opt/firefox:${PATH}"

WORKDIR /app

COPY packages.txt requirements.txt ./

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils tar python3 python3-pip tzdata && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    if [ -s packages.txt ]; then \
      xargs -r apt-get install -y --no-install-recommends < packages.txt; \
    fi && \
    if [ -s requirements.txt ]; then \
      pip3 install --no-cache-dir -r requirements.txt; \
    fi && \
    case "${TARGETARCH}" in \
      amd64) \
        FIREFOX_OS="linux64"; \
        GECKO_ARCH="linux64"; \
        ;; \
      arm64) \
        FIREFOX_OS="linux64-aarch64"; \
        GECKO_ARCH="linux-aarch64"; \
        ;; \
      *) \
        echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; \
        exit 1; \
        ;; \
    esac && \
    curl -L -o /tmp/firefox.tar.xz \
      "https://download.mozilla.org/?product=firefox-latest&os=${FIREFOX_OS}&lang=en-US" && \
    tar -xJf /tmp/firefox.tar.xz -C /opt && \
    ln -sf /opt/firefox/firefox /usr/local/bin/firefox && \
    curl -L -o /tmp/geckodriver.tar.gz \
      "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-${GECKO_ARCH}.tar.gz" && \
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/geckodriver && \
    firefox --version && \
    geckodriver --version && \
    setcap cap_net_raw,cap_net_admin+ep /usr/sbin/dhcpcd && \
    setcap cap_net_raw,cap_net_admin+ep /usr/bin/ip && \
    echo "Cmnd_Alias NETCMDS = /usr/bin/ip, /usr/sbin/dhcpcd, /usr/sbin/pppd" > /etc/sudoers.d/networking && \
    echo "tester ALL=(root) NOPASSWD: NETCMDS" >> /etc/sudoers.d/networking && \
    chown 0:0 /etc/sudoers.d/networking && \
    useradd -m -s /bin/bash tester && \
    usermod -aG sudo tester && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY . .

CMD ["bash"]
