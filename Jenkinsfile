pipeline {
    agent any

    environment {
        AWS_REGION    = 'ap-south-1'
        AWS_ACCOUNT   = '722632731549'
        ECR_REPO      = 'project'
        EKS_CLUSTER   = 'project_cluster'
        K8S_NAMESPACE = 'default'
        KIND_HOST     = '65.0.131.38'
        KIND_SSH_USER = 'redhat
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                    env.ECR_URI =
                        "${env.AWS_ACCOUNT}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
                    env.IMAGE_URI = "${env.ECR_URI}:${env.IMAGE_TAG}"
                }

                sh '''
                    set -eu
                    docker build -t "$IMAGE_URI" .
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-ecr-credentials']
                ]) {
                    sh '''
                        set -eu

                        aws ecr get-login-password \
                          --region "$AWS_REGION" |
                          docker login \
                          --username AWS \
                          --password-stdin \
                          "$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"

                        docker push "$IMAGE_URI"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-ecr-credentials']
                ]) {
                    sh '''
                        set -eu

                        aws eks update-kubeconfig \
                          --region "$AWS_REGION" \
                          --name "$EKS_CLUSTER"

                        IMAGE_DIGEST=$(aws ecr describe-images \
                          --region "$AWS_REGION" \
                          --repository-name "$ECR_REPO" \
                          --image-ids imageTag="$IMAGE_TAG" \
                          --query 'imageDetails[0].imageDigest' \
                          --output text)

                        test -n "$IMAGE_DIGEST"
                        test "$IMAGE_DIGEST" != "None"

                        kubectl -n "$K8S_NAMESPACE" set image \
                          "deployment/$DEPLOYMENT" \
                          "$CONTAINER=$ECR_URI@$IMAGE_DIGEST"

                        kubectl -n "$K8S_NAMESPACE" rollout status \
                          "deployment/$DEPLOYMENT" \
                          --timeout=180s
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
            sh 'docker logout "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com" || true'
        }
    }
}
