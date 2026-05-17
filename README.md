# gh-actions-workflows

Reusable GitHub Actions workflows for kitsuyui repositories.

## Workflows

- `spellcheck.yml`: runs `crate-ci/typos` against the caller repository.
- `happy-commit.yml`: runs `kitsuyui/happy-commit`.
- `gitignore-in.yml`: runs `gitignore-in/gh-action`.
- `actionlint.yml`: runs `rhysd/actionlint` against the caller repository.
- `gh-counter.yml`: runs `kitsuyui/gh-counter` and uploads its generated files.
- `private-renovate.yml`: runs self-hosted Renovate for private repositories.

Caller repositories should keep only small workflow files that define the trigger,
permissions, and `jobs.<job_id>.uses` reference. The reusable workflows run in the
caller repository context after `actions/checkout`.

## Caller examples

```yaml
name: Spellcheck
on:
  - pull_request
permissions:
  contents: read
jobs:
  check:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/spellcheck.yml@main
```

If a repository needs to check a non-root path or a custom typos configuration,
pass explicit inputs from the caller workflow:

```yaml
jobs:
  check:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/spellcheck.yml@main
    with:
      files: docs
      config: .github/typos.toml
```

Keep repository-specific build, test, coverage, and publish paths in the caller
repository until the reusable workflow has explicit inputs for those paths.

Actionlint callers can customize the checked files and shellcheck behavior:

```yaml
jobs:
  actionlint:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/actionlint.yml@main
    with:
      files: ".github/workflows/*.yml"
      shellcheck-enabled: false
```

When overriding `actionlint-version`, pass an actionlint release tag such as
`v1.7.12`. The workflow validates the tag format before invoking `go run`.
The legacy `shellcheck: disabled` input is still accepted for compatibility, but
new callers should prefer `shellcheck-enabled: false`.

Private Renovate callers should provide a repository secret named
`RENOVATE_TOKEN`. The workflow processes the caller repository by default:

```yaml
name: Renovate
on:
  schedule:
    - cron: "0 23 * * 5"
  workflow_dispatch:
jobs:
  renovate:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/private-renovate.yml@main
    secrets:
      RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
```

The reusable workflow uses the `self-hosted-renovate/` branch prefix by default
so that it can run alongside hosted Renovate during migration.
Private callers should pin this reusable workflow to a tag or commit SHA after a
release because they pass a Renovate credential to the called workflow.
