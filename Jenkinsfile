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
  - name: shell
    image: node:latest
#    command: ["sleep"]
#    args: ["infinity"]
    securityContext:
      runAsUser: 1000
    resources:
      requests:
        cpu: "1000m"
      limits:
        cpu: "14"
  - name: verdaccio
    image: verdaccio/verdaccio
    ports:
    - containerPort: 4873
    securityContext:
      runAsUser: 1000
    resources:
      requests:
        cpu: "500m"
      limits:
        cpu: "1"
    volumeMounts:
    - name: verdaccio-config
      mountPath: "/verdaccio/conf/"
  volumes:
  - name: verdaccio-config
    configMap:
      name: verdaccio-config
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
              sh 'yes none | npm login --registry ${env.NPM_REGISTRY}'
              sh 'npm config set @vendure:registry ${env.NPM_REGISTRY}'
            }
        }
        stage('Publish NPM Packages') {
            steps {
              dir('vendure') {
                script {
                    def packages = [
                        "packages/common",
                        "packages/core",
                        "packages/admin-ui-plugin",
                        "packages/asset-server-plugin",
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
        /*
        stage('Building Docker image') {
          steps {
            container('docker') {
              dir('vendure-showcase') {
                sh 'docker build -t vendure-showcase .'
              }              
            }

          }
        }
        stage('Pushing Docker image') {
          steps {
            container('docker') {
              dir('vendure-showcase') {
                sh 'docker tag vendure-showcase:latest linas37/vendure-showcase:tagname:latest'
                sh 'docker push linas37/vendure-showcase:tagname:latest'
              }
            }
          }
        }
        */
    }
}