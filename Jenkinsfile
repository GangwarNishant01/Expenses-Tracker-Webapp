pipeline {
    agent any

    environment {
        SONAR_HOME = tool "Sonar"
        ProjectName = "expenses-tracker-app"
    }

    parameters {
        string(name: 'DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }

    stages {

        stage("Validate Parameters") {
            steps {
                script {
                    if (params.DOCKER_TAG == '') {
                        error("DOCKER_TAG must be provided.")
                    }
                }
            }
        }

        stage("Workspace Cleanup") {
            steps {
                echo "Cleaning up Workspace"
                cleanWs()
            }
        }

        stage("Git: Code Checkout") {
            steps {
                sh '''
                    git clone https://github.com/GangwarNishant01/Expenses-Tracker-Webapp.git
                    cd Expenses-Tracker-Webapp
                    echo "Repository is Cloned successfully"
                '''
            }
        }

        stage("Trivy: Filesystem Scan") {
            steps {
                dir('Expenses-Tracker-Webapp') {
                    sh "trivy fs ."
                }
            }
        }

        stage("OWASP: Dependency Check") {
            steps {
                dir('Expenses-Tracker-Webapp') {
                    dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'OWASP'
                }
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage("SonarQube: Code Analysis") {
            steps {
                dir('Expenses-Tracker-Webapp') {
                    withSonarQubeEnv("Sonar") {
                        sh "${SONAR_HOME}/bin/sonar-scanner -Dsonar.projectName=Expenses-tracker -Dsonar.projectKey=nishant-key -Dsonar.exclusions=**/*.java -X"
                    }
                }
            }
        }

        stage("SonarQube: Code Quality Gates") {
            steps {
                timeout(time: 1, unit: "MINUTES") {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage("Docker: Build Image") {
            steps {
                dir('Expenses-Tracker-Webapp') {
                    withCredentials([usernamePassword(credentialsId: "DockerHubCreds", passwordVariable: "DockerHubPass", usernameVariable: "DockerHubUser")]) {
                        sh "docker build -t ${env.DockerHubUser}/${env.ProjectName}:${params.DOCKER_TAG} ."
                        echo "Code Built Successfully!"
                    }
                }
            }
        }

        stage("Docker: Push to DockerHub") {
            steps {
                dir('Expenses-Tracker-Webapp') {
                    withCredentials([usernamePassword(credentialsId: "DockerHubCreds", passwordVariable: "DockerHubPass", usernameVariable: "DockerHubUser")]) {
                        sh "docker login -u ${env.DockerHubUser} -p ${env.DockerHubPass}"
                        sh "docker push ${env.DockerHubUser}/${env.ProjectName}:${params.DOCKER_TAG}"
                    }
                }
            }
        }
    }

    post {
    success {
        script {
            try {
                build job: "Expenses-Tracker-CD", parameters: [
                    string(name: 'DOCKER_TAG', value: "${params.DOCKER_TAG}")
                ]
            } catch (err) {
                echo "Triggering CD pipeline failed: ${err}"
                currentBuild.result = 'FAILURE'
            }
        }
    }
}
}
