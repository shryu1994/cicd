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
# Update apt and install containerd.io
sudo apt update
sudo apt install -y containerd.io
# Enable and start containerd
sudo systemctl enable containerd
sudo systemctl start containerd
# Backup and update containerd configuration file
sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.orig 
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# Download CNI plugins
sudo mkdir -p /opt/cni/bin
sudo wget -qO- https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz | sudo tar -xzvf - -C /opt/cni/bin
# Restart containerd
sudo systemctl restart containerd
# Enable required kernel modules
sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
# Install Kubernetes packages
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/kubernetes-archive-keyring.gpg
#sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
# Reload systemd configuration and restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
# Enable required kernel modules
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.ipv4.ip_forward=1
sudo cat <<EOF | sudo tee /etc/sysctl.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl -p
# Initialize Kubernetes cluster
sudo kubeadm init
# Create the kube config directory in the current user's home directory
sudo mkdir -p $HOME/.kube 
# Copy the Kubernetes cluster configuration file from the default location to the kube config directory
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# Change the ownership of the copied configuration file to the current user and group
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# Deploy the weave-net network plugin for Kubernetes networking
sudo kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# Taint all nodes with the node-role.kubernetes.io/control-plane taint to prevent pods from being scheduled on the control plane node(s)
sudo kubectl taint nodes --all node-role.kubernetes.io/control-plane-
# Update the package list and install the bash-completion package for kubectl command completion
sudo apt-get update
sudo apt-get install bash-completion
# Configure bash shell command completion for kubectl
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

############################ArgoCD Install#################################
# argocd namespace 생성
kubectl create namespace argocd
# argocd 설치 매니페스트 다운로드 및 argocd 서버 배포
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# argocd 서버 서비스의 유형을 NodePort로 변경
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
# argocd 서버 서비스의 유형을 LoadBalancer로 변경 - nks 사용시
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
# argocd CLI 다운로드
VERSION=v2.4.4; curl -sL -o argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
# argocd CLI 실행 권한 부여
chmod +x argocd
# argocd CLI를 /usr/local/bin 디렉토리로 이동
sudo mv argocd /usr/local/bin/argocd
kubectl get svc -n argocd | grep NodePort
