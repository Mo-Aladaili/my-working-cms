#!/bin/bash
set -e

echo "START-ADMIN SCRIPT IS RUNNING"

mkdir -p /usr/local/etc

cat > /usr/local/etc/cms.toml <<EOF
database = """$DATABASE_URL"""
EOF

echo "CMS TOML CREATED:"
ls -l /usr/local/etc/cms.toml
cat /usr/local/etc/cms.toml | sed 's/:.*@/:PASSWORD@/g'

cmsInitDB || true

cmsLogService &
cmsResourceService &
cmsScoringService &
cmsEvaluationService &
cmsWorker 0 &

cmsAdminWebServer --port ${PORT:-10000}
