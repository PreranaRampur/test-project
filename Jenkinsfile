pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven3'
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '722632731549'
        ECR_REPOSITORY = 'project_ecr/mini_project'
        SONARQUBE_SERVER = 'SonarQube'

        GITOPS_VALUES_FILE = 'helm/java-app/values-prod.yaml'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY =
                        "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

                    env.IMAGE_URI =
                        "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                }
            }
        }

        stage('Build and Test') {
            steps {
                sh 'mvn -B clean verify'
            }

            post {
                always {
                    junit(
                        testResults: 'target/surefire-reports/*.xml',
                        allowEmptyResults: true
                    )

                    archiveArtifacts(
                        artifacts: 'target/site/jacoco/**',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                branch 'main'
            }

            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                        mvn -B org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                          -Dsonar.projectKey=java-cicd-demo \
                          -Dsonar.projectName=java-cicd-demo \
                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    '''
                }
            }
        }

        stage('Quality Gate') {
            when {
                branch 'main'
            }

            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            when {
                branch 'main'
            }

            steps {
                sh 'docker build --pull -t "$IMAGE_URI" .'
            }
        }

        stage('Trivy Security Scan') {
            when {
                branch 'main'
            }

            steps {
                sh '''
                    trivy image \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      --ignore-unfixed \
                      "$IMAGE_URI"
                '''
            }
        }

        stage('Push Image to ECR') {
            when {
                branch 'main'
            }

            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        set -eu

                        aws ecr get-login-password \
                          --region "$AWS_DEFAULT_REGION" |
                          docker login \
                            --username AWS \
                            --password-stdin "$ECR_REGISTRY"

                        docker push "$IMAGE_URI"
                    '''
                }
            }
        }

        stage('Update Helm for Argo CD') {
            when {
                branch 'main'
            }

            steps {
                withCredentials([gitUsernamePassword(
                    credentialsId: 'gitops-github',
                    gitToolName: 'Default'
                )]) {
                    sh '''
                        set -eu

                        sed -i -E \
                          "s/^([[:space:]]*tag:).*/\\1 \\"${IMAGE_TAG}\\"/" \
                          "$GITOPS_VALUES_FILE"

                        git config user.name "jenkins"
                        git config user.email "jenkins@example.com"

                        git add "$GITOPS_VALUES_FILE"

                        if ! git diff --cached --quiet; then
                            git commit -m "Deploy ${IMAGE_TAG} [skip ci]"
                            git push origin HEAD:main
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                if (env.IMAGE_URI) {
                    sh 'docker image rm "$IMAGE_URI" || true'
                }
            }

            cleanWs()
        }

        success {
            echo 'Pipeline succeeded. Argo CD will reconcile Helm changes.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage in the console log.'
        }
    }
}
