UNAME:= $(shell uname)
ifeq ($(UNAME),Darwin)
		OS_X  := true
		SHELL := /bin/zsh
else
		OS_DEB  := true
		SHELL := /bin/bash
endif

# define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0)
	RED          := $(shell tput -Txterm setaf 1)
	GREEN        := $(shell tput -Txterm setaf 2)
	YELLOW       := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
	PURPLE       := $(shell tput -Txterm setaf 5)
	BLUE         := $(shell tput -Txterm setaf 6)
	WHITE        := $(shell tput -Txterm setaf 7)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif

# set target color
TARGET_COLOR := $(BLUE)

colors: ## show all the colors
	@echo "${BLACK}BLACK${RESET}"
	@echo "${RED}RED${RESET}"
	@echo "${GREEN}GREEN${RESET}"
	@echo "${YELLOW}YELLOW${RESET}"
	@echo "${LIGHTPURPLE}LIGHTPURPLE${RESET}"
	@echo "${PURPLE}PURPLE${RESET}"
	@echo "${BLUE}BLUE${RESET}"
	@echo "${WHITE}WHITE${RESET}"


.PHONY: initialize
initialize: ## Initialize Terraform configuration, format HCL and run validate
	@echo ""
	@echo "${BLACK}:: ${RED}Running a fmt, init, and validate on current environment${RESET} ${BLACK}::${RESET}"
	@echo ""
	terraform fmt -recursive
	terraform init -upgrade=true
	terraform validate

.PHONY: validate
validate: ## Runs a format and validation check on the configuration files in a directory
	terraform fmt -recursive
	terraform validate

.PHONY: fmt
fmt: ## Rewrites config to canonical format
	terraform fmt -recursive

.PHONY: plan
plan: ## Run a terraform plan against current workspace and save it to a file
	@echo ""
	@echo "${BLACK}[:: ${RED}Running a plan on current environment${RESET} ${BLACK}::]${RESET}"
	@echo ""
	terraform plan -out "$$(terraform workspace show).tfplan"

.PHONY: apply
apply: ## Run a terraform apply on previously saved plan file
	@echo ""
	@echo "${BLACK}:: ${RED}Running an apply on previously saved plan${RESET} ${BLACK}::${RESET}"
	@echo ""
	terraform apply "$$(terraform workspace show).tfplan"

.PHONY: reset
reset: ## Clean up the local state and destroy the infrastructure
	@echo ""
	@echo "${BLACK}:: ${RED}Cleaning up terraform envionrment${RESET} ${BLACK}::${RESET}"
	@echo ""
	terraform destroy -auto-approve
	rm -rf .terraform
	rm -rf .terraform.lock.hcl
	rm -rf terraform.tfstate
	rm -rf terraform.tfstate.backup
	rm -rf *.tfplan

.PHONY: all
all: initialize plan apply ## Initialize, plan and apply the infrastructure

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

# plan:
# 	@bash terraform validate
# 	@bash terraform plan -out "$$(terraform workspace show).tfplan"

# apply:
# 	@bash terraform apply "$$(terraform workspace show).tfplan"

# destroy:
# 	@bash terraform destroy -auto-approve

# all: validate plan apply


# .PHONY: fmt
# fmt: ## Rewrites config to canonical format
# 	@bash $(dir $(mkfile_path))/terraform.sh fmt $(args)

# .PHONY: lint
# lint: ## Lint the HCL code
# 	@bash $(dir $(mkfile_path))/terraform.sh fmt -diff=true -check $(args) $(RUN_ARGS)

# .PHONY: validate
# validate: ## Basic syntax check
# 	@bash $(dir $(mkfile_path))/terraform.sh validate $(args) $(RUN_ARGS)

# .PHONY: show
# show: ## List infra resources
# 	@bash $(dir $(mkfile_path))/terraform.sh show $(args) $(RUN_ARGS)

# .PHONY: refresh
# refresh: ## Refresh infra resources
# 	@bash $(dir $(mkfile_path))/terraform.sh refresh $(args) $(RUN_ARGS)

# .PHONY: console
# console: ## Console infra resources
# 	@bash $(dir $(mkfile_path))/terraform.sh console $(args) $(RUN_ARGS)

# .PHONY: import
# import: ## Import infra resources
# 	@bash $(dir $(mkfile_path))/terraform.sh import $(args) $(RUN_ARGS)

# .PHONY: taint
# taint: ## Taint infra resources
# 	bash $(dir $(mkfile_path))terraform.sh taint -module=$(module) $(args) $(RUN_ARGS)

# .PHONY: untaint
# untaint: ## Untaint infra resources
# 	bash $(dir $(mkfile_path))terraform.sh untaint -module=$(module) $(args) $(RUN_ARGS)

# .PHONY: workspace
# workspace: ## Workspace infra resources
# 	bash $(dir $(mkfile_path))terraform.sh workspace $(args) $(RUN_ARGS)

# .PHONY: state
# state: ## Inspect or change the remote state of your resources
# 	@bash $(dir $(mkfile_path))/terraform.sh state $(args) $(RUN_ARGS)

# .PHONY: plan
# plan: dry-run
# .PHONY: dry-run
# dry-run: install ## Dry run resources changes
# ifndef landscape
# 	@bash $(dir $(mkfile_path))/terraform.sh plan $(args) $(RUN_ARGS)
# else
# 	@bash $(dir $(mkfile_path))/terraform.sh plan $(args) $(RUN_ARGS) | landscape
# endif

# .PHONY: apply
# apply: run
# .PHONY: run
# run: ## Execute resources changes
# 	@bash $(dir $(mkfile_path))/terraform.sh apply $(args) $(RUN_ARGS)

# .PHONY: destroy
# destroy: ## Destroy resources
# 	@bash $(dir $(mkfile_path))/terraform.sh destroy $(args) $(RUN_ARGS)

# .PHONY: raw
# raw: ## Raw command sent to terraform
# 	@bash $(dir $(mkfile_path))/terraform.sh $(RUN_ARGS) $(args)
