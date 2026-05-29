# gh-actions-workflows

Reusable GitHub Actions workflows for kitsuyui repositories.

## Workflows

- `spellcheck.yml`: runs `crate-ci/typos` against the caller repository.
- `happy-commit.yml`: runs `kitsuyui/happy-commit`. The `happy` job uses
  `continue-on-error: true` by design — a failure (e.g. token scope, API
  rate-limit) does not block the caller's CI and is not observable via
  `needs.<job>.result`. This is intentional because happy-commit is a
  decorative step.
- `gitignore-in.yml`: runs `gitignore-in/gh-action`.
- `actionlint.yml`: runs `rhysd/actionlint` against the caller repository.
- `gh-counter.yml`: runs `kitsuyui/gh-counter` and uploads its generated files.
- `private-renovate.yml`: runs self-hosted Renovate for private repositories.

Caller repositories should keep only small workflow files that define the trigger,
permissions, and `jobs.<job_id>.uses` reference. The reusable workflows run in the
caller repository context after `actions/checkout`.

Reusable workflows that write repository contents or pull requests are serialized
by this repository's workflow definitions. Caller workflows should also keep a
matching `concurrency` group when they define multiple triggers for the same
write operation, so queued runs stay explicit in the caller repository.

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

The `files` input is passed unquoted to the shell so that glob patterns expand
normally. Pass one or more space-separated shell glob patterns. Paths containing
spaces are not supported. When overriding `actionlint-version`, pass an
actionlint release tag such as `v1.7.12`. The workflow validates the tag format
before invoking `go run`.
The legacy `shellcheck: disabled` input is still accepted for compatibility, but
new callers should prefer `shellcheck-enabled: false`.

Gh-counter callers can override the checkout history depth:

```yaml
jobs:
  gh-counter:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/gh-counter.yml@main
    with:
      checkout-fetch-depth: 100
```

The default remains `0` because gh-counter compares pull requests against the
base branch and may need full history to resolve a merge-base. Repositories with
large histories can set a bounded depth to reduce checkout cost, but too shallow
a checkout can make gh-counter fail to find the pull request base commit.

Private Renovate callers should provide a repository secret named
`RENOVATE_TOKEN`. The workflow processes the caller repository by default:

```yaml
name: Renovate
on:
  schedule:
    - cron: "0 23 * * 5"
  workflow_dispatch:
concurrency:
  group: private-renovate-${{ github.repository }}
  cancel-in-progress: false
jobs:
  renovate:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/private-renovate.yml@main
    secrets:
      RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
```

The reusable workflow uses the `self-hosted-renovate/` branch prefix by default
so that it can run alongside hosted Renovate during migration.
Private callers should pin this reusable workflow to a tag or commit SHA because
they pass a Renovate credential to the called workflow.

## Releases

Releases are created by triggering the `release.yml` workflow via
`Actions → Release → Run workflow` with a version tag such as `v1.0.0`.
The workflow validates the semver format and creates a GitHub release with
auto-generated release notes.

No releases have been published yet. Until the first release tag is available,
callers that pass credentials or otherwise need a reproducible reference can
pin to a commit SHA:

```yaml
jobs:
  renovate:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/private-renovate.yml@f71e3c9057b11b8f5308003068ed64c8da3ed8a9
    secrets:
      RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
```

Once a release is published, callers should prefer pinning to a release tag:

```yaml
jobs:
  renovate:
    uses: kitsuyui/gh-actions-workflows/.github/workflows/private-renovate.yml@v1.0.0
    secrets:
      RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
```

Other callers may continue to reference `@main` if they prefer to track the
latest workflows without explicit pinning.
