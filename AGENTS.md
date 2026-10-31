# AGENTS.md

Edit AGENTS.md and README.md only when explicitly requested.

Freely manage PLAN.md, NOTES.md, and ARCHITECTURE.md for your own work. Keep them gitignored and never commit them.

## Devcontainer

The development environment is configured in `.devcontainer/`. Manage it from the repository root on the host using the Makefile targets or directly through the `devcontainer`, `docker` and `docker compose` CLIs.

Use an available shell. Add `-eu` for sh or `-Eeuo pipefail` for Bash as needed.

```sh
# start
make up

# workspace command
devcontainer exec --workspace-folder . COMMAND ARG...

# workspace sh
devcontainer exec --workspace-folder . sh -c 'COMMAND ARG... | COMMAND ARG...'

# workspace bash
devcontainer exec --workspace-folder . bash -c 'COMMAND ARG... | COMMAND ARG...'

# sidecar command
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE COMMAND ARG...

# sidecar sh
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE sh -c 'COMMAND ARG... | COMMAND ARG...'

# sidecar bash
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE bash -c 'COMMAND ARG... | COMMAND ARG...'
```

### Services

`devcontainer` — `docker.io/library/php:8.5.12-cli-trixie`  
Runs development tools and workspace commands.

`wiremock` — `docker.io/wiremock/wiremock:3.13.2`  
Mocks HTTP for development and automated tests.

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

## Prettier

```json
{
    "arrowParens": "always",
    "bracketSameLine": false,
    "objectWrap": "preserve",
    "plugins": [
        "@prettier/plugin-xml"
    ],
    "proseWrap": "never",
    "semi": true,
    "singleAttributePerLine": true,
    "singleQuote": true,
    "trailingComma": "all",
    "xmlQuoteAttributes": "double",
    "xmlSelfClosingSpace": true,
    "xmlWhitespaceSensitivity": "preserve"
}
```
