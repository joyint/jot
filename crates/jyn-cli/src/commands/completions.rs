// Copyright (c) 2026 Joydev GmbH (joydev.com)
// SPDX-License-Identifier: MIT

use anyhow::{bail, Result};
use clap_complete::{generate, Shell};
use std::io;

#[derive(clap::Args)]
#[command(after_help = "\
Recommended setup (add the line to the shell's startup file):

  Bash:        source <(COMPLETE=bash jyn)                       # ~/.bashrc
  Zsh:         source <(COMPLETE=zsh jyn)                        # ~/.zshrc
  Fish:        source (COMPLETE=fish jyn | psub)                 # config.fish
  PowerShell:  jyn completions powershell | Out-String | Invoke-Expression   # $PROFILE
  Elvish:      eval (COMPLETE=elvish jyn | slurp)                # rc.elv

The COMPLETE= forms are dynamic: they complete task IDs (bare short
form `A1`, plus completed-occurrence addresses like `1@2026-04-13`)
and tags. 'jyn completions <shell>' emits a static script instead
(subcommands and flags only); on Windows that is the simplest route
for a PowerShell profile.

For fully case-insensitive completion (so 'p<TAB>' finds Peter.*) put

  set completion-ignore-case on

into ~/.inputrc; this is a readline setting and applies to all commands.")]
pub struct CompletionsArgs {
    /// Target shell (bash, zsh, fish, powershell, elvish)
    shell: String,
}

pub fn run(args: CompletionsArgs, cmd: &mut clap::Command) -> Result<()> {
    let shell = match args.shell.to_lowercase().as_str() {
        "bash" => Shell::Bash,
        "zsh" => Shell::Zsh,
        "fish" => Shell::Fish,
        "powershell" => Shell::PowerShell,
        "elvish" => Shell::Elvish,
        _ => bail!(
            "unsupported shell '{}'. Supported: bash, zsh, fish, powershell, elvish",
            args.shell
        ),
    };
    generate(shell, cmd, "jyn", &mut io::stdout());
    Ok(())
}
