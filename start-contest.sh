#!/bin/bash
set -e

mkdir -p /usr/local/etc

cat > /usr/local/etc/cms.toml <<EOF
database = """$DATABASE_URL"""
EOF

cmsContestWebServer --port ${PORT:-10000}
