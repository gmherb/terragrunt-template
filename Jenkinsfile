pipeline {
    agent {
        dockerfile {
            filename = 'Dockerfile'
        }
    }
    triggers {
        cron(env.BRANCH_NAME == 'main' ? '0 16 * * 1-5' : '')
    }
    environment {
        AWS_CREDS             = credentials('terraform-service-account')
        AWS_ACCESS_KEY_ID     = "${env.AWS_CREDS_USR}"
        AWS_SECRET_ACCESS_KEY = "${env.AWS_CREDS_PSW}"
        SSH_KEY_PATH          = credentials('terraform-service-account-ssh-key')
        TF_INPUT              = false // Assume yes to interactive prompts in terraform
    }
    parameters {
        booleanParam(name: 'TF_ENABLE_DESTROY', defaultValue: false, description: 'Toggle to enable DESTRUCTIVE terraform actions.')
    }
    options {
        ansiColor('xterm')
        disableConcurrentBuilds()
        skipStagesAfterUnstable()
        timestamps()
    }
    stages {
        stage('Setup') {
            steps {
                echo "Running SSH Authentication steps..."
                sh '''
                    echo "Host *\n  IdentityFile ${SSH_KEY_PATH}\n  User git" > ~/.ssh/config
                    make version
                '''
            }
        }
        stage('Plan') {
            matrix {
                when { anyOf { not { branch 'main' }; triggeredBy 'TimerTrigger' } }
                axes {
                    axis {
                        name 'ENV'
                        values 'dev', 'prod' // Add more environments here...
                    }
                }
                stages {
                    stage('Plan') {
                        steps {
                            echo "Running plan in ${ENV}..."
                            sh 'make plan-${ENV}-ci'
                            archiveArtifacts artifacts: "plan-${ENV}-ci"
                        }
                    }
                }
            }
        }
        stage('Apply - Dev') {
            when { allOf { branch 'main'; not { triggeredBy 'TimerTrigger' } } }
            steps {
                echo "Running apply in dev..."
                sh 'make apply-dev-ci'
                archiveArtifacts artifacts: 'plan-dev-ci,apply-dev-ci'
            }
        }
        // Add additional stages for other environments here...
        stage('Apply - Prod') {
            when { allOf { branch 'main'; not { triggeredBy 'TimerTrigger' } } }
            steps {
                input(
                    message: "Apply in prod?",
                    ok: "Yes",
                    submitter: "ADD_CODEOWNERS_HERE"
                )
                echo "Running apply in prod..."
                sh 'make apply-prod-ci'
                archiveArtifacts artifacts: 'plan-prod-ci,apply-prod-ci'
            }
        }
    }
    post {
        always {
            echo "Sending slack notification..."
            sh 'make slack-notification'
        }
        cleanup {
            cleanWs()
        }
    }
}