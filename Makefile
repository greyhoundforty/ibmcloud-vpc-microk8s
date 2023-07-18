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
all: initialize plan apply ansible-run ## Initialize, plan and apply the infrastructure and then run Ansible playbooks

.PHONY: ansible-run
ansible-run: ## Run default playbooks to test the infrastructure
	@echo "${WHITE}:: ${BLUE}Sleeping for 30 seconds to ensure cloud-init updates have completed: ${RESET} ${WHITE}::${RESET}"
	sleep 30
	@echo ""
	@echo "${BLACK}:: ${RED}Running ansible playbook to check host connectivity ${RESET} ${BLACK}::${RESET}"
	@echo ""
	ansible-playbook -i ansible/inventory.ini ansible/playbooks/ping-all.yml
	@echo ""
	@echo "${BLACK}:: ${RED}Running ansible playbook to update all systems ${RESET} ${BLACK}::${RESET}"
	@echo ""
	ansible-playbook -i ansible/inventory.ini ansible/playbooks/update-systems.yml
	@echo ""
	@echo "${BLACK}:: ${RED}Running ansible playbooks to deploy microk8s ${RESET} ${BLACK}::${RESET}"
	@echo ""
	ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy-microk8s.yml

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help