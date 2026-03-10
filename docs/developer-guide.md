# Developer Guide

## Pre-commit Hooks Setup

This repository recommends using [`prek`](https://prek.j178.dev) (a faster, drop-in alternative to [`pre-commit`](https://pre-commit.com)).

Install the hooks by running:

```console
uvx prek install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
```

If `prek` is already installed:

```console
prek install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
```

If you prefer `pre-commit`:

```console
uvx pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
```

## Commit Message Linting

This repository enforces [Conventional Commits](https://www.conventionalcommits.org) in pre-commit hooks and CI,
so your commit messages must follow that format.

You can maintain Conventional Commits manually, but automation tools such as Commitizen or cz-git can help.
Any tool is fine, but this repository uses [commitizen-tools/commitizen](https://github.com/commitizen-tools/commitizen)
for checks, so it is recommended.

Install Commitizen:

```console
uv tool install commitizen
```

Use Commitizen instead of `git commit`:

```console
cz commit
```

For more details, see [Commitizen documentation](https://commitizen-tools.github.io/commitizen).

## Version Bumping by Labels

This repository is configured to automatically bump versions when a pull request is merged with one of the
following labels:

- `update::major`
- `update::minor`
- `update::patch`

For more details, see [conjikidow/bump-version](https://github.com/conjikidow/bump-version).
