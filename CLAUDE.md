# unc — repo notes for agents

## always
- **update `CHANGELOG.md`** on every change that touches behavior, CLI, or docs.
  Add a line under `## unreleased`. Move it under a version heading on release.
- commits: human/casual/lowercase, terse. NO AI attribution, NO Co-Authored-By.
- never push without explicit approval.
- run `bash tests/test.sh` before committing.

## shipping a change
edit here (`~/Developer/unc`) → test → commit → (on approval) push →
`git -C ~/.unc/src pull` to update the live CLI/hooks.

full context: `~/.unc/HANDOFF.md`.
