-include .env
export
SHELL := /bin/bash
PWD := $(shell pwd)

TMP_DIR := $(PWD)/TMP
NODE := $(TMP_DIR)/node/bin/
NODE_BIN:= $(TMP_DIR)/node/bin/node
N8N_GIT_REPO := https://github.com/n8n-io/n8n
PATH := $(NODE):$(PATH)
CURRENT_DATE := $(shell date '+%Y_%m_%d_%H_%M_%S')
N8N_PROJECT_DIR := $(TMP_DIR)/n8n
N8N_NODE_VERSION := 22.21.1
CRANE_VERSION := 0.20.7
CRANE_BIN := $(TMP_DIR)/crane/crane
PNPM_VERSION := 10.26.2
PNPM_BIN := $(TMP_DIR)/pnpm/pnpm
N8N_VERSION := 2.1.4
N8N_IMAGES_REPO := redacid
#POSTFIX := -slim
LOCAL_IMAGES_REPO := localhost:5000
N8N_IMAGES_BASE_NAME := n8n-playwright

N8N_BASE_IMAGE := $(LOCAL_IMAGES_REPO)/$(N8N_IMAGES_BASE_NAME):$(N8N_NODE_VERSION)-base$(POSTFIX)
N8N_IMAGE := $(LOCAL_IMAGES_REPO)/$(N8N_IMAGES_BASE_NAME):$(N8N_VERSION)-n8n$(POSTFIX)
N8N_RUNNERS_IMAGE := $(LOCAL_IMAGES_REPO)/$(N8N_IMAGES_BASE_NAME):$(N8N_VERSION)-runners$(POSTFIX)

EXT_BASE_IMAGE := $(N8N_IMAGES_REPO)/$(N8N_IMAGES_BASE_NAME):$(N8N_NODE_VERSION)-base$(POSTFIX)
EXT_IMAGE := $(N8N_IMAGES_REPO)/$(N8N_IMAGES_BASE_NAME)$(POSTFIX):$(N8N_VERSION)-n8n$(POSTFIX)
EXT_RUNNERS_IMAGE := $(N8N_IMAGES_REPO)/$(N8N_IMAGES_BASE_NAME):$(N8N_VERSION)-runners$(POSTFIX)

# colors
GREEN = $(shell tput -Txterm setaf 2)
YELLOW = $(shell tput -Txterm setaf 3)
WHITE = $(shell tput -Txterm setaf 7)
RESET = $(shell tput -Txterm sgr0)
GRAY = $(shell tput -Txterm setaf 6)
TARGET_MAX_CHAR_NUM = 30

.EXPORT_ALL_VARIABLES:

.PHONY: all
## Default target
all: help

.ONESHELL:
.PHONY: create-volume-dirs
## Create n8n db volumes
create-volume-dirs:
	mkdir -p $(N8N_VOLUME_PATH) || true;
	chmod 777 $(N8N_VOLUME_PATH) || true;
	mkdir -p $(DB_VOLUME_PATH) || true;
	chmod 777 $(DB_VOLUME_PATH) || true;

.ONESHELL:
.PHONY: docker-compose-up
## Compose Up | Compose
docker-compose-up: create-volume-dirs
	docker compose up -d

.ONESHELL:
.PHONY: docker-compose-stop
## Compose Stop
docker-compose-stop:
	docker compose stop

.ONESHELL:
.PHONY: docker-compose-down
## Compose Down
docker-compose-down:
	docker compose down

.ONESHELL:
.PHONY: cleanup
## Make dirs | Prepare
cleanup:
	rm -rf $(TMP_DIR)

.ONESHELL:
.PHONY: get-node
## Download node | Download
get-node:
	mkdir -p $(TMP_DIR)/node
	wget https://nodejs.org/dist/v$(N8N_NODE_VERSION)/node-v$(N8N_NODE_VERSION)-linux-x64.tar.xz -O $(TMP_DIR)/node.tar.xz
	tar -xf $(TMP_DIR)/node.tar.xz -C $(TMP_DIR)/node --strip-components=1
	rm $(TMP_DIR)/node.tar.xz
	#export PATH="$(TMP_DIR)/node/bin:$(PATH)"

.ONESHELL:
.PHONY: get-crane
## Download crane
get-crane:
	mkdir -p $(TMP_DIR)/crane
	wget https://github.com/google/go-containerregistry/releases/download/v$(CRANE_VERSION)/go-containerregistry_Linux_x86_64.tar.gz -O $(TMP_DIR)/crane.tar.gz
	tar -xzf $(TMP_DIR)/crane.tar.gz -C $(TMP_DIR)/crane
	rm $(TMP_DIR)/crane.tar.gz

.ONESHELL:
.PHONY: get-pnpm
## Download pnpm
get-pnpm:
	mkdir -p $(TMP_DIR)/pnpm
	wget https://github.com/pnpm/pnpm/releases/download/v$(PNPM_VERSION)/pnpm-linux-x64 -O $(TMP_DIR)/pnpm/pnpm
	chmod +x $(TMP_DIR)/pnpm/pnpm

.ONESHELL:
.PHONY: clone-n8n-repo
## Clone n8n repo | Clone
clone-n8n-repo: cleanup
	mkdir -p $(TMP_DIR)
	cd $(TMP_DIR)
	git clone $(N8N_GIT_REPO)
	cd $(N8N_PROJECT_DIR) && git pull && git fetch --all
	git checkout n8n@$(N8N_VERSION) || true
	git describe --tags

.ONESHELL:
.PHONY: build-all
## Build All Images | Build
build-all: build-n8n build-base-image build-n8n-image build-runners-image crane-flatten #registry-push #registry-stop


.ONESHELL:
.PHONY: build-n8n
## Build n8n
build-n8n: clone-n8n-repo get-node get-pnpm
	cd $(N8N_PROJECT_DIR)
	export PATH=$(NODE):$(PATH)
	$(PNPM_BIN) install
	$(PNPM_BIN) run build
	$(PNPM_BIN) run build:n8n

.ONESHELL:
.PHONY: build-base-image
## Build base image
build-base-image:
	docker --debug buildx build -f ./images/n8n-base/Dockerfile -t $(N8N_BASE_IMAGE) $(N8N_PROJECT_DIR)

.ONESHELL:
.PHONY: build-n8n-image
## Build n8n image
build-n8n-image: build-base-image
	docker --debug buildx build \
		--build-arg N8N_BASE_IMAGE="$(N8N_BASE_IMAGE)" \
		--build-arg N8N_VERSION=$(N8N_VERSION) \
		-f ./images/n8n/Dockerfile \
		-t $(N8N_IMAGE) $(N8N_PROJECT_DIR)

.ONESHELL:
.PHONY: build-runners-image
## Build runners image
build-runners-image:
	cp ./images/runners/n8n-task-runners.json $(N8N_PROJECT_DIR)/docker/images/runners/n8n-task-runners.json
	docker --debug buildx build -f ./images/runners/Dockerfile -t $(N8N_RUNNERS_IMAGE) $(N8N_PROJECT_DIR)


.ONESHELL:
.PHONY: registry-start
## Start local registry
registry-start:
	docker run -d -p 5000:5000 --rm --name local-registry registry:2

.ONESHELL:
.PHONY: registry-stop
## Stop local registry
registry-stop:
	docker stop local-registry

.ONESHELL:
.PHONY: registry-push
## Build runners image | Push
registry-push:
	docker push $(N8N_BASE_IMAGE)
	docker push $(N8N_IMAGE)
	docker push $(N8N_RUNNERS_IMAGE)

.ONESHELL:
.PHONY: crane-flatten
## Build runners image | Push
crane-flatten: get-crane registry-start registry-push
	@echo $(DOCKER_PASS) | docker login --username $(DOCKER_USER) --password-stdin
	$(CRANE_BIN) flatten $(N8N_BASE_IMAGE) -t $(EXT_BASE_IMAGE)
	$(CRANE_BIN) flatten $(N8N_IMAGE) -t $(EXT_IMAGE)
	$(CRANE_BIN) flatten $(N8N_RUNNERS_IMAGE) -t $(EXT_RUNNERS_IMAGE)
	make registry-stop
	#curl http://localhost:5000/v2/_catalog
	#curl http://localhost:5000/v2/$(N8N_IMAGES_BASE_NAME)-base/tags/list
	#curl http://localhost:5000/v2/$(N8N_IMAGES_BASE_NAME)/tags/list
	#curl http://localhost:5000/v2/$(N8N_IMAGES_BASE_NAME)-runners/tags/list

.PHONY: help
## Shows help | Help
help:
	@echo ''
	@echo 'Usage:'
	@echo ''
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z0-9\-_]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
		    if (index(lastLine, "|") != 0) { \
				stage = substr(lastLine, index(lastLine, "|") + 1); \
				printf "\n ${GRAY}%s: \n\n", stage;  \
			} \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			if (index(lastLine, "|") != 0) { \
				helpMessage = substr(helpMessage, 0, index(helpMessage, "|")-1); \
			} \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@echo ''



