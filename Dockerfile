FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Fix for exit code 100: Wipe lists cache, set timeout options, and bundle update/install cleanly
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update -y -o Acquire::Retries=3 -o Acquire::http::Timeout="60" && \
    apt-get install -y --no-install-recommends \
    git python3 python3-pip python3-setuptools python3-tornado \
    postgresql postgresql-contrib isolate build-essential \
    libpq-dev libcap-dev libcups2-dev libyaml-dev libffi-dev \
    supervisor curl && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --recursive https://github.com /opt/cms
WORKDIR /opt/cms
RUN pip3 install -r requirements.txt && python3 setup.py install

USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER cmsuser WITH PASSWORD 'cmspass';" && \
    psql --command "CREATE DATABASE cmsdb OWNER cmsuser;"

USER root
RUN mkdir -p /usr/local/etc/ && \
    echo '{"database": "postgresql://cmsuser:cmspass@localhost/cmsdb"}' > /usr/local/etc/cms.conf

EXPOSE 8888
EXPOSE 8889

# 1. Download your data file directly into the container during the build process
RUN curl -L "https://file.io" -o /tmp/my_base64_data.txt

# 2. Decode the downloaded data straight into your PostgreSQL database
RUN /etc/init.d/postgresql start && \
    cat /tmp/my_base64_data.txt | base64 -d | gunzip | psql -U cmsuser -h localhost -d cmsdb && \
    cmsInitDB

RUN echo "[program:postgres]\ncommand=/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf\nuser=postgres\n\n[program:cmsAdmin]\ncommand=cmsAdminWebServer\nautostart=true\nautorestart=true\n\n[program:cmsContest]\ncommand=cmsContestWebServer\nautostart=true\nautorestart=true" > /etc/supervisor/conf.d/cms.conf

CMD ["/usr/bin/supervisord", "-n"]
