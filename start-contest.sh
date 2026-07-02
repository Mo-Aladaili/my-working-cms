#!/bin/bash
set -e

echo "START-CONTEST SCRIPT IS RUNNING"

mkdir -p /usr/local/etc

cat > /usr/local/etc/cms.toml <<EOF
database = """$DATABASE_URL"""
EOF

echo "CMS TOML CREATED:"
ls -l /usr/local/etc/cms.toml
cat /usr/local/etc/cms.toml | sed 's/:.*@/:PASSWORD@/g'

cmsContestWebServer --port ${PORT:-10000}
