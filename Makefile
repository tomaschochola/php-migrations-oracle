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

# Public goals

.PHONY: fix
fix: eslint_fix php_cs_fixer_fix prettier_fix trimmer_fix

.PHONY: check
check: doctor lint analyze coverage audit

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor composer_diagnose

.PHONY: lint
lint: eslint_check php_cs_fixer_check prettier_check trimmer_check

.PHONY: analyze
analyze: npm_check composer_check phpstan_check

.PHONY: test
test: phpunit_test

.PHONY: coverage
coverage: phpunit_coverage

.PHONY: audit
audit: npm_audit composer_audit

.PHONY: update
update: npm_config_check ./package.json ./package-lock.json ./composer.json ./composer.lock npm_update composer_update

.PHONY: clean
clean:
	rm --force --recursive --one-file-system -- ./.php-cs-fixer.cache ./.phpstan.cache ./.phpunit.cache ./.phpunit.coverage

.PHONY: distclean
distclean: clean deps_clean

.PHONY: postcreate
postcreate: deps_install

.PHONY: up
up: devcontainer_check
	devcontainer up --workspace-folder .

.PHONY: shell
shell: up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop:
	docker container ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container stop "$$container"; done

.PHONY: down
down: stop
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container rm "$$container"; done

.PHONY: rebuild
rebuild: devcontainer_check down
	devcontainer up --workspace-folder . --build-no-cache

# Protected goals

.PHONY: deps_install
deps_install: npm_install composer_install

.PHONY: deps_clean
deps_clean: npm_clean composer_clean

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer fix .

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer check .

.PHONY: eslint_fix
eslint_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./eslint.config.js
	npm exec --no --ignore-scripts -- eslint --concurrency=auto --fix .

.PHONY: eslint_check
eslint_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./eslint.config.js
	npm exec --no --ignore-scripts -- eslint --concurrency=auto .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -w .

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -c .

.PHONY: php_cs_fixer_fix
php_cs_fixer_fix: ./vendor/autoload.php ./composer.json ./composer.lock ./.php-cs-fixer.php
	composer exec --no-plugins --no-scripts -- php-cs-fixer fix

.PHONY: php_cs_fixer_check
php_cs_fixer_check: ./vendor/autoload.php ./composer.json ./composer.lock ./.php-cs-fixer.php
	composer exec --no-plugins --no-scripts -- php-cs-fixer check

.PHONY: phpstan_check
phpstan_check: ./vendor/autoload.php ./composer.json ./composer.lock ./phpstan.neon
	composer exec --no-plugins --no-scripts -- phpstan analyse

.PHONY: phpunit_test
phpunit_test: ./vendor/autoload.php ./phpunit.xml
	composer exec --no-plugins --no-scripts -- phpunit --no-coverage

.PHONY: phpunit_coverage
phpunit_coverage: ./vendor/autoload.php ./phpunit.xml
	composer exec --no-plugins --no-scripts -- phpunit

.PHONY: npm_config_check
npm_config_check: ./.npmrc
	test "$$(npm config get ignore-scripts)" = "true"
	test "$$(npm config get allow-directory)" = "root"
	test "$$(npm config get allow-file)" = "root"
	test "$$(npm config get allow-git)" = "root"
	test "$$(npm config get allow-remote)" = "root"
	test "$$(npm config get audit)" = "false"
	test "$$(npm config get strict-ssl)" = "true"
	test "$$(npm config get registry)" = "https://registry.npmjs.org/"

.PHONY: npm_doctor
npm_doctor:
	npm doctor connection registry environment permissions cache

.PHONY: npm_check
npm_check: npm_config_check ./node_modules/.package-lock.json
	npm ci --dry-run --ignore-scripts --audit=false --install-links --include=prod --include=dev --include=peer --include=optional
	npm ls --all --install-links --include=prod --include=dev --include=peer --include=optional >/dev/null

.PHONY: npm_audit
npm_audit: npm_config_check ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=moderate --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_install
npm_install: npm_config_check ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: npm_config_check ./package.json ./package-lock.json npm_clean
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_clean
npm_clean:
	rm --force --recursive --one-file-system -- ./node_modules

.PHONY: composer_diagnose
composer_diagnose:
	composer diagnose --no-plugins --no-scripts

.PHONY: composer_check
composer_check: ./vendor/autoload.php ./composer.json ./composer.lock
	composer validate --no-plugins --no-scripts --strict --with-dependencies --check-lock
	composer check-platform-reqs --no-plugins --no-scripts
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous --dry-run

.PHONY: composer_audit
composer_audit: ./vendor/autoload.php ./composer.json ./composer.lock
	composer audit --no-plugins --no-scripts

.PHONY: composer_install
composer_install: ./composer.json ./composer.lock
	composer install --no-plugins --no-scripts --no-autoloader
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: composer_update
composer_update: ./composer.json ./composer.lock composer_clean
	composer update --no-plugins --no-scripts --no-autoloader --with-all-dependencies
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: composer_clean
composer_clean:
	rm --force --recursive --one-file-system -- ./vendor

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

# Private targets

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install

./vendor/autoload.php: ./composer.json ./composer.lock
	$(MAKE) composer_install
