#!/bin/bash
set -e

echo "START-CONTEST SCRIPT IS RUNNING"

mkdir -p /usr/local/etc

cat > /usr/local/etc/cms.toml <<EOF
[database]
url = "$DATABASE_URL"
debug = false
twophase_commit = false

[services]
LogService = [["localhost", 29000]]
ResourceService = [["localhost", 28000]]
ScoringService = [["localhost", 28500]]
Checker = [["localhost", 22000]]
EvaluationService = [["localhost", 25000]]
Worker = [["localhost", 26000]]
ContestWebServer = [["localhost", 21000]]
AdminWebServer = [["localhost", 21100]]
ProxyService = [["localhost", 28600]]
PrometheusExporter = []
TelegramBot = []

[global]
temp_dir = "/tmp"
file_log_debug = false
stream_log_detailed = false

[web_server]
secret_key = "8e045a51e4b102ea803c06f92841a1fb"
tornado_debug = false

[contest_web_server]
listen_address = [""]
listen_port = [${PORT:-10000}]
cookie_duration = 10800
num_proxies_used = 1
submit_local_copy = false
tests_local_copy = false
max_submission_length = 100000
max_input_length = 5000000
docs_path = "/usr/share/cms/docs"

[admin_web_server]
listen_address = ""
listen_port = ${PORT:-10000}
cookie_duration = 36000
num_proxies_used = 1

[worker]
keep_sandbox = false

[sandbox]
max_file_size = 1048576
compilation_sandbox_max_processes = 1000
compilation_sandbox_max_time_s = 10.0
compilation_sandbox_max_memory_kib = 524288
trusted_sandbox_max_processes = 1000
trusted_sandbox_max_time_s = 10.0
trusted_sandbox_max_memory_kib = 4194304
EOF

echo "CMS TOML CREATED:"
grep -n "^\[database\]" /usr/local/etc/cms.toml
grep -n "^url" /usr/local/etc/cms.toml | sed 's/:.*@/:PASSWORD@/g'

cmsInitDB || true

cmsLogService &
cmsResourceService &
cmsScoringService &
cmsEvaluationService &
cmsWorker 0 &
cmsProxyService &

sleep 3

while true
do
    echo "Starting contest web server..."
    cmsContestWebServer 0 -c 1 || true
    echo "Contest web server exited. Retrying in 30 seconds..."
    sleep 30
done
