# AGENTS.md

## Development environment

The development environment is configured in `.devcontainer/`. Manage it from the repository root on the host using the Makefile targets or directly through the `devcontainer`, `docker` and `docker compose` CLIs.

- `devcontainer`: `php` 8.5.11 — Run development tools and workspace commands.
- `wiremock`: `wiremock/wiremock` 3.13.2 — Mock HTTP APIs for automated tests.

```sh
# start the development environment
make up

# run a workspace command
devcontainer exec --workspace-folder . COMMAND ARG...

# run a shell command
devcontainer exec --workspace-folder . bash -c 'COMMAND ARG... | COMMAND ARG...'

# run a sidecar command
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE COMMAND ARG...
```

## EditorConfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 4
indent_style = space
insert_final_newline = true
max_line_length = 200
trim_trailing_whitespace = true

[*.go]
indent_size = tab
indent_style = tab
tab_width = 8

[*.ini]
max_line_length = off

[*.md]
indent_size = unset
indent_style = unset
max_line_length = off

[*.txt]
indent_size = unset
indent_style = unset
max_line_length = off

[LICENSE]
indent_size = unset
indent_style = unset
max_line_length = off

[Makefile]
indent_style = tab
max_line_length = off
```

## Repository layout

```text
.
|-- .devcontainer/
|   |-- .dockerignore
|   |-- Dockerfile
|   |-- devcontainer.json
|   |-- docker-compose.yml
|   `-- ...
|-- .editorconfig
|-- .gitattributes
|-- .gitignore
|-- .npmrc
|-- .php-cs-fixer.php
|-- .prettierignore
|-- AGENTS.md
|-- AUTHORS.md
|-- LICENSE
|-- Makefile
|-- composer.json
|-- composer.lock
|-- eslint.config.js
|-- package-lock.json
|-- package.json
|-- phpstan.neon
|-- phpunit.xml
|-- prettier.config.js
|-- src/
|   `-- ...
`-- tests/
    `-- ...
```

## Makefile targets

- `never`: Require an explicit target.
- `fix`: `eslint_fix` + `php_cs_fixer_fix` + `prettier_fix` + `trimmer_fix`
- `check`: `devcontainer_gate` + `doctor` + `lint` + `analyze` + `coverage` + `audit`
- `doctor`: `git_check` + `npm_config_check` + `npm_doctor` + `npm_check` + `composer_diagnose`
- `lint`: `eslint_check` + `php_cs_fixer_check` + `prettier_check` + `trimmer_check`
- `analyze`: `npm_check` + `composer_check` + `phpstan_check`
- `test`: `devcontainer_gate` + `phpunit_test`
- `coverage`: `devcontainer_gate` + `phpunit_coverage`
- `audit`: `npm_audit` + `composer_audit`
- `update`: `npm_config_check` + `npm_update` + `composer_update`
- `clean`: Remove generated project files.
- `distclean`: `clean` + `deps_clean`
- `postcreate`: `deps_install`
- `up`: `host_gate` + `devcontainer_check` — Start the development environment.
- `shell`: `interactive_gate` + `host_gate` + `up` — Open a shell in the development environment.
- `stop`: `host_gate` — Stop the development environment.
- `down`: `host_gate` — Remove the development environment.
- `rebuild`: `host_gate` + `devcontainer_check` + `down` — Rebuild the development environment.
- `nuke`: `distclean` + `prune`
- `prune`: `host_gate` — Remove project container resources.
- `host_gate`: Require execution on the host.
- `devcontainer_gate`: Require execution in a Docker container.
- `interactive_gate`: Require an interactive terminal.
- `deps_install`: `npm_install` + `composer_install`
- `deps_clean`: `npm_clean` + `composer_clean`
- `trimmer_fix`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` — Fix whitespace formatting.
- `trimmer_check`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` — Check whitespace formatting.
- `eslint_fix`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` + `./eslint.config.js` — Fix JavaScript and TypeScript lint findings.
- `eslint_check`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` + `./eslint.config.js` — Check JavaScript and TypeScript code with ESLint.
- `prettier_fix`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` + `./prettier.config.js` — Format files with Prettier.
- `prettier_check`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` + `./prettier.config.js` — Check formatting with Prettier.
- `php_cs_fixer_fix`: `./vendor/autoload.php` + `./composer.json` + `./composer.lock` + `./.php-cs-fixer.php` — Format PHP code.
- `php_cs_fixer_check`: `./vendor/autoload.php` + `./composer.json` + `./composer.lock` + `./.php-cs-fixer.php` — Check PHP code formatting.
- `phpstan_check`: `./vendor/autoload.php` + `./composer.json` + `./composer.lock` + `./phpstan.neon` — Analyze PHP code with PHPStan.
- `phpunit_test`: `./vendor/autoload.php` + `./phpunit.xml` — Run PHP unit tests.
- `phpunit_coverage`: `./vendor/autoload.php` + `./phpunit.xml` — Measure PHP test coverage.
- `npm_config_check`: `./.npmrc` — Check npm configuration.
- `npm_doctor`: Check the npm environment.
- `npm_check`: `npm_config_check` + `./node_modules/.package-lock.json` — Check npm dependencies.
- `npm_audit`: `npm_config_check` + `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` — Audit npm dependency security.
- `npm_install`: `npm_config_check` + `./package.json` + `./package-lock.json` — Install npm dependencies.
- `npm_update`: `npm_config_check` + `./package.json` + `./package-lock.json` + `npm_clean` — Update npm dependencies.
- `npm_clean`: Remove installed npm dependencies.
- `composer_diagnose`: Check the Composer environment.
- `composer_check`: `./vendor/autoload.php` + `./composer.json` + `./composer.lock` — Check Composer dependencies and autoloading.
- `composer_audit`: `./vendor/autoload.php` + `./composer.json` + `./composer.lock` — Audit Composer dependency security.
- `composer_install`: `./composer.json` + `./composer.lock` — Install Composer dependencies.
- `composer_update`: `./composer.json` + `./composer.lock` + `composer_clean` — Update Composer dependencies.
- `composer_clean`: Remove installed Composer dependencies.
- `git_check`: Check repository integrity.
- `devcontainer_check`: `host_gate` — Check development environment configuration.
- `./node_modules/.package-lock.json`: `./.npmrc` + `./package.json` + `./package-lock.json` — Prepare npm dependencies.
- `./vendor/autoload.php`: `./composer.json` + `./composer.lock` — Prepare Composer dependencies.
