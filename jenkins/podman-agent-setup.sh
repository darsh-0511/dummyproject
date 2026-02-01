#!/bin/bash

echo "🔧 Setting up Jenkins Agent with Podman..."

# Update system
sudo dnf update -y

# Install Podman
sudo dnf install -y podman podman-compose

# Install Java (required for Jenkins agent)
sudo dnf install -y java-11-openjdk

# Install Git
sudo dnf install -y git

# Install Python and pip
sudo dnf install -y python3 python3-pip

# Install Node.js
sudo dnf install -y nodejs npm

# Configure Podman for rootless
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 jenkins
podman system migrate

# Enable Podman socket
systemctl --user enable --now podman.socket

# Create Jenkins workspace directory
sudo mkdir -p /var/lib/jenkins/workspace
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Configure SSH for deployment
sudo mkdir -p /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chown -R jenkins:jenkins /home/jenkins/.ssh

echo "✅ Jenkins agent setup completed!"
echo "Podman version: $(podman --version)"
echo "Java version: $(java -version 2>&1 | head -n 1)"
