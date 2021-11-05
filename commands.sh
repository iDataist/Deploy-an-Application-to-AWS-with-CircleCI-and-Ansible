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

aws s3 rm s3://udapeople-aldkgke --recursive

# create an EC2 instance with 22, 9090, 9093, 9100 inbound port open
aws ec2 run-instances \
--image-id ami-083654bd07b5da81d \
--count 1 \
--instance-type t2.micro \
--key-name ec2 \
--security-group-ids sg-0ec08075ac9543720
--tag-specifications 'ResourceType=instance,Tags=[{Key=monitoring,Value=prometheum-host}]'

# terminate ec2 instance
aws ec2 terminate-instances --instance-ids  i-05c15d9b474bc3acc

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
