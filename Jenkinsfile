node {
  stage ('======== Clone repository ========') {
    checkout scm
  }
  stage('======== Build image ========') {
    sh "git switch main"
    sh "git config --global user.email 'admin@example.com'"
    sh "git config --global user.name 'admin'"
    sh "git pull origin main"
    app = docker.build("shryu/nginx")
  }
  stage('======== Push image ========') {
    docker.withRegistry('https://shryu.kr.ncr.ntruss.com', 'docker') {
       app.push("${env.BUILD_NUMBER}")
       app.push("latest")
    }
  }
  stage('======== Update YAML file ========') {
    sh "git switch yaml"
    sh "git pull origin yaml"
    sh "sed -i s%shryu/nginx:.*%shryu/nginx:${env.BUILD_NUMBER}%g nginx.yaml"
    sh "cat nginx.yaml | grep image:"
    sh "git add ."
    sh "git commit -m 'image tag update ${env.BUILD_NUMBER}'"
    sh "git push -u origin yaml"
  }
}
