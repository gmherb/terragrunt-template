SHELL := /bin/bash -exuo pipefail
PWD != pwd

# Makefile syntax
# target: req1 req2
# 	gcc -o $@ $^
# $@ = target
# $^ = req1 req2
# $* = % (wildcard match)

VERSION ?= latest
CONTAINER := alpine/terragrunt:$(VERSION)

DOCKER_ARGS := docker run \
		--interactive \
		--rm \
		--tty \
		--volume $(PWD):/apps

PLAN_OUTPUT_DIR := .tg-plans

.PHONY: list
list:
	LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: graph
graph:
	$(DOCKER_ARGS) $(CONTAINER) terragrunt dag graph | dot -Tsvg > graph.svg

# DANGER: these next three targets will run across all environments.
validate:
	$(DOCKER_ARGS) $(CONTAINER) terragrunt run --all validate | tee $@

plan: validate
	$(DOCKER_ARGS) $(CONTAINER) terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

apply: plan
	$(DOCKER_ARGS) $(CONTAINER) terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

# These next three targets will only run in the specified environment.
validate-%:
	$(DOCKER_ARGS) -w /apps/$* $(CONTAINER) terragrunt run --all validate | tee $@

plan-%: validate-%
	$(DOCKER_ARGS) -w /apps/$* $(CONTAINER) terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

apply-%: plan-%
	$(DOCKER_ARGS) -w /apps/$* $(CONTAINER) terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

# CI Steps are the same as above, but without docker since we are already running in a container
validate-ci:
	terragrunt run --all validate | tee $@

plan-ci: validate-ci
	terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

apply-ci: plan-ci
	terragrunt run --all apply --out-dir=$(PLAN_OUTPUT_DIR) | tee $@

validate-%-ci:
	cd $*/; terragrunt run --all validate | tee $(PWD)/$@

plan-%-ci: validate-%-ci
	cd $*/; terragrunt run --all plan --out-dir=$(PLAN_OUTPUT_DIR) | tee $(PWD)/$@

apply-%-ci: plan-%-ci
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
		validate-*
	rm -rf $(PLAN_OUTPUT_DIR)
	rm -f graph.svg