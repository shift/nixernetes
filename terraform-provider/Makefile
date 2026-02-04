NAMESPACE := anomalyco
NAME := nixernetes
VERSION := 1.0.0
BINARY := terraform-provider-${NAME}_v${VERSION}

# Go build options
GOARCH ?= $(shell go env GOARCH)
GOOS ?= $(shell go env GOOS)
INSTALL_PATH := ~/.terraform.d/plugins/registry.terraform.io/${NAMESPACE}/${NAME}/${VERSION}/${GOOS}_${GOARCH}

.PHONY: help
help:
	@echo "Terraform Provider for Nixernetes"
	@echo ""
	@echo "Available targets:"
	@echo "  build          - Build the provider binary for the current OS/architecture"
	@echo "  build-all      - Build binaries for all supported architectures"
	@echo "  build-linux    - Build binary for Linux (amd64 and arm64)"
	@echo "  build-darwin   - Build binary for macOS (amd64 and arm64)"
	@echo "  install        - Install the provider locally"
	@echo "  test           - Run go test"
	@echo "  testacc        - Run acceptance tests"
	@echo "  fmt            - Format Go code"
	@echo "  lint           - Run golangci-lint"
	@echo "  clean          - Remove build artifacts"

.PHONY: build
build:
	@echo "Building ${BINARY} for ${GOOS}/${GOARCH}..."
	go build -o bin/${BINARY} .

.PHONY: build-all
build-all: build-linux build-darwin

.PHONY: build-linux
build-linux:
	@echo "Building for Linux..."
	GOOS=linux GOARCH=amd64 go build -o bin/terraform-provider-${NAME}_v${VERSION}_linux_amd64 .
	GOOS=linux GOARCH=arm64 go build -o bin/terraform-provider-${NAME}_v${VERSION}_linux_arm64 .

.PHONY: build-darwin
build-darwin:
	@echo "Building for macOS..."
	GOOS=darwin GOARCH=amd64 go build -o bin/terraform-provider-${NAME}_v${VERSION}_darwin_amd64 .
	GOOS=darwin GOARCH=arm64 go build -o bin/terraform-provider-${NAME}_v${VERSION}_darwin_arm64 .

.PHONY: install
install: build
	@echo "Installing ${BINARY} to ${INSTALL_PATH}..."
	@mkdir -p ${INSTALL_PATH}
	@cp bin/${BINARY} ${INSTALL_PATH}/${BINARY}
	@echo "Provider installed. Update your Terraform configuration with:"
	@echo ""
	@echo "terraform {"
	@echo "  required_providers {"
	@echo "    nixernetes = {"
	@echo "      source = \"${NAMESPACE}/${NAME}\""
	@echo "      version = \"${VERSION}\""
	@echo "    }"
	@echo "  }"
	@echo "}"

.PHONY: test
test:
	go test -v -cover -timeout=5m ./...

.PHONY: testacc
testacc:
	TF_ACC=1 go test -v -cover -timeout=5m ./...

.PHONY: fmt
fmt:
	go fmt ./...
	goimports -w .

.PHONY: lint
lint:
	golangci-lint run ./...

.PHONY: clean
clean:
	@echo "Cleaning up..."
	rm -rf bin/
	go clean

.PHONY: deps
deps:
	go mod download
	go mod tidy

.PHONY: dev
dev: deps fmt build install
	@echo "Development setup complete. Provider installed to ${INSTALL_PATH}"
