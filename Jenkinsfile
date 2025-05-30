node {
  stage ('======== Clone repository ========') {
    checkout scm
  }
  stage('======== Build image ========') {
    sh "git switch main"
    sh "git config --global user.email 'admin@example.com'"
    sh "git config --global user.name 'admin'"
    sh "git pull origin main"
    app = docker.build("shryu.kr.ncr.ntruss.com/nginx")
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
    sh "sed -i s%shryu.kr.ncr.ntruss.com/nginx:.*%shryu.kr.ncr.ntruss.com/nginx:${env.BUILD_NUMBER}%g nginx.yaml"
    sh "cat nginx.yaml | grep image:"
    withCredentials([usernamePassword(credentialsId: 'github-shryu1994', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
            sh "git config --global user.email 'admin@example.com'"
            sh "git config --global user.name 'admin'"
            
            sh "git add ."
            sh "git commit -m 'image tag update ${env.BUILD_NUMBER}'"
            
            sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/shryu1994/cicd.git HEAD:yaml"
        }
    }
}
