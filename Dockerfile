FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential libpq-dev libcap-dev isolate curl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --recursive https://github.com/cms-dev/cms.git /opt/cms

WORKDIR /opt/cms

RUN pip install --no-cache-dir -r requirements.txt && python setup.py install

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 10000

CMD ["/start.sh"]
