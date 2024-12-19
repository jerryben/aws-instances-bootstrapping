#!/bin/bash

# Enable strict error handling
set -e

# Define a log file for capturing output
LOG_FILE="/var/log/tomcat_install.log"
exec > >(tee -i $LOG_FILE) 2>&1

echo "Starting Tomcat installation script..."

# Step 1: Create a user for Tomcat
echo "Creating a dedicated Tomcat user..."
sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat

# Step 2: Update packages and install Java
echo "Updating package lists and installing Java..."
sudo apt-get update -y
sudo apt-get install -y default-jdk
echo "Java installation complete. Verifying Java version..."
java -version || { echo "Java installation failed."; exit 1; }

# Step 3: Download and extract Tomcat
echo "Downloading and extracting Tomcat..."
cd /tmp
TOMCAT_VERSION=10.0.20
wget https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
sudo mkdir -p /opt/tomcat
sudo tar xzvf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1

# Step 4: Set permissions for Tomcat
echo "Setting permissions for Tomcat..."
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

# Step 5: Configure Tomcat users
echo "Configuring Tomcat users..."
sudo tee /opt/tomcat/conf/tomcat-users.xml > /dev/null <<EOF
<role rolename="manager-gui" />
<user username="manager" password="jenkins" roles="manager-gui" />
<role rolename="admin-gui" />
<user username="admin" password="jenkins" roles="manager-gui,admin-gui" />
EOF

# Step 6: Update Manager and Host Manager access restrictions
echo "Removing access restrictions for Manager and Host Manager..."
sudo sed -i '/Valve className="org.apache.catalina.valves.RemoteAddrValve"/s/^<!--/<\!--/' /opt/tomcat/webapps/manager/META-INF/context.xml
sudo sed -i '/Valve className="org.apache.catalina.valves.RemoteAddrValve"/s/^<!--/<\!--/' /opt/tomcat/webapps/host-manager/META-INF/context.xml

# Step 7: Create a systemd service file for Tomcat
echo "Creating systemd service for Tomcat..."
JAVA_HOME_PATH=$(update-java-alternatives -l | awk '{print $3}')
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=${JAVA_HOME_PATH}"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Step 8: Start and enable Tomcat service
echo "Starting and enabling Tomcat service..."
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo systemctl status tomcat || { echo "Tomcat service failed to start."; exit 1; }

# Step 9: Allow Tomcat port through UFW
echo "Allowing Tomcat port (8080) through UFW..."
sudo ufw allow 8080

# Step 10: Install Datadog and Cockpit
echo "Installing Cockpit and Datadog..."
sudo apt-get install -y cockpit
DD_API_KEY=${datadog_api_key}
DD_SITE="datadoghq.com"
if [ -z "$DD_API_KEY" ]; then
    echo "Datadog API key is not set. Skipping Datadog installation."
else
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)" || { echo "Datadog installation failed."; exit 1; }
fi

# Final verification
echo "Tomcat installation completed successfully!"
echo "Log file saved to $LOG_FILE."

echo "Installed components:"
java -version
sudo systemctl status tomcat | grep "Active:"
sudo ufw status

echo "Access Tomcat Manager at http://<your-server-ip>:8080/manager"
echo "Access Cockpit at http://<your-server-ip>:9090"
