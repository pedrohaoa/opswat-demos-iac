#!/bin/bash
# MetaDefender Core Installation Script for Amazon Linux 2

# Update system
yum update -y

# Install required packages
yum install -y wget curl unzip docker

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/opswat
cd /opt/opswat

# Create docker-compose.yml for MetaDefender Core
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  metadefender-core:
    image: opswat/metadefender:latest
    container_name: metadefender-core
    ports:
      - "8008:8008"
      - "8009:8009"
    environment:
      - MD_LICENSE=${license_key}
      - MD_CONSOLE_LOG_LEVEL=INFO
    volumes:
      - metadefender-data:/app/data
      - metadefender-logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8008/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  metadefender-data:
  metadefender-logs:
EOF

# Set license key if provided
if [ ! -z "${license_key}" ]; then
    sed -i "s/\${license_key}/${license_key}/g" docker-compose.yml
else
    sed -i '/MD_LICENSE/d' docker-compose.yml
fi

# Start MetaDefender Core
docker-compose up -d

# Create systemd service for auto-start
cat > /etc/systemd/system/metadefender.service << 'EOF'
[Unit]
Description=OPSWAT MetaDefender Core
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/opswat
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable metadefender.service

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "OPSWAT/MetaDefender",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/opt/opswat/logs/*.log",
                        "log_group_name": "/aws/ec2/opswat/metadefender",
                        "log_stream_name": "{instance_id}/metadefender.log"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Setup logrotate for application logs
cat > /etc/logrotate.d/metadefender << 'EOF'
/opt/opswat/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

echo "MetaDefender Core installation completed!"