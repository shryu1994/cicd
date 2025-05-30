#!/bin/bash
# Install required packages for containerd and Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https
# Add Docker GPG key to apt keyring
sudo mkdir -p /etc/apt/keyrings
sudo chmod 755 /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Add Docker repository to sources.list
sudo echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt-get install -y docker-ce docker-ce-cli

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Set Docker daemon options
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Reload daemon and restart Docker service
sudo systemctl daemon-reload
sudo systemctl restart docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose -v

# Install GitLab
apt-get install -y curl openssh-server ca-certificates
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo apt-get -y install gitlab-ce

# Update GitLab URL
echo "Enter GitLab URL:"
read -t 60 url
sudo sed -i "s/^external_url.*/external_url 'http:\/\/$url'/" /etc/gitlab/gitlab.rb

# Reconfigure GitLab and print initial root password
sudo gitlab-ctl reconfigure
sudo cat /etc/gitlab/initial_root_password

