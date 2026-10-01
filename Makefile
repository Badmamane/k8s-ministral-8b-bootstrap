SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

ENV   ?= dev
VARS  := accounts/$(ENV).tfvars
STATE := state/$(ENV).tfstate

.PHONY: help fmt lint init plan apply destroy output

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

fmt: ## Format Terraform files
	terraform fmt -recursive

lint: ## Format check, tflint, checkov
	terraform fmt -check -recursive
	tflint --config "$(CURDIR)/.tflint.hcl"
	checkov --directory . --framework terraform --quiet --compact

init: ## Initialise with the local state file for ENV
	terraform init -reconfigure -backend-config="path=$(STATE)"

plan: init ## Plan the bootstrap stack for ENV
	terraform plan -var-file=$(VARS)

apply: init ## Apply the bootstrap stack for ENV (CREATE=1 required)
	@[ "$(CREATE)" = "1" ] || { echo "refusing: set CREATE=1 to apply"; exit 1; }
	terraform apply -var-file=$(VARS)

destroy: init ## Destroy the bootstrap stack for ENV (DESTROY=1 required)
	@[ "$(DESTROY)" = "1" ] || { echo "refusing: set DESTROY=1 to destroy"; exit 1; }
	terraform destroy -var-file=$(VARS)

output: init ## Print the outputs to copy into the platform repository settings
	terraform output
