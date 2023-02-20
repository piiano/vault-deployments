PROJECT_NAME		:= vault-deployments
REPO_NAME		:= $(PROJECT_NAME)
ENV			?= dev
PVAULT_DOCKER_TAG	?= latest
SERVICE			?= aws-ecs# Set this to the service name - aws-apprunner / aws-ecs

# Terraform.
TF_ENV			:= piiano-sandbox-04
TF_STATE_BASE		:= $(TF_ENV)-terraform-state
RDS_PASS		?= Password1# Changeme later.
TF_DIR			?= $(SERVICE)

# AWS.
AWS_ACCOUNT		:= 963086747405
export AWS_REGION	?= us-east-2
export AWS_DEFAULT_REGION ?= $(AWS_REGION)
ECR_REGISTRY		:= $(AWS_ACCOUNT).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com
RDS_INSTANCE_TYPE	?= db.r6g.large

define TF_VARS
-var="rds_password=$(RDS_PASS)" \
-var="service=$(SERVICE)" \
-var="rds_instance_class=$(RDS_INSTANCE_TYPE)"
endef

.PHONY: infra-init
infra-init:
	terraform -chdir=$(TF_DIR) init -reconfigure \
		-backend-config="bucket=$(TF_STATE_BASE)" \
		-backend-config="dynamodb_table=$(TF_ENV)-$(PROJECT_NAME)-$(SERVICE)-lock" \
		-backend-config="key=$(REPO_NAME)/$(PROJECT_NAME)-$(SERVICE)/terraform.tfstate"

.PHONY: infra-plan
infra-plan: infra-init
	terraform -chdir=$(TF_DIR) plan \
		-var-file=$(ENV).tfvars

.PHONY: infra-apply
infra-apply: infra-init
	terraform -chdir=$(TF_DIR) apply -auto-approve \
		-var-file=$(ENV).tfvars

.PHONY: infra-destroy
infra-destroy: infra-init
	terraform -chdir=$(TF_DIR) destroy -auto-approve


ifndef SERVICE
	$(error Missing SERVICE param)
endif
