# Issue tracker: local, offline

Issues for this repo are tracked **offline on John's laptop**, not on GitHub.

GitHub Issues is **disabled** for this repository, deliberately. The repo is
public, so anything filed there — titles, bodies, comments — is world-readable.
Planning detail about unreleased products, and biography pending approval, does
not belong in a public tracker.

## Where issues live

`issues-export.csv` at the repo root, opened as a spreadsheet.

It is listed in `.gitignore` and **must stay there**. It is a local working file:
never committed, never pushed. If you find it staged, unstage it.

Columns: `number`, `state`, `labels`, `title`, `created`, `body`.

The file was seeded by exporting the ten issues that existed before GitHub Issues
was switched off, so historical numbering is preserved.

## Conventions

- **Create an issue**: append a row. Take the next unused `number`; set `state`
  to `OPEN` and `created` to today.
- **Read an issue**: read the row.
- **List issues**: read the file, filter on `state` and `labels`.
- **Comment**: append to the `body` cell, dated, rather than overwriting.
- **Apply / remove labels**: edit the `labels` cell — space-separated.
- **Close**: set `state` to `CLOSED`.

Do not run `gh issue` commands against this repo. They fail — issues are disabled
at the repository level.

## When a skill says "publish to the issue tracker"

Add a row to `issues-export.csv`, then tell John what was added, since he cannot
see it appear anywhere online.

## When a skill says "fetch the relevant ticket"

Read the matching row from `issues-export.csv`.

## What must never go in the tracker

Treat it as a working file that could be shared:

- Nothing identifying the unreleased third product beyond "third platform"
- No biographical detail pending John's approval

## If tracking moves back online

Should this move to a private repo or an external tracker, replace this file
wholesale. Skills read only this file to decide how to reach the tracker.
