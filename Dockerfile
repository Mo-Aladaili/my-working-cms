FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    gcc \
    g++ \
    make \
    pkg-config \
    asciidoc \
    libpq-dev \
    libcap-dev \
    libffi-dev \
    libyaml-dev \
    libseccomp-dev \
    libsystemd-dev \
    libcups2-dev \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ioi/isolate.git /tmp/isolate \
    && cd /tmp/isolate \
    && make isolate isolate-cg-keeper \
    && install -m 4755 isolate /usr/local/bin/isolate \
    && install -m 0755 isolate-cg-keeper /usr/local/bin/isolate-cg-keeper \
    && mkdir -p /usr/local/etc \
    && rm -rf /tmp/isolate

RUN git clone --recursive https://github.com/cms-dev/cms.git /opt/cms

WORKDIR /opt/cms

RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -c constraints.txt .

COPY start-admin.sh /start-admin.sh
COPY start-contest.sh /start-contest.sh

RUN chmod +x /start-admin.sh /start-contest.sh

EXPOSE 10000

CMD ["/start-contest.sh"]
