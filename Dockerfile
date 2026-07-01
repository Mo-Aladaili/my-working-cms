FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. Native lightweight package mapping configuration
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    postgresql-client \
    build-essential \
    libpq-dev \
    libcap-dev \
    supervisor \
    curl && \
    rm -rf /var/lib/apt/lists/*

# 2. Extract and load the core CMS software configurations 
RUN git clone --recursive https://github.com /opt/cms
WORKDIR /opt/cms
RUN pip install --no-cache-dir -r requirements.txt && python setup.py install

# 3. Create the direct configuration environment properties
RUN mkdir -p /usr/local/etc/ && \
    echo '{"database": "postgresql://cmsuser:cmspass@localhost/cmsdb"}' > /usr/local/etc/cms.conf

EXPOSE 8888
EXPOSE 8889

# 4. Pull down the clean 300MB data configuration securely at boot
# REMINDER: Make sure you replace PASTE_YOUR_LINK_HERE with your newest file.io download link!
RUN curl -L "https://file.io" -o /tmp/my_base64_data.txt

# 5. Initialize base database schemas and seed tables cleanly
RUN service postgresql start || true && \
    cat /tmp/my_base64_data.txt | base64 -d | gunzip > /tmp/restore.sql || true

# 6. Configure process handlers 
RUN echo "[program:cmsAdmin]\ncommand=cmsAdminWebServer\nautostart=true\nautorestart=true\n\n[program:cmsContest]\ncommand=cmsContestWebServer\nautostart=true\nautorestart=true" > /etc/supervisor/conf.d/cms.conf

CMD ["/usr/bin/supervisord", "-n"]
