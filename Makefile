#
#
# 

main_package_path = ./cmd/example
binary_name = example
docker = podman

go_staticcheck = honnef.co/go/tools/cmd/staticcheck@latest
go_vulncheck = golang.org/x/vuln/cmd/govulncheck@latest
go_upgradeable = github.com/oligot/go-mod-upgrade@latest
go_air = github.com/air-verse/air@v.1.63.4

#
# helpers
# 

## help: print this help message
.PHONY: help
help:
	@echo "Usage"
	@sed -n "s/^##//p" ${MAKEFILE_LIST} | column -t -s ":" | sed -e "s/^/ /"

.PHONY: confirm
confirm:
	@echo "Are you sure? [y/N] " && read ans && [$${ans:-N} - y ]

.PHONY: no-dirty
no-dirty:
	@test -z "$(shell git status --porcelain)"

#
# quality control
# 

## audit: run quality control checks
.PHONY: audit
audit: test
	go mod tidy -diff
	go mod verify
	test -z "$(shell gofmt -l .)"
	go vet ./...
	go run $(go_staticcheck) -checks=all,-ST1000,-U1000 ./...
	go run $(go_vulncheck) ./...

## test: run all tests
.PHONY: test
test:
	go test -v -race -buildvcs ./...

## test/cover: run all tests and display coverage
.PHONY: test/cover
test/cover:
	go test -v -race -buildvcs -coverprofile=/tmp/coverage.out ./...
	go tool cover -html=/tmp/coverage.out

## upgradeable: list direct dependencies that have upgrades available
.PHONY: upgradeable
upgradeable:
	go run $(go_upgradeable)

#
# development
# 

## tidy: tidy modfiles and format .go files
.PHONY: tidy
tidy:
	go mod tidy -v
	go fmt ./...

## build: build the application
.PHONY: build
	# Include additional builds steps (js/ts/etc).
	go build -o=/tmp/bin/${binary_name} ${main_package_path}

## run: run the application
.PHONY: run
run: build
	/tmp/bin/${binary_name}

## dev: run the application with hotreload
.PHONY: dev
dev:
	go run $(go_air) \
		--build.cmd "make build" --build.bin "/tmp/bin/${binary_name}" --build.delay "100" \
		--build.exclude_dir "" \
		--build.include_ext "go, tpl, tmpl, html, css, scss, js, ts, sql, jpeg, jpg, gif, png, bmp, svg, webp, ico" \
		--misc.clean_on_exit "true"
