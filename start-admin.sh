#!/bin/bash
set -e

mkdir -p /usr/local/etc

cat > /usr/local/etc/cms.toml <<EOF
database = """$DATABASE_URL"""
EOF

cmsInitDB || true

cmsLogService &
cmsResourceService &
cmsScoringService &
cmsEvaluationService &
cmsWorker 0 &

cmsAdminWebServer --port ${PORT:-10000}
