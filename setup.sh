#!/bin/bash
set -exu;

# USAGE
# This script expects that the domains to be watched are passed in as command line arguments.
# EXAMPLE: ./setup.sh example.com sub.example.com;

# REQUIRED ENVIRONMENT VARIABLES (prefixed with PBE - prometheus blackbox experiment)
# PBE_EMAIL_TO
# PBE_EMAIL_FROM
# PBE_EMAIL_PASSWORD

function createPrometheusConfig()
{
cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s

rule_files:
  - /config/prometheus.rules.yml

scrape_configs:
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [ http_2xx ]
    static_configs:
      - targets:
EOF

while (($#)); do
cat <<EOF >> prometheus.yml
        - $1
EOF
shift
done

cat <<EOF >> prometheus.yml
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: pbe_blackbox:9115 # Blackbox Exporter's address

alerting:
  alertmanagers:
    - static_configs:
      - targets:
        - pbe_alertmanager:9093
EOF
}

function createAlertManagerConfig()
{
cat <<EOF > alertmanager.yml
global:
  smtp_from: $PBE_EMAIL_FROM
  smtp_smarthost: smtp.gmail.com:587
  smtp_auth_username: $PBE_EMAIL_FROM
  smtp_auth_identity: $PBE_EMAIL_FROM
  smtp_auth_password: "$PBE_EMAIL_PASSWORD"

route:
  receiver: email-it
  
receivers:
  - name: email-it
    email_configs:
    - to: $PBE_EMAIL_TO
      send_resolved: true
EOF
}

function setupDocker()
{
  docker network create pbe_monitoring;

  docker run -d \
    -p 9090:9090 \
    -v $(pwd)/prometheus.yml:/config/prometheus.yml:ro \
    -v $(pwd)/prometheus.rules.yml:/config/prometheus.rules.yml:ro \
    --restart always \
    --name pbe_prometheus \
    --network pbe_monitoring \
    prom/prometheus:v2.15.0 \
    --config.file=/config/prometheus.yml;

  docker run -d \
    -p 9115:9115 \
    -v $(pwd)/blackbox.yml:/config/blackbox.yml:ro \
    --restart always \
    --name pbe_blackbox \
    --network pbe_monitoring \
    prom/blackbox-exporter:v0.16.0 \
    --config.file=/config/blackbox.yml;

  docker run -d \
    -p 9093:9093 \
    -v $(pwd)/alertmanager.yml:/config/alertmanager.yml:ro \
    --restart always \
    --name pbe_alertmanager \
    --network pbe_monitoring \
    prom/alertmanager:v0.20.0 \
    --config.file=/config/alertmanager.yml;
}

createPrometheusConfig $@;
createAlertManagerConfig;
setupDocker;
