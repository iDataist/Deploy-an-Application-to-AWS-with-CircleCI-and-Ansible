aws cloudformation deploy \
         --template-file cloudfront.yml \
         --stack-name udapeople-cloudfront--aldkgke\
         --parameter-overrides WorkflowID=udapeople-aldkgke

curl http://3.89.219.6:3030/api/status

aws cloudformation deploy \
--template-file frontend.yml \
--stack-name udapeople-frontend-aldkgke \
--parameter-overrides ID=aldkgke \
--region us-east-1 \
--tags project=udapeople-frontend-aldkgke

aws s3 rm s3://udapeople-qwertyu --recursive

# create an EC2 instance with 22, 9090, 9093, 9100 inbound port open
aws ec2 run-instances \
--image-id ami-0279c3b3186e54acd \
--count 1 \
--instance-type t2.micro \
--key-name ec2 \
--security-group-ids sg-0ec08075ac9543720 \
--tag-specifications 'ResourceType=instance,Tags=[{Key=monitoring,Value=prometheum-host}]'

# terminate ec2 instance
aws ec2 terminate-instances --instance-ids i-0296bf3d6a0e1ad84

# ssh into EC2 instance
chmod 400 ec2.pem
ssh -i "ec2.pem" ubuntu@ec2-54-165-172-173.compute-1.amazonaws.com

# create a different user than root to run specific services
sudo useradd --no-create-home prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.19.0/prometheus-2.19.0.linux-amd64.tar.gz
tar xvfz prometheus-2.19.0.linux-amd64.tar.gz

sudo cp prometheus-2.19.0.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-2.19.0.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.19.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.19.0.linux-amd64/console_libraries /etc/prometheus

sudo cp prometheus-2.19.0.linux-amd64/promtool /usr/local/bin/
rm -rf prometheus-2.19.0.linux-amd64.tar.gz prometheus-2.19.0.linux-amd64

# configure Prometheus to monitor itself
sudo vim /etc/prometheus/prometheus.yml
# paste the following content
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
# exit
:wq

# allow Prometheus to be available as a service
sudo vim /etc/systemd/system/prometheus.service
# paste the following content
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
# exit
:wq

# change the permissions of the directories, files and binaries
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

# configure systemd
sudo systemctl daemon-reload
sudo systemctl enable prometheus

service prometheus status
sudo service prometheus restart

# install Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz
tar xvfz alertmanager-0.21.0.linux-amd64.tar.gz

sudo cp alertmanager-0.21.0.linux-amd64/alertmanager /usr/local/bin
sudo cp alertmanager-0.21.0.linux-amd64/amtool /usr/local/bin/
sudo mkdir /var/lib/alertmanager

rm -rf alertmanager*

# Add Alertmanager’s configuration
sudo vim /etc/prometheus/alertmanager.yml
# paste the following content
route:
  group_by: [Alertname]
  receiver: email-me

receivers:
- name: email-me
  email_configs:
  - to: EMAIL_YO_WANT_TO_SEND_EMAILS_TO
    from: YOUR_EMAIL_ADDRESS
    smarthost: smtp.gmail.com:587
    auth_username: YOUR_EMAIL_ADDRESS
    auth_identity: YOUR_EMAIL_ADDRESS
    auth_password: YOUR_EMAIL_PASSWORD
# exit
:wq

# Configure Alertmanager as a service
sudo vim /etc/systemd/system/alertmanager.service
# paste the following content
[Unit]
Description=Alert Manager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/prometheus/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

Restart=always

[Install]
WantedBy=multi-user.target
# exit
:wq

# create a rule
sudo vim /etc/prometheus/rules.yml
# paste the following content
groups:
- name: Down
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 3m
    labels:
      severity: 'critical'
    annotations:
      summary: "Instance  is down"
      description: " of job  has been down for more than 3 minutes."
# exit
:wq

# Configure Prometheus
sudo chown -R prometheus:prometheus /etc/prometheus

# Update Prometheus configuration file
sudo vim /etc/prometheus/prometheus.yml
#delete all lines
:1,$d
# paste the following content
global:
  scrape_interval: 1s
  evaluation_interval: 1s

rule_files:
 - /etc/prometheus/rules.yml

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

scrape_configs:
  - job_name: 'node'
    ec2_sd_configs:
      - region: us-east-1
        access_key: ASIA3VWHZ2J4MBAUIFC7
        secret_key: I7YS7sOKVvXxkGvunyOmLEHEmxQAkprfFr5KdF+a
        port: 9100
# exit
:wq

# Reload Systemd
sudo systemctl restart prometheus


service prometheus status
sudo service prometheus restart
service alertmanager status
sudo service alertmanager restart

-----------------------------------------
sudo useradd --no-create-home --shell /bin/false alertmanager

wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz
tar xvfz alertmanager-0.21.0.linux-amd64.tar.gz

sudo cp alertmanager-0.21.0.linux-amd64/alertmanager /usr/local/bin
sudo cp alertmanager-0.21.0.linux-amd64/amtool /usr/local/bin/
sudo mkdir /var/lib/alertmanager

rm -rf alertmanager*