SHELL := /bin/bash -exuo pipefail
PWD != pwd

BASE_VERSION ?= latest
BASE_IMAGE ?= alpine/terragrunt:$(BASE_VERSION)

BUILD_TAG != git rev-parse --short HEAD
BUILD_IMAGE ?= gmherb/terragrunt-template:$(BUILD_TAG)

CONTAINER ?= $(BUILD_IMAGE) #$(BASE_IMAGE)
DOCKER_ARGS := docker run \
		--interactive \
		--rm \
		--tty \
		--volume $(PWD):/apps \
		--user $(shell id -u):$(shell id -g)

PLAN_OUTPUT_DIR ?= .tg-plans
PLAN_FILES != find . -name tfplan.tfplan
CACHE_DIRS != find . -name .terragrunt-cache | xargs -I {} dirname {} | sed 's/.\///'

.PHONY: list
list:
	@awk -F: '/^[a-zA-Z0-9][^$#\/\t=]*:/ {print $$1}' $(MAKEFILE_LIST) | sort | uniq

.PHONY: build
build:
	docker buildx build --platform linux/amd64 -t $(BUILD_IMAGE) -f Dockerfile .

.PHONY: shell
shell:
	$(DOCKER_ARGS) $(CONTAINER) bash

.PHONY: fmt
fmt:
	$(DOCKER_ARGS) $(CONTAINER) terragrunt hcl fmt
	$(DOCKER_ARGS) $(CONTAINER) terraform fmt -recursive

.PHONY: version
version:
	$(DOCKER_ARGS) $(CONTAINER) terraform --version
	$(DOCKER_ARGS) $(CONTAINER) terragrunt --version

.PHONY: info
info:
	$(DOCKER_ARGS) $(CONTAINER) terragrunt info print

.PHONY: graph
graph:
	$(DOCKER_ARGS) $(CONTAINER) terragrunt dag graph | dot -Tsvg > graph.svg

.PHONY: show
show:
	$(foreach var,$(PLAN_FILES), $(DOCKER_ARGS) -w /apps $(CONTAINER) bash -c "cd $(shell dirname $(var)) && terraform show";)

.PHONY: show-cache
show-cache:
	$(foreach var,$(CACHE_DIRS), $(DOCKER_ARGS) -w /apps $(CONTAINER) bash -c "cd ./$(var)/.terragrunt-cache/*/*/ && terraform show ../../../../.tg-plans/$(shell basename $(var))/tfplan.tfplan";)

.PHONY: render-json
render-json:
	$(foreach var,$(CACHE_DIRS), $(DOCKER_ARGS) -w /apps $(CONTAINER) bash -c "cd ./$(var)/.terragrunt-cache/*/*/ && terragrunt render --json -w";)

# DANGER: these next three targets will run across all environments.
validate:
	$(DOCKER_ARGS) $(CONTAINER) terragrunt run --all validate | tee $@

plan: validate
	$(DOCKER_ARGS) $(CONTAINER) terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

apply: plan
	scripts/abort_on_destroy.sh $(PLAN_OUTPUT_DIR)
	$(DOCKER_ARGS) $(CONTAINER) terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

# These next three targets will only run in the specified environment.
validate-%:
	$(DOCKER_ARGS) -w /apps/$* $(CONTAINER) terragrunt run --all validate | tee $@

plan-%: validate-%
	$(DOCKER_ARGS) -w /apps/$* $(CONTAINER) terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

apply-%: plan-%
	scripts/abort_on_destroy.sh $(PLAN_OUTPUT_DIR)
	$(DOCKER_ARGS) -w /apps/$* $(CONTAINER) terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

# CI Steps are the same as above, but without docker since we are already running in a container
validate-ci:
	terragrunt run --all validate | tee $@

plan-ci: validate-ci
	terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

apply-ci: plan-ci
	scripts/abort_on_destroy.sh $(PLAN_OUTPUT_DIR)
	terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

validate-%-ci:
	cd $*/; terragrunt run --all validate | tee $(PWD)/$@

plan-%-ci: validate-%-ci
	cd $*/; terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $(PWD)/$@

apply-%-ci: plan-%-ci
	scripts/abort_on_destroy.sh $(PLAN_OUTPUT_DIR)
	cd $*/; terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $(PWD)/$@

.PHONY: clean
clean:
	find . -name .terragrunt-cache | xargs rm -rf
	rm -f \
		apply \
		apply-* \
		plan \
		plan-* \
		validate \
		validate-* \
		graph.svg
	rm -rf $(PLAN_OUTPUT_DIR) \
	    dev/$(PLAN_OUTPUT_DIR) \
	    prod/$(PLAN_OUTPUT_DIR)

.PHONY: slack-notification
slack-notification:
	scripts/slack_notification.sh
