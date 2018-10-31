TEST?=$$(go list ./... | grep -v vendor)
VETARGS?=-all
GOFMT_FILES?=$$(find . -name '*.go' | grep -v vendor)
GOGEN_FILES?=$$(go list ./... | grep -v vendor)
BIN_NAME?=usacloud
CURRENT_VERSION = $$(gobump show -r version/)
NEXT_VERSION?= $$(git symbolic-ref --short HEAD | sed -n -E 's/^bump-version-([0-9]+\.[0-9]+\.[0-9]+)$$/\1/p')
GO_FILES?=$(shell find . -name '*.go')
export GO111MODULE=on

BUILD_LDFLAGS = "-s -w -X github.com/sacloud/automation-sandbox/version.Revision=`git rev-parse --short HEAD`"

.PHONY: tools
tools:
	GO111MODULE=off go get -u github.com/motemen/gobump/cmd/gobump

# -----------------------------------------------
# for release
# -----------------------------------------------
.PHONY: bump-patch bump-minor bump-major
bump-patch:
	gobump patch -w version/

bump-minor:
	gobump minor -w version/

bump-major:
	gobump major -w version/

.PHONY: current-version next-version
current-version:
	@echo $(CURRENT_VERSION)

next-version:
	@echo $(NEXT_VERSION)

.PHONY: create-release-pr
create-release-pr:
	$(eval CURRENT := $(shell echo $(CURRENT_VERSION)))
	@gobump set "$(NEXT_VERSION)" -w version/ && \
	docker run --rm \
        -e APP_NAME=automation-sandbox\
        -e REPO_NAME=sacloud/automation-sandbox \
        -e ENABLE_RPM=1 \
        -e ENABLE_DEB=1 \
        -e ENABLE_PR=1 \
        -e RELEASE_FROM="$(CURRENT)" \
        -e RELEASE_TO="$(NEXT_VERSION)" \
        -e GITHUB_TOKEN \
        -v $(PWD):/workdir \
        sacloud/generate-changelog:latest

git-tag:
	git tag v$(CURRENT_VERSION)
