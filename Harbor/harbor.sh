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
docker version
# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker
# Configure Docker daemon with recommended settings for Harbor
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
sudo systemctl daemon-reload
sudo systemctl restart docker
# Download and install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose -v
# Download and extract Harbor installer
wget https://storage.googleapis.com/harbor-releases/release-1.8.0/harbor-offline-installer-v1.8.1.tgz
tar xvf harbor-offline-installer-v1.8.1.tgz
cd harbor
# Prompt user for input values
echo "Enter Harbor Admin password:"
read -t 60 admin_password
echo "Enter Harbor Database password:"
read -t 60 db_password
echo "Enter Harbor Data Volume path:"
read -t 60 data_volume
echo "Enter Harbor Hostname:"
read -t 60 hostname
echo "Enter Harbor Port:"
read -t 60 port
# Modify harbor.yml file with user input values
sed -i "s/^hostname:.*/hostname: $hostname/" harbor.yml
sed -i "s/^harbor_admin_password:.*/harbor_admin_password: $admin_password/" harbor.yml
sed -i "s/^data_volume:.*/data_volume: $data_volume/" harbor.yml
sed -i "s/^  password:.*/  password: $db_password/" harbor.yml
sed -i "s/^  port:.*/  port: $port/" harbor.yml
# Install and configure Harbor
sudo ./install.sh
# Check status of Docker Compose services
sudo docker-compose ps
