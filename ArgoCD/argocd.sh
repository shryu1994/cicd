#!/bin/bash
# argocd namespace 생성
kubectl create namespace argocd
# argocd 설치 매니페스트 다운로드 및 argocd 서버 배포
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# argocd 서버 서비스의 유형을 NodePort로 변경
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
# argocd 서버 서비스의 유형을 LoadBalancer로 변경 - nks 사용시
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
# argocd CLI 다운로드
VERSION=v2.4.4; curl -sL -o argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
# argocd CLI 실행 권한 부여
chmod +x argocd
# argocd CLI를 /usr/local/bin 디렉토리로 이동
sudo mv argocd /usr/local/bin/argocd
kubectl get svc -n argocd | grep LoadBalancer
