FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    jq \
    httpie \
    poppler-utils \
    less \
    fzf \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/share/doc/* /usr/share/man/*

WORKDIR /app

COPY grepstein.sh /usr/local/bin/grepstein
RUN chmod +x /usr/local/bin/grepstein

ENTRYPOINT ["grepstein"]
