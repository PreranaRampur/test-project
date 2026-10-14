
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPOSITORY = 'project_ecr/mini_project'
        IMAGE_TAG=" latest"
        ECR_REGISTRY = '722632731549.dkr.ecr.ap-south-1.amazonaws.com'
        KIND_HOST = '13.126.217.241'
        KIND_SSH_USER = 'ubuntu'
        K8S_NAMESPACE = 'default'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Image Details') {
            steps {
                script {

                    env.AWS_ACCOUNT_ID = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_URI = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"

                    echo "Image to publish: ${env.IMAGE_URI}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build -t 722632731549.dkr.ecr.ap-south-1.amazonaws.com/project_ecr/mini_project:latest .
                '''
            }
        }

        stage('Push to ECR') {
steps {
sh '''
set -eu
        aws ecr get-login-password --region ap-south-1 | \
        docker login --username AWS --password-stdin \
        722632731549.dkr.ecr.ap-south-1.amazonaws.com

        docker push 722632731549.dkr.ecr.ap-south-1.amazonaws.com/project_ecr/mini_project:latest
    '''
    }

}
        
    stage('Deploy to Kubernetes') {
    steps {
        sshagent(['kind-ssh-key']) {
            sh '''
                set -eu

                sed "s|IMAGE_PLACEHOLDER|$IMAGE_URI|g" \
                  deployment.yaml > deployment-rendered.yaml

                scp -o StrictHostKeyChecking=accept-new \
                  deployment-rendered.yaml \
                  ubuntu@13.126.217.241:/tmp/mini_project.yaml

                ssh -o StrictHostKeyChecking=accept-new \
                  ubuntu@13.126.217.241 \
                  "kubectl apply -f /tmp/mini_project.yaml"
            '''
          }
       }
    } 
}
    post {

        success {
            echo 'Image pushed to ECR and deployment completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins logs for details.'
        }

        always {
            sh '''
                if [ -n "${ECR_REGISTRY:-}" ]; then
                    docker logout "$ECR_REGISTRY" || true
                fi
            '''
        }
    }
  }
