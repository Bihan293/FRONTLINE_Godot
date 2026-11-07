# FRONTLINE QA bug log

This folder is the shared handoff point for every QA agent. Record every reproducible defect here, even when it looks small. Use one file per issue, named `BUG-0001-short-name.md`, and add its ID and status to `OPEN.md`.

## Required report fields

- Build or commit, platform, and device
- Severity: blocker, critical, major, minor, or cosmetic
- Status: open, investigating, fixed, ready for retest, verified, or won't fix
- Exact reproduction steps and how often it reproduces
- Expected result and actual result
- Screenshot, video, or log path when available
- Suspected owner and fix commit when known
- Retest result and tested build before marking verified

Do not mark an issue verified based only on a code change. A tester must reproduce the original steps on a build containing the fix and record the result.

## Workflow

1. Check `OPEN.md` to avoid duplicate reports; link related reports instead of deleting them.
2. Copy `BUG_TEMPLATE.md` to a new `BUG-####-short-name.md` file.
3. Add the issue to `OPEN.md` and update its status as work progresses.
4. Keep evidence in `BUGS/evidence/` using the issue ID in each filename.

