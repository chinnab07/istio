#!/usr/bin/env groovy
pipeline {
    agent any
    environment{
       // Required Configs
        FEATURE_NAME = BRANCH_NAME.replaceAll('[\\(\\)_/]','-').toLowerCase()
        http_proxy = "http://bh-app-proxy.corp.dmz:8080"
        https_proxy = "http://bh-app-proxy.corp.dmz:8080"
        HTTP_PROXY = "http://bh-app-proxy.corp.dmz:8080"
        HTTPS_PROXY = "http://bh-app-proxy.corp.dmz:8080"
        NO_PROXY = "169.254.169.254,karma-runner,protractor-runner,selenium,corp.dmz,127.0.0.1,0.0.0.0,localhost,10.212.0.0/16,172.20.0.1,10.77.0.0/16"
        no_proxy = "169.254.169.254,karma-runner,protractor-runner,selenium,corp.dmz,127.0.0.1,0.0.0.0,localhost,10.212.0.0/16,172.20.0.1,10.77.0.0/16"
        AWS_DEFAULT_REGION  = "ap-southeast-2"
        NEXUS_HOST = "nexus.corp.dmz:8083"
        NEXUS_USERNAME = credentials('NEXUS_USERNAME')
        NEXUS_PASSWORD = credentials('NEXUS_PASSWORD')
        KIALI_PASSPHRASE = credentials('KIALI_PASSPHRASE')
        KIALI_USERNAME = credentials('KIALI_USERNAME')

        // Project Variables
        EKS_DOMAIN = "ob-intl-au-aws-efx"

        // AWS Credentials
        // NONPROD Deployment Account

        AWS_NONPROD_ACCOUNT_ID = credentials('OPEN_BANKING_NONPROD_TERRAFORM_DEPLOYMENT_ROLE_ACCOUNT_ID')
        AWS_NONPROD_EXTERNAL_ID = credentials('OPEN_BANKING_NONPROD_TERRAFORM_DEPLOYMENT_ROLE_EXTERNAL_ID')
        AWS_NONPROD_ROLE_NAME = credentials('OPEN_BANKING_NONPROD_TERRAFORM_DEPLOYMENT_ROLE_NAME')

        // App Configs
        ISTIO_VERSION = "1.2.2"
        DNS = "open-banking.intl-au.aws.efx"
        NAME_SPACE = "open-banking"
        KIALI_DOMAIN = "kiali.telemetry.<ENV>.${DNS}"
        GRAFANA_DOMAIN = "grafana.telemetry.<ENV>.${DNS}" 
        TRACING_DOMAIN =  "tracing.telemetry.<ENV>.${DNS}"
        PROMETHEUS_DOMAIN = "prometheus.telemetry.<ENV>.${DNS}"
    }
    
    stages {
        // ################### DEV ###################
        stage('DEV') {
            when {branch 'istio-sidecar-testing'}
            environment { 
                // Environment Config
                ENV = "dev"
                ENV_TYPE = "nonprod"
                AWS_ACCOUNT_ID = "${AWS_NONPROD_ACCOUNT_ID}" 
                AWS_ROLE_NAME = "${AWS_NONPROD_ROLE_NAME}"
                AWS_EXTERNAL_ID = "${AWS_NONPROD_EXTERNAL_ID}"
                KIALI_DOMAIN = "${KIALI_DOMAIN}".replaceAll("<ENV>", "${ENV}")   
                GRAFANA_DOMAIN = "${GRAFANA_DOMAIN}".replaceAll("<ENV>", "${ENV}")
                TRACING_DOMAIN = "${TRACING_DOMAIN}".replaceAll("<ENV>", "${ENV}")
                PROMETHEUS_DOMAIN = "${PROMETHEUS_DOMAIN}".replaceAll("<ENV>", "${ENV}")
                INGRESS_GW_CRT_ARN = "arn:aws:secretsmanager:ap-southeast-2:701381577861:secret:dev-open-banking.pem-R3bhnm"
                INGRESS_GW_KEY_ARN = "arn:aws:secretsmanager:ap-southeast-2:701381577861:secret:dev-open-banking.key-Rc3k2R"
                INGRESS_GW_SSL_SECRET_NAME = "ingressgateway-dev-openbanking-certs"

                // App Config
                EKS_CLUSTER_NAME = "${ENV}-${EKS_DOMAIN}"
            }
            stages {

                // Deploys Kiam
                 stage('Dev: Deploy ISTIO') {
                    steps {
                        withAWS(role:"${AWS_ROLE_NAME}", roleAccount:"${AWS_ACCOUNT_ID}", externalId: "${AWS_EXTERNAL_ID}", region: "${AWS_DEFAULT_REGION}") {
                            sh "make nexusLogin applyArnConfig istio.install istio.deploy istio.gateway istio.envoyInjection istio.telemetry istio.serviceEntry"
                            //   sh "make nexusLogin applyArnConfig  istio.undeploy"
                        }
                    }
                }
            }
        }
    }
}

