// Copyright (c) 2026 Joydev GmbH (joydev.com)
// SPDX-License-Identifier: MIT

//! Dynamic completions for task IDs and tags.
//!
//! Fed to clap_complete via `ArgValueCompleter::new(...)`. Reads the
//! active workspace on every completion callback (cheap enough for
//! shell TAB latency; a few dozen tiny YAML files).

use std::ffi::OsStr;

use clap_complete::CompletionCandidate;
use jyn_core::{display, storage};

/// Resolve the workspace root the same way `run()` does, but silently:
/// completion callbacks must never error. Falls back to cwd when no
/// `.jyn/` is above it. Honours JYN_WORKING_DIR so completion works
/// under `-w` too.
fn resolve_root() -> Option<std::path::PathBuf> {
    let cwd = if let Some(w) = std::env::var_os("JYN_WORKING_DIR") {
        std::path::PathBuf::from(w)
    } else {
        std::env::current_dir().ok()?
    };
    Some(storage::find_workspace_root(&cwd).unwrap_or(cwd))
}

fn matches(prefix: &OsStr, candidate: &str) -> bool {
    match prefix.to_str() {
        Some(p) => candidate.starts_with(p),
        None => true,
    }
}

/// Complete a Task ID: the bare short form (`A1`, `110`) for every
/// live task, plus each series' completed-occurrence addresses in the
/// bare `N@DATE` form. Bare, not `#`-prefixed, per JYN-0011-08 - the
/// user types what shells actually deliver.
pub fn complete_task_id(prefix: &OsStr) -> Vec<CompletionCandidate> {
    let Some(root) = resolve_root() else {
        return Vec::new();
    };
    let Ok(tasks) = storage::load_tasks(&root) else {
        return Vec::new();
    };
    let mut out: Vec<CompletionCandidate> = Vec::new();
    for t in &tasks {
        let short = display::short_id(&t.item.id);
        let bare = short.trim_start_matches('#').to_string();
        if matches(prefix, &bare) {
            out.push(
                CompletionCandidate::new(bare.clone()).help(Some(t.item.title.clone().into())),
            );
        }
        for occ in &t.completed_occurrences {
            let addr = format!("{bare}@{}", occ.occurrence);
            if matches(prefix, &addr) {
                out.push(CompletionCandidate::new(addr).help(Some(t.item.title.clone().into())));
            }
        }
    }
    out
}

/// Complete a tag from the union of tags on all non-archived tasks.
pub fn complete_tag(prefix: &OsStr) -> Vec<CompletionCandidate> {
    let Some(root) = resolve_root() else {
        return Vec::new();
    };
    let Ok(tasks) = storage::load_tasks(&root) else {
        return Vec::new();
    };
    let mut seen = std::collections::BTreeSet::new();
    for t in &tasks {
        if t.archived {
            continue;
        }
        for tag in &t.item.tags {
            seen.insert(tag.clone());
        }
    }
    seen.into_iter()
        .filter(|t| matches(prefix, t))
        .map(CompletionCandidate::new)
        .collect()
}
