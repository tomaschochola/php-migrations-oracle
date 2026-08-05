# Makefile

SHELL := /usr/bin/env bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:

# Default goal

.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Run an explicit target' >&2
	exit 1

# Options

DEVCONTAINER_FILTER := label=devcontainer.local_folder=$(CURDIR)

export PHP_CS_FIXER_FUTURE_MODE := 1

# Goals

.PHONY: fix
fix: eslint_fix prettier_fix php_cs_fixer_fix trimmer_fix

.PHONY: check
check: trimmer_check composer_diagnose lint static test audit

.PHONY: lint
lint: eslint_check prettier_check php_cs_fixer_check

.PHONY: static
static: phpstan_check composer_autoload_check

.PHONY: test
test: phpunit_test

.PHONY: coverage
coverage: phpunit_test

.PHONY: coverage_serve
coverage_serve: coverage
	php -S 0.0.0.0:8000 -t ./.phpunit.coverage/html

.PHONY: audit
audit: npm_audit composer_audit

.PHONY: deps_install
deps_install: npm_install composer_install

.PHONY: deps_update
deps_update: npm_update composer_update

.PHONY: clean
clean:
	rm -rf ./.php-cs-fixer.cache
	rm -rf ./.phpstan.cache
	rm -rf ./.phpunit.cache
	rm -rf ./.phpunit.coverage

.PHONY: deps_clean
deps_clean: npm_deps_clean composer_deps_clean

.PHONY: npm_deps_clean
npm_deps_clean:
	rm -rf ./node_modules

.PHONY: composer_deps_clean
composer_deps_clean:
	rm -rf ./vendor

.PHONY: distclean
distclean: clean deps_clean

.PHONY: nuke
nuke: down distclean

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --ignore-scripts -- trimmer fix .

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --ignore-scripts -- trimmer check .

.PHONY: eslint_fix
eslint_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./eslint.config.js
	npm exec --ignore-scripts -- eslint --concurrency=auto --fix .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --ignore-scripts -- prettier -w .

.PHONY: php_cs_fixer_fix
php_cs_fixer_fix: ./vendor/autoload.php ./composer.json ./composer.lock ./.php-cs-fixer.php
	composer exec --no-plugins --no-scripts -- php-cs-fixer fix

.PHONY: eslint_check
eslint_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./eslint.config.js
	npm exec --ignore-scripts -- eslint --concurrency=auto .

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --ignore-scripts -- prettier -c .

.PHONY: php_cs_fixer_check
php_cs_fixer_check: ./vendor/autoload.php ./composer.json ./composer.lock ./.php-cs-fixer.php
	composer exec --no-plugins --no-scripts -- php-cs-fixer check

.PHONY: phpstan_check
phpstan_check: ./vendor/autoload.php ./composer.json ./composer.lock ./phpstan.neon
	composer exec --no-plugins --no-scripts -- phpstan analyse

.PHONY: phpunit_test
phpunit_test: ./vendor/autoload.php ./phpunit.xml
	composer exec --no-plugins --no-scripts -- phpunit

.PHONY: npm_audit
npm_audit: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=high --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_audit
composer_audit: ./vendor/autoload.php ./composer.json ./composer.lock
	composer audit --no-plugins --no-scripts
	composer check-platform-reqs --no-plugins --no-scripts
	composer validate --no-plugins --no-scripts --strict --with-dependencies --check-lock

.PHONY: composer_diagnose
composer_diagnose: ./composer.json ./composer.lock
	composer diagnose --no-plugins --no-scripts

.PHONY: composer_autoload_check
composer_autoload_check: ./vendor/autoload.php ./composer.json ./composer.lock
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous --dry-run

.PHONY: npm_install
npm_install: ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_install
composer_install: ./composer.json ./composer.lock
	composer install --no-plugins --no-scripts --no-autoloader
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: npm_update
npm_update: npm_deps_clean ./package.json
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_update
composer_update: composer_deps_clean ./composer.json
	composer update --no-plugins --no-scripts --no-autoloader --with-all-dependencies
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: postcreate
postcreate: deps_install

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

.PHONY: up
up: devcontainer_check
	devcontainer up --workspace-folder .

.PHONY: devcontainer
devcontainer: up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: status
status:
	docker container ls --all --filter "$(DEVCONTAINER_FILTER)"

.PHONY: stop
stop:
	docker container ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container stop "$$container"; done

.PHONY: restart
restart:
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container restart "$$container"; done

.PHONY: down
down: stop
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container rm --volumes "$$container"; done

.PHONY: rebuild
rebuild: devcontainer_check down
	devcontainer up --workspace-folder .

.PHONY: rebuild_no_cache
rebuild_no_cache: devcontainer_check down
	devcontainer up --workspace-folder . --build-no-cache

./vendor/autoload.php: ./composer.json ./composer.lock
	$(MAKE) composer_install

./node_modules/.package-lock.json: ./package.json ./package-lock.json
	$(MAKE) npm_install
