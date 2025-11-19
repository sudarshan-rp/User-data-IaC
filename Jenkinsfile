pipeline {
    agent any   // or label your agent that has Terraform 1.5.7 and AWS CLI

    parameters {
        choice(
            name: 'ACTION',
            choices: ['create-cluster', 'delete-cluster'],
            description: 'What do you want to do with the EKS cluster?'
        )
    }

    environment {
        // Pull secrets from Jenkins credentials
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')           // ID of AWS Credentials
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')           // same ID, second field
        BUCKET_TF_STATE       = credentials('BUCKET_TF_STATE')         // Secret text credential
        AWS_DEFAULT_REGION    = 'us-east-1'  // change if needed
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Terraform') {
            steps {
                script {
                    // Download exact Terraform version (same as GitHub Actions)
                    sh '''
                        wget -q https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
                        unzip -o terraform_1.5.7_linux_amd64.zip
                        sudo mv terraform /usr/local/bin/terraform || mv terraform /usr/bin/terraform
                        terraform --version
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                    terraform init \
                      -backend-config="bucket=${BUCKET_TF_STATE}" \
                      -backend-config="key=eks-cluster.tfstate" \
                      -backend-config="region=${AWS_DEFAULT_REGION}"
                """
            }
        }

        stage('Terraform Format & Validate') {
            steps {
                sh 'terraform fmt'
                sh 'terraform fmt -check'
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -input=false'
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    if (params.ACTION == 'create-cluster') {
                        sh 'terraform apply -auto-approve -input=false'
                    }
                    else if (params.ACTION == 'delete-cluster') {
                        sh 'terraform destroy -auto-approve -input=false'
                    }
                    else {
                        error "Invalid action selected"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()  // optional: clean workspace
        }
        success {
            echo "EKS cluster operation completed successfully!"
        }
        failure {
            echo "Pipeline failed"
        }
    }
}
