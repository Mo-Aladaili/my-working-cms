FROM python:3.10-slim
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git postgresql postgresql-contrib build-essential \
    libpq-dev libcap-dev supervisor curl && \
    rm -rf /var/lib/apt/lists/*

# 2. Download and install CMS officially
RUN git clone --recursive https://github.com /opt/cms
WORKDIR /opt/cms
RUN pip install --no-cache-dir -r requirements.txt && python setup.py install

# 3. Configure local Postgres database out of the box
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER cmsuser WITH PASSWORD 'cmspass';" && \
    psql --command "CREATE DATABASE cmsdb OWNER cmsuser;"

USER root
RUN mkdir -p /usr/local/etc/ && \
    echo '{"database": "postgresql://cmsuser:cmspass@localhost/cmsdb"}' > /usr/local/etc/cms.conf && \
    /etc/init.d/postgresql start && cmsInitDB

# Open port 8888 for Contestants and 8889 for Admin panel
EXPOSE 8888
EXPOSE 8889

# Configure process handlers to run DB and CMS together
RUN echo "[program:postgres]\ncommand=/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf\nuser=postgres\n\n[program:cmsAdmin]\ncommand=cmsAdminWebServer\nautostart=true\nautorestart=true\n\n[program:cmsContest]\ncommand=cmsContestWebServer\nautostart=true\nautorestart=true" > /etc/supervisor/conf.d/cms.conf

CMD ["/usr/bin/supervisord", "-n"]
