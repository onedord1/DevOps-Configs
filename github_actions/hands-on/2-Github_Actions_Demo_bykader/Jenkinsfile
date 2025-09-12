pipeline {
    agent any
    environment {
        DOCKER_USERNAME = "kaderdevops"  // Docker Hub username
        DOCKER_CREDENTIALS = "docker_jenkins_access" // Jenkins credentials ID
        IMAGE_NAME = "goal-front-jenkins"
        TAG = "deploy"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Abir-K/goal-frontend-with-jenkins'
            }
        }
        stage('Build Frontend') {
            steps {
                script {
                    // Build the frontend Docker image
                    docker.build("${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}", ".")
                }
            }
        }
        
        stage('Push Frontend Image') {
            steps {
                script {
                    // Use the correct Docker Hub registry URL for login
                    docker.withRegistry("https://index.docker.io/v1/", "${DOCKER_CREDENTIALS}") {
                        docker.image("${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}").push()
                    }
                }
            }
        }
        stage('Update Deployment File') {
        environment {
            GIT_REPO_NAME = "goal-frontend-with-jenkins"
            GIT_USER_NAME = "Abir-K"
            GIT_CRED = $ {{ secret.GIT_CRED }} //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_XOXO
        }
        steps {
            //withCredentials([usernamePassword(credentialsId: 'hellogithub', passwordVariable: 'pass', usernameVariable: 'uname')]) 
            withCredentials([string(credentialsId: 'github', variable: 'GIT_CRED')]){
                sh '''
                    git config --global user.email "abirbeatz@gmail.com"
                    git config --global user.name "Abir-K"
                    BUILD_NUMBER=${TAG}
                    sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" argocd_deployment/deployment.yaml
                    git add argocd_deployment/deployment.yaml
                    git commit -m "New Tag_${BUILD_NUMBER}"
                    git push https://${GIT_CRED}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                    
                '''
            }
        }
    }
    }
}
