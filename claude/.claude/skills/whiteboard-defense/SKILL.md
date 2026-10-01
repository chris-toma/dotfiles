---
name: whiteboard-defense
description: Explain an implementation by functionality — what was done and how it works — at the level Mitchell Hashimoto's "whiteboard defense" expects: how it works, why this approach, what data structures, how failures and untrusted input are handled. Written directly in the terminal. Use when asked to explain an implementation, a change, a PR, a feature or a system.
---

# Whiteboard defense

The bar (Hashimoto): you should be able to pull anyone aside and have them
explain a system they shipped: how it works and why it was built that way. Not
line by line, not every function call. The design.

Your job is to write that explanation for the user: **what was done and how it
works**. This is an explanation, not a review. Do not critique the code, look
for bugs, quiz the user or list weak spots.

## Output

- Write the explanation **directly in the terminal response**. Do not
  create a separate file or document.
- **Keep it short: about 15–25 lines in total.** No preamble, no recap, no
  per-unit sub-headings or bullet lists of every aspect.
- If the user wants more on one part, they'll ask. Then go deeper on that part
  only.

## 1. Scope and read

- Target: the current diff (`git diff`, `git diff main...HEAD`), a PR, a path,
  or a feature the user names. If it's ambiguous, default to the branch diff.
- Read the code and its callers, callees, config, schema and tests.

### Commits: pick them, then read their diffs

Pick the commits by target:

- Branch diff / PR: `git log --reverse main..HEAD` (use the PR's base if it
  isn't `main`).
- Path or feature: `git log --reverse -- <paths>`, plus `git blame` on the
  lines behind the key parts to find the older commits that introduced them.

Read every picked commit's actual changes (`git show <sha>`), not only its
message. Use them to understand:

- **What was done, in order.** What each step added or changed.
- **Why it ended up this way.** An approach that was tried and then replaced
  explains the choice that was kept.
- **Edge cases.** Fix-up commits and tests added alongside the code show which
  cases the implementation handles.
- PR description and review comments (`gh pr view --comments`) for stated
  intent.

This is background for the explanation. Don't narrate commit by commit unless
the user asks.

## 2. Structure of the answer

**Purpose.** One sentence: what problem this solves.

**Flow.** One line, or a sketch of at most 3 lines:
`entry → processing → storage / side effects → output`.

**By functionality.** At most 5 units, grouped by what it *does* from the
outside (e.g. "ingest events", "dedupe", "retry"), not files or functions.
Each unit is a bold name plus **2–3 sentences**:

- how it works, with one `file:line` anchor;
- why it's built this way and the key data structure, only if it's
  non-obvious (one clause);
- failure, edge-case or security handling, only if the unit exists for it or
  handles something notable (one clause).

Leave out anything that doesn't fit those sentences.

## Rules

- Functionality over syntax. Skip anything a competent engineer reads in two
  seconds.
- Every claim comes from code or history you read. Cite `file:line`. Mark
  anything inferred as **(unverified)**.
- Describe; don't judge. No "this could be improved", no risk lists, no
  verdicts.
