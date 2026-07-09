---
name: feedback-{short-kebab-case-slug}
aliases:
  - feedback-{short-kebab-case-slug}     # short slug — keeps [[wikilinks]] working
description: "{one-line summary — used to decide relevance in future conversations}"
metadata:
  type: feedback
  category: "{topic — e.g., tooling, communication, workflow}"
  status: active
  date: YYYY-MM-DD
  # Learning Loop tracking — see docs/LEARNING-LOOP.md
  applied_count: 0
  last_applied: null
  last_context: null
  verified_by_user: pending  # yes | no | pending
  promoted_to: null          # null | "CLAUDE.md#section" | "user-docs"
  evolved_to: null           # null | "skill:{skill-name}"
  skill_version: null         # null | 1, 2, 3...
---

# Feedback — {Title}

## Rule
{The rule/guidance itself — one sentence ideally}

## Why
{Reason — usually a past incident or strong preference of the user}
{Cite the original phrase/scenario if possible}

## How to apply
{Concrete trigger + action — when does this kick in?}
{Examples of correct vs incorrect application}

## Anti-patterns
- {what NOT to do}
- {common mistake}

## Trigger
- {situation A that should fire this lesson}
- {situation B}

## Related
- [[other-memory-entry]]

## Change Log
- YYYY-MM-DD: created — captured from "{phrase or scenario}"
- (when refined): {what changed and why}
