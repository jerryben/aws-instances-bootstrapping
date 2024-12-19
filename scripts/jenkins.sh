#!/bin/bash

# Enable strict error handling
set -e

# Define a log file for capturing output
LOG_FILE="/var/log/jenkins_install.log"
exec > >(tee -i $LOG_FILE) 2>&1

echo "Starting Jenkins installation script..."

# Updating and installing required dependencies
echo "Updating package lists and installing Java..."
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-17-jre
echo "Java installation complete. Verifying Java version..."
java -version || { echo "Java installation failed."; exit 1; }

# Install Jenkins
echo "Adding Jenkins repository and GPG key..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
if [ $? -ne 0 ]; then
    echo "Failed to download Jenkins GPG key."
    exit 1
fi

echo "Adding Jenkins repository to the sources list..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Updating package lists and installing Jenkins..."
sudo apt-get update -y
sudo apt-get install -y jenkins || { echo "Jenkins installation failed."; exit 1; }

# Start and enable Jenkins service
echo "Starting and enabling Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins || { echo "Jenkins service failed to start."; exit 1; }

# Installing Cockpit
echo "Installing Cockpit for web-based server management..."
sudo apt-get install -y cockpit || { echo "Cockpit installation failed."; exit 1; }

# Installing Datadog Agent
echo "Installing Datadog Agent..."
DD_API_KEY=${datadog_api_key}
DD_SITE="datadoghq.com"
if [ -z "$DD_API_KEY" ]; then
    echo "Datadog API key is not set. Skipping Datadog installation."
else
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)" || { echo "Datadog Agent installation failed."; exit 1; }
fi

# Final verification
echo "Installation script completed successfully!"
echo "Log file saved to $LOG_FILE."

echo "Installed components:"
java -version
sudo systemctl status jenkins | grep "Active:"
sudo systemctl status cockpit | grep "Active:"

echo "Access Jenkins at http://<your-server-ip>:8080"
echo "Access Cockpit at http://<your-server-ip>:9090"
