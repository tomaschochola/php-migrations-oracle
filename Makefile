# Default shell
SHELL := /bin/bash

# Default goal
.DEFAULT_GOAL := never

# Options
export DEBIAN_FRONTEND := noninteractive
export PHP_CS_FIXER_FUTURE_MODE := 1

# Goals
.PHONY: commit
commit: distclean update fix check

.PHONY: fix
fix: eslint_fix prettier_fix php_cs_fixer_fix yq_fix

.PHONY: check
check: lint stan test audit

.PHONY: lint
lint: eslint_check prettier_check php_cs_fixer_check

.PHONY: stan
stan: phpstan_check

.PHONY: test
test: phpunit_test

.PHONY: coverage
coverage: ./.phpunit.coverage/html
	php -S 0.0.0.0:8000 -t ./.phpunit.coverage/html

.PHONY: audit
audit: npm_audit composer_audit

.PHONY: install
install: npm_install composer_install

.PHONY: update
update: npm_update composer_update

.PHONY: clean
clean:
	rm -rf ./.php-cs-fixer.cache
	rm -rf ./.phpunit.cache
	rm -rf ./.phpunit.coverage
	rm -rf ./.phpunit.result.cache
	rm -rf ./node_modules
	rm -rf ./vendor

.PHONY: distclean
distclean: clean
	git clean -Xfd

.PHONY: eslint_fix
eslint_fix: ./node_modules ./eslint.config.js
	npm exec --ignore-scripts -- eslint --concurrency=auto --fix .

.PHONY: prettier_fix
prettier_fix: ./node_modules ./prettier.config.js
	npm exec --ignore-scripts -- prettier -w .

.PHONY: php_cs_fixer_fix
php_cs_fixer_fix: ./vendor ./.php-cs-fixer.php
	composer exec --no-plugins --no-scripts -- php-cs-fixer fix

.PHONY: yq_fix
yq_fix:
	find . -type f -name "*.yml" -exec yq -i 'sort_keys(..)' {} \;

.PHONY: eslint_check
eslint_check: ./node_modules ./eslint.config.js
	npm exec --ignore-scripts -- eslint --concurrency=auto .

.PHONY: prettier_check
prettier_check: ./node_modules ./prettier.config.js
	npm exec --ignore-scripts -- prettier -c .

.PHONY: php_cs_fixer_check
php_cs_fixer_check: ./vendor ./.php-cs-fixer.php
	composer exec --no-plugins --no-scripts -- php-cs-fixer check

.PHONY: phpstan_check
phpstan_check: ./vendor ./phpstan.neon
	composer exec --no-plugins --no-scripts -- phpstan analyse

.PHONY: phpunit_test
phpunit_test: ./vendor ./phpunit.xml
	composer exec --no-plugins --no-scripts -- phpunit

.PHONY: npm_audit
npm_audit: ./node_modules ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=critical --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_audit
composer_audit: ./vendor ./composer.json ./composer.lock
	composer audit --no-plugins --no-scripts
	composer check-platform-reqs --no-plugins --no-scripts
	composer validate --no-plugins --no-scripts --strict --with-dependencies --check-lock
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: npm_install
npm_install: ./package.json ./package-lock.json
	npm install --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_install
composer_install: ./composer.json ./composer.lock
	composer install --no-plugins --no-scripts --no-autoloader
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: npm_update
npm_update: ./package.json
	rm -rf ./node_modules
	rm -rf ./package-lock.json
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_update
composer_update: ./composer.json
	rm -rf ./vendor
	rm -rf ./composer.lock
	composer update --no-plugins --no-scripts --no-autoloader --with-all-dependencies
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: precreate
precreate:
	docker volume create tomaschochola-composer-cache >/dev/null
	docker volume create tomaschochola-npm-cache >/dev/null

.PHONY: postcreate
postcreate: install

.PHONY: devcontainer
devcontainer: precreate
	devcontainer up
	devcontainer exec /bin/bash || true
	docker ps -q --filter "label=devcontainer.local_folder=$${PWD}" | xargs -r docker stop

.PHONY: prune
prune:
	@projects="$$(docker ps -aq --filter "label=devcontainer.local_folder=$${PWD}" | xargs -r docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u)"; for project in $$projects; do docker ps -aq --filter "label=com.docker.compose.project=$$project" | xargs -r docker rm -f; done; docker ps -aq --filter "label=devcontainer.local_folder=$${PWD}" | xargs -r docker rm -f

.PHONY: fresh
fresh: prune devcontainer

# Dependencies
./.phpunit.coverage/html:
	${MAKE} phpunit_test

./composer.lock ./vendor: ./composer.json
	${MAKE} composer_update

./package-lock.json ./node_modules: ./package.json
	${MAKE} npm_update
