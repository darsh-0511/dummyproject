#!/bin/bash

echo "🔧 Setting up Jenkins for Blu-Reserve CI/CD..."

# Install required Jenkins plugins
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="your-jenkins-token"

# List of required plugins
PLUGINS=(
    "git"
    "pipeline-stage-view"
    "workflow-aggregator"
    "docker-workflow"
    "credentials-binding"
    "ssh-agent"
    "junit"
    "slack"
)

# Install plugins
for plugin in "${PLUGINS[@]}"; do
    echo "Installing plugin: $plugin"
    java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_TOKEN} install-plugin $plugin
done

# Restart Jenkins
echo "Restarting Jenkins..."
java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_TOKEN} safe-restart

echo "✅ Jenkins setup completed!"
