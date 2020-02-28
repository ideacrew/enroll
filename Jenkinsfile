env.ENGINES_RESULT = 0
env.RSPEC_RESULT = 0
env.CUCUMBER_RESULT = 0

branch_naming = '*/master'

repo_url = "https://github.com/health-connector/enroll/"

pipeline {
    agent any
    triggers {
      pollSCM("H/5 * * * *")
    }
    stages {
      stage("Tests") {
        parallel {
          stage("Engine RSpec") {
            agent {
              label "master"
            }
            steps {
              checkout([$class: 'GitSCM', branches: [[name: "${branch_naming}"]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CleanBeforeCheckout'], [$class: 'LocalBranch', localBranch: '**']], submoduleCfg: [], userRemoteConfigs: [[url: repo_url]]])
              script {
                env.GIT_COMMIT = sh returnStdout: true, script: "git rev-parse HEAD | tr -d '\\n' | tr -d '\\r'"
                env.GIT_BRANCH_NAME = sh returnStdout: true, script: "git rev-parse --abbrev-ref HEAD | tr -d '\\n' | tr -d '\\r'"
                env.ENGINES_RESULT = sh returnStatus: true, script: """
                source ~/.bashrc || true
                base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
                export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
                export https_proxy=\$http_proxy
                export PATH=/usr/local/bin:\$PATH
                ./jenkins/engines.sh
                """
                echo env.ENGINES_RESULT
                if ((env.ENGINES_RESULT != 0) && (env.ENGINES_RESULT != '0')) {
                  error "Engine RSpecs Failed"
                }
              }
            }
          }
          stage("RSpec") {
            agent {
              label "slave2"
            }
            steps {
              checkout([$class: 'GitSCM', branches: [[name: "${branch_naming}"]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CleanBeforeCheckout'], [$class: 'LocalBranch', localBranch: '**']], submoduleCfg: [], userRemoteConfigs: [[url: repo_url]]])
              script {
                env.RSPEC_RESULT = sh returnStatus: true, script: """
                source ~/.bashrc || true
                base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
                export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
                export https_proxy=\$http_proxy
                export PATH=/usr/local/bin:\$PATH
                ./jenkins/rspec.sh
                """
                junit allowEmptyResults: true, testResults: 'tmp/rspec_junit_*.xml'
                if ((env.RSPEC_RESULT != 0) && (env.RSPEC_RESULT != '0')) {
                    error "RSpecs Failed"
                } else {
                    sh "rm -rf coverage.zip"
                    sh "zip -r coverage.zip coverage"
                    stash includes: 'coverage.zip', name: 'coverage_zip'
                }
              }
            }
          }
          stage("Cucumbers") {
            agent {
              label "master"
            }
            steps {
              checkout([$class: 'GitSCM', branches: [[name: "${branch_naming}"]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CleanBeforeCheckout'], [$class: 'LocalBranch', localBranch: '**']], submoduleCfg: [], userRemoteConfigs: [[url: repo_url]]])
              script {
                env.CUCUMBER_RESULT = sh returnStatus: true, script: """
                source ~/.bashrc || true
                base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
                export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
                export https_proxy=\$http_proxy
                export PATH=/usr/local/bin:\$PATH
                ./jenkins/cucumber.sh
                """
                if ((env.CUCUMBER_RESULT != 0) && (env.CUCUMBER_RESULT != '0')) {
                  error "Cucumbers Failed"
                }
              }
            }
          }
        }
        post {
          success {
            sh """
echo "{\\"project\\":\\"enroll_ma\\",\\"branch\\":\\"${env.GIT_BRANCH_NAME}\\",\\"sha\\":\\"${env.GIT_COMMIT}\\",\\"status\\":\\"passing\\"}"
curl -H "Content-Type: application/json" -H "X-API-Key: DEPLOYMENT_TEST_API_KEY" -X POST http://tx.hra.openhbx.org:9000/api/build_results -d "{\\"project\\":\\"enroll_dc\\",\\"branch\\":\\"${env.GIT_BRANCH_NAME}\\",\\"sha\\":\\"${env.GIT_COMMIT}\\",\\"status\\":\\"passing\\"}"
            """
          }
          failure {
            sh """
echo "{\\"project\\":\\"enroll_ma\\",\\"branch\\":\\"${env.GIT_BRANCH_NAME}\\",\\"sha\\":\\"${env.GIT_COMMIT}\\",\\"status\\":\\"failing\\"}"
curl -H "Content-Type: application/json" -H "X-API-Key: DEPLOYMENT_TEST_API_KEY" -X POST http://tx.hra.openhbx.org:9000/api/build_results -d "{\\"project\\":\\"enroll_dc\\",\\"branch\\":\\"${env.GIT_BRANCH_NAME}\\",\\"sha\\":\\"${env.GIT_COMMIT}\\",\\"status\\":\\"failing\\"}"
            """
          }
        }
      }
    }
}
