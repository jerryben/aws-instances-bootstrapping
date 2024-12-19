#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Update and install dependencies
apt-get update && apt-get upgrade -y
apt-get install -y openjdk-11-jdk postgresql wget unzip nano curl cockpit

# Verify Java installation
java --version

# Install and configure PostgreSQL
echo "Installing PostgreSQL..."
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get -y install postgresql
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL
echo "Configuring PostgreSQL..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonarqube12';"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# Download and install SonarQube
echo "Installing SonarQube..."
cd /opt/
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.3.79811.zip
unzip sonarqube-9.9.3.79811.zip
mv sonarqube-9.9.3.79811 sonarqube

# Create sonar user and assign permissions
echo "Setting up SonarQube user and permissions..."
groupadd sonar
useradd -g sonar -d /opt/sonarqube -s /bin/bash sonar
chown -R sonar:sonar /opt/sonarqube

# Configure SonarQube properties
echo "Configuring SonarQube properties..."
sed -i 's/#sonar.jdbc.username=/sonar.jdbc.username=sonar/' /opt/sonarqube/conf/sonar.properties
sed -i 's/#sonar.jdbc.password=/sonar.jdbc.password=sonarqube12/' /opt/sonarqube/conf/sonar.properties

# Set RUN_AS_USER in the sonar script
echo "Configuring SonarQube script..."
sed -i 's/#RUN_AS_USER=/RUN_AS_USER=sonar/' /opt/sonarqube/bin/linux-x86-64/sonar.sh

# Create systemd service file for SonarQube
echo "Creating systemd service for SonarQube..."
cat <<EOF > /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start SonarQube
echo "Starting SonarQube service..."
systemctl daemon-reload
systemctl start sonar
systemctl enable sonar

# Install Datadog Agent
echo "Installing Cockpit and Datadog..."
sudo apt-get install -y cockpit
DD_API_KEY=${datadog_api_key}
DD_SITE="datadoghq.com"
if [ -z "$DD_API_KEY" ]; then
    echo "Datadog API key is not set. Skipping Datadog installation."
else
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)" || { echo "Datadog installation failed."; exit 1; }
fi

# Verify installations
echo "Verifying installations..."
systemctl status sonar
systemctl status postgresql
