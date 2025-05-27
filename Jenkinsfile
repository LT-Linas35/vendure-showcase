pipeline {
      environment {
        NPM_REGISTRY = 'http://localhost:4873'
    }
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: verdaccio
    image: verdaccio/verdaccio
    ports:
    - containerPort: 4873
    resources:
      requests:
        cpu: "500m"
      limits:
        cpu: "1"
  - name: shell
    image: node
    command: ["sleep"]
    args: ["infinity"]
    securityContext:
      runAsUser: 1000
    resources:
      requests:
        cpu: "1000m"
      limits:
        cpu: "3"
'''
            defaultContainer 'shell'
            retries 2
        }
    }
    stages {

        stage('Geting Vendure source') {
            steps {
                checkout scmGit(
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[url: 'https://github.com/LT-Linas35/vendure-showcase.git']])
            }
        }

        stage('Installing dependencies') {
            steps {
              dir('vendure') {
                sh 'npm i lerna'
                sh 'npm i vitest'
            } 
          }
        }


        stage('Building Vendure packages') {
            steps {
              dir('vendure') {
                sh 'npm run build'
              }
            }
        }
/*
        stage('Running Vendure tests') {
            steps {
              dir('vendure') {
                sh 'npm run test'
            } 
          }
        }
*/

        stage('Configuring NPM Registry') {
            steps {
              sh 'yes none | npm login --registry http://localhost:4873'
              sh 'npm config set @vendure:registry http://localhost:4873'
            }
        }
        stage('Publish NPM Packages') {
            steps {
              dir('vendure') {
                script {
                    def packages = [
                        "packages/admin-ui-plugin",
                        "packages/asset-server-plugin",
                        "packages/core",
                        "packages/email-plugin",
                        "packages/graphiql-plugin"
                    ]

                    packages.each { pkg ->
                        dir(pkg) {
                            echo "Publishing package in ${pkg}"
                            sh "npm publish --registry ${env.NPM_REGISTRY}"
                        }
                    }
                }
            }
          }
        }
}
}
