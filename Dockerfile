FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git python3 python3-pip python3-setuptools python3-tornado \
    postgresql postgresql-contrib isolate build-essential \
    libpq-dev libcap-dev libcups2-dev libyaml-dev libffi-dev \
    supervisor && \
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

RUN echo "[program:postgres]\ncommand=/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf\nuser=postgres\n\n[program:cmsAdmin]\ncommand=cmsAdminWebServer\nautostart=true\n24/7=true\n\n[program:cmsContest]\ncommand=cmsContestWebServer\nautostart=true\nautorestart=true" > /etc/supervisor/conf.d/cms.conf

# This entry script decodes and restores your data on-the-fly at boot setup
CMD /etc/init.d/postgresql start && \
    if [ ! -z "$CONTEST_DATA" ]; then \
        echo "$CONTEST_DATA" | base64 -d | gunzip | psql -U cmsuser -h localhost -d cmsdb; \
        cmsInitDB; \
    fi && \
    /usr/bin/supervisord -n
