#!/bin/bash

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y docker.io nginx logrotate

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Enable and start Nginx service
sudo systemctl enable nginx
sudo systemctl start nginx

# Ensure logrotate is installed
sudo apt-get install -y logrotate
