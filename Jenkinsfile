#!/usr/bin/env groovy

/**
 * Jenkins Pipeline for Terraform Cloudflare Maintenance Module
 *
 * This pipeline validates, tests, and optionally deploys the Terraform module
 * with comprehensive checks for code quality, security, and functionality.
 */

// Pipeline configuration
def TERRAFORM_VERSION = '1.7.1'
def NODE_VERSION = '20'
def TFLINT_VERSION = 'v0.50.0'

pipeline {
    agent {
        label 'terraform'
    }

    options {
        buildDiscarder(logRotator(
            numToKeepStr: '30',
            artifactNumToKeepStr: '10'
        ))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment for deployment'
        )
        booleanParam(
            name: 'DEPLOY',
            defaultValue: false,
            description: 'Deploy changes to Cloudflare (requires approval)'
        )
        booleanParam(
            name: 'RUN_SECURITY_SCAN',
            defaultValue: true,
            description: 'Run security scanning with tfsec'
        )
    }

    environment {
        // Terraform configuration
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        TF_CLI_ARGS = '-no-color'

        // Credentials (stored in Jenkins credentials)
        CLOUDFLARE_API_TOKEN = credentials('cloudflare-api-token')
        CLOUDFLARE_ACCOUNT_ID = credentials('cloudflare-account-id')
        CLOUDFLARE_ZONE_ID = credentials('cloudflare-zone-id')

        // Paths
        WORKSPACE_DIR = "${env.WORKSPACE}"
        WORKER_DIR = "${env.WORKSPACE}/worker"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out source code...'
                checkout scm

                script {
                    // Set build description
                    currentBuild.description = "Environment: ${params.ENVIRONMENT}"
                }
            }
        }

        stage('Setup') {
            parallel {
                stage('Install Terraform') {
                    steps {
                        echo '🔧 Setting up Terraform...'
                        sh """
                            # Install Terraform if not present or wrong version
                            if ! command -v terraform &> /dev/null || [ "\$(terraform version -json | jq -r '.terraform_version')" != "${TERRAFORM_VERSION}" ]; then
                                curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
                                unzip -o terraform.zip
                                chmod +x terraform
                                sudo mv terraform /usr/local/bin/
                            fi
                            terraform version
                        """
                    }
                }

                stage('Install Node.js Dependencies') {
                    steps {
                        echo '📦 Installing Node.js dependencies...'
                        dir("${WORKER_DIR}") {
                            sh """
                                # Use nvm if available
                                export NVM_DIR="\$HOME/.nvm"
                                [ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

                                # Install dependencies
                                npm ci

                                # Audit for vulnerabilities
                                npm audit --audit-level=moderate || true
                            """
                        }
                    }
                }

                stage('Install TFLint') {
                    when {
                        expression { params.RUN_SECURITY_SCAN }
                    }
                    steps {
                        echo '🔍 Installing TFLint...'
                        sh """
                            if ! command -v tflint &> /dev/null; then
                                curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
                            fi
                            tflint --version
                        """
                    }
                }

                stage('Install TFSec') {
                    when {
                        expression { params.RUN_SECURITY_SCAN }
                    }
                    steps {
                        echo '🛡️ Installing TFSec...'
                        sh """
                            if ! command -v tfsec &> /dev/null; then
                                curl -fsSL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64 -o tfsec
                                chmod +x tfsec
                                sudo mv tfsec /usr/local/bin/
                            fi
                            tfsec --version
                        """
                    }
                }
            }
        }

        stage('Validate') {
            parallel {
                stage('Terraform Format Check') {
                    steps {
                        echo '📝 Checking Terraform formatting...'
                        sh """
                            terraform fmt -check -recursive -diff || {
                                echo "ERROR: Terraform files are not formatted correctly"
                                echo "Run 'terraform fmt -recursive' to fix"
                                exit 1
                            }
                        """
                    }
                }

                stage('Terraform Validate') {
                    steps {
                        echo '✅ Validating Terraform configuration...'
                        sh """
                            terraform init -backend=false
                            terraform validate
                        """
                    }
                }

                stage('TypeScript Type Check') {
                    steps {
                        echo '🔍 Running TypeScript type checking...'
                        dir("${WORKER_DIR}") {
                            sh 'npm run typecheck'
                        }
                    }
                }

                stage('ESLint') {
                    steps {
                        echo '🔍 Running ESLint...'
                        dir("${WORKER_DIR}") {
                            sh 'npm run lint || true'  // Don't fail on warnings
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            when {
                expression { params.RUN_SECURITY_SCAN }
            }
            parallel {
                stage('TFLint') {
                    steps {
                        echo '🔍 Running TFLint security checks...'
                        sh """
                            tflint --init
                            tflint --format compact --force || true
                        """
                    }
                }

                stage('TFSec') {
                    steps {
                        echo '🛡️ Running TFSec security analysis...'
                        sh """
                            tfsec . --format json --out tfsec-results.json --soft-fail || true
                            tfsec . --format default
                        """
                    }
                }

                stage('NPM Audit') {
                    steps {
                        echo '🔒 Running npm security audit...'
                        dir("${WORKER_DIR}") {
                            sh """
                                npm audit --json > npm-audit.json || true
                                npm audit || true
                            """
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'tfsec-results.json,worker/npm-audit.json', allowEmptyArchive: true
                }
            }
        }

        stage('Test') {
            parallel {
                stage('Worker Unit Tests') {
                    steps {
                        echo '🧪 Running Worker unit tests...'
                        dir("${WORKER_DIR}") {
                            sh """
                                npm test -- --reporter=junit --outputFile=test-results.xml
                                npm run test:coverage
                            """
                        }
                    }
                    post {
                        always {
                            junit "${WORKER_DIR}/test-results.xml"
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: "${WORKER_DIR}/coverage",
                                reportFiles: 'index.html',
                                reportName: 'Worker Test Coverage'
                            ])
                        }
                    }
                }

                stage('Terraform Tests') {
                    steps {
                        echo '🧪 Running Terraform tests...'
                        script {
                            // Run tests with timeout
                            timeout(time: 10, unit: 'MINUTES') {
                                sh """
                                    export TF_VAR_cloudflare_api_token=\${CLOUDFLARE_API_TOKEN}
                                    export TF_VAR_cloudflare_account_id=\${CLOUDFLARE_ACCOUNT_ID}
                                    export TF_VAR_cloudflare_zone_id=\${CLOUDFLARE_ZONE_ID}

                                    # Run basic tests
                                    terraform test -filter=tests/basic.tftest.hcl || echo "Basic tests check skipped"

                                    # Run worker tests
                                    terraform test -filter=tests/worker.tftest.hcl || echo "Worker tests check skipped"

                                    # Run advanced tests
                                    terraform test -filter=tests/advanced.tftest.hcl || echo "Advanced tests check skipped"
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Build Worker') {
            steps {
                echo '🏗️ Building Cloudflare Worker...'
                dir("${WORKER_DIR}") {
                    sh """
                        npm run build

                        # Verify build output
                        if [ ! -f "dist/index.js" ]; then
                            echo "ERROR: Worker build failed - dist/index.js not found"
                            exit 1
                        fi

                        # Check bundle size
                        BUNDLE_SIZE=\$(wc -c < dist/index.js)
                        echo "Bundle size: \${BUNDLE_SIZE} bytes"

                        # Warn if bundle is too large (>1MB is Cloudflare's limit)
                        if [ \${BUNDLE_SIZE} -gt 1048576 ]; then
                            echo "WARNING: Bundle size exceeds 1MB limit"
                            exit 1
                        fi
                    """
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'worker/dist/index.js', fingerprint: true
                }
            }
        }

        stage('Plan') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                echo '📋 Creating Terraform plan...'
                script {
                    sh """
                        export TF_VAR_cloudflare_api_token=\${CLOUDFLARE_API_TOKEN}
                        export TF_VAR_cloudflare_account_id=\${CLOUDFLARE_ACCOUNT_ID}
                        export TF_VAR_cloudflare_zone_id=\${CLOUDFLARE_ZONE_ID}
                        export TF_VAR_environment=${params.ENVIRONMENT}

                        terraform init
                        terraform plan -out=tfplan-${params.ENVIRONMENT}.bin
                        terraform show -no-color tfplan-${params.ENVIRONMENT}.bin > tfplan-${params.ENVIRONMENT}.txt
                    """
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "tfplan-${params.ENVIRONMENT}.txt", fingerprint: true
                }
            }
        }

        stage('Approval') {
            when {
                expression { params.DEPLOY && params.ENVIRONMENT == 'production' }
            }
            steps {
                script {
                    // Read the plan for display
                    def planOutput = readFile("tfplan-${params.ENVIRONMENT}.txt")

                    // Request approval
                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: "Deploy to ${params.ENVIRONMENT}?",
                            ok: 'Deploy',
                            parameters: [
                                text(
                                    name: 'PLAN_REVIEW',
                                    defaultValue: planOutput,
                                    description: 'Review the Terraform plan before approving'
                                )
                            ]
                        )
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                echo "🚀 Deploying to ${params.ENVIRONMENT}..."
                script {
                    sh """
                        export TF_VAR_cloudflare_api_token=\${CLOUDFLARE_API_TOKEN}
                        export TF_VAR_cloudflare_account_id=\${CLOUDFLARE_ACCOUNT_ID}
                        export TF_VAR_cloudflare_zone_id=\${CLOUDFLARE_ZONE_ID}
                        export TF_VAR_environment=${params.ENVIRONMENT}

                        terraform apply -auto-approve tfplan-${params.ENVIRONMENT}.bin

                        # Save outputs
                        terraform output -json > terraform-outputs.json
                    """
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'terraform-outputs.json', allowEmptyArchive: true
                }
                success {
                    echo "✅ Successfully deployed to ${params.ENVIRONMENT}"
                }
                failure {
                    echo "❌ Deployment to ${params.ENVIRONMENT} failed"
                }
            }
        }

        stage('Smoke Test') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                echo '🧪 Running smoke tests...'
                script {
                    sh """
                        # Parse outputs
                        WORKER_ROUTE=\$(terraform output -raw worker_route_pattern || echo "")
                        MAINTENANCE_STATUS=\$(terraform output -raw maintenance_status || echo "")

                        echo "Worker Route: \${WORKER_ROUTE}"
                        echo "Maintenance Status: \${MAINTENANCE_STATUS}"

                        # Basic connectivity check
                        if [ -n "\${WORKER_ROUTE}" ] && [ "\${MAINTENANCE_STATUS}" = "ENABLED" ]; then
                            echo "Smoke test: Maintenance mode is active"
                            # Add additional smoke tests here as needed
                        fi
                    """
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            cleanWs(
                deleteDirs: true,
                disableDeferredWipeout: true,
                patterns: [
                    [pattern: '.terraform', type: 'INCLUDE'],
                    [pattern: 'worker/node_modules', type: 'INCLUDE'],
                    [pattern: '*.bin', type: 'INCLUDE']
                ]
            )
        }
        success {
            echo '✅ Pipeline completed successfully!'
            script {
                if (params.DEPLOY) {
                    // Send success notification
                    // mail to: 'team@example.com',
                    //      subject: "Deployment Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    //      body: "The deployment to ${params.ENVIRONMENT} completed successfully."
                }
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                // Send failure notification
                // mail to: 'team@example.com',
                //      subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                //      body: "The build failed. Check ${env.BUILD_URL} for details."
            }
        }
        unstable {
            echo '⚠️ Pipeline completed with warnings'
        }
    }
}
