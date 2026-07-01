FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system requirements
RUN apt-get update && apt-get install -y \
    git python3 python3-pip python3-setuptools python3-tornado \
    postgresql postgresql-contrib isolate build-essential \
    libpq-dev libcap-dev libcups2-dev libyaml-dev libffi-dev \
    supervisor && \
    rm -rf /var/lib/apt/lists/*

# 2. Download and install CMS officially
RUN git clone --recursive https://github.com /opt/cms
WORKDIR /opt/cms
RUN pip3 install -r requirements.txt && python3 setup.py install

# 3. Create the database space
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER cmsuser WITH PASSWORD 'cmspass';" && \
    psql --command "CREATE DATABASE cmsdb OWNER cmsuser;"

USER root
RUN mkdir -p /usr/local/etc/ && \
    echo '{"database": "postgresql://cmsuser:cmspass@localhost/cmsdb"}' > /usr/local/etc/cms.conf

# 4. Copy your local database file from your repo into the container
COPY my_contest_data.sql /tmp/my_contest_data.sql

# 5. Inject your existing tasks, users, and submissions directly into the database
RUN /etc/init.d/postgresql start && \
    psql -U cmsuser -h localhost -d cmsdb -f /tmp/my_contest_data.sql && \
    cmsInitDB

EXPOSE 8888
EXPOSE 8889

# 6. Set up background services
RUN echo "[program:postgres]\ncommand=/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf\nuser=postgres\n\n[program:cmsAdmin]\ncommand=cmsAdminWebServer\nautostart=true\nautorestart=true\n\n[program:cmsContest]\ncommand=cmsContestWebServer\nautostart=true\nautorestart=true" > /etc/supervisor/conf.d/cms.conf

CMD ["/usr/bin/supervisord", "-n"]
