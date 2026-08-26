# Mad-Genius-Tech/modules — reusable Terraform modules

The shared Terraform module library for the estate: 58 provider-agnostic
modules under `modules/` (ALB, Aurora, ECS, CloudFront, 1Password, VPN, and
the rest). This repo owns module *implementation* only.

## What this repo does not own

- Environment state, terragrunt configuration, applies, or any live
  infrastructure claim — those live in the consumers:
  [BloclabsHQ/iac](https://github.com/BloclabsHQ/iac) (company substrate) and
  [BloclabsHQ/fabric-iac](https://github.com/BloclabsHQ/fabric-iac)
  (FabricBloc runtime), each governed by its own `CONTEXT.md`.
- Secrets or credentials. Modules take references; values stay in owner
  vaults.

## Working here

- One module per directory under `modules/<name>`; each carries its own
  variables/outputs and terraform-docs coverage (`.terraform-docs.yml`,
  enforced by `.pre-commit-config.yaml`).
- A module change ships to consumers only when they advance their module
  source ref — nothing here mutates an environment by merging.

## Evidence owners

Never state current status here — name the owner and how to read it fresh.

- Build/lint status: CI — `gh run list --repo Mad-Genius-Tech/modules --limit 5`
- Issues: GitHub — `gh issue list --repo Mad-Genius-Tech/modules`
- Pull requests: GitHub — `gh pr list --repo Mad-Genius-Tech/modules`
- Runtime/logs/metrics: none — this repo has no runtime; deployed behavior is
  owned by the consuming iac repos
- Deployed state: not deployed from here — see the consumers above
- Secrets: none held — references only
- Task/lifecycle state: not tracked in Workboard — this repo's GitHub issues
  own it

## Freshness

Before acting on any analysis of this repo:
`git fetch origin && git rev-list --count HEAD..origin/main`
A nonzero count voids prior findings — re-run them against the new base.
