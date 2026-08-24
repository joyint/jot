#!/usr/bin/env bats
# Shell completions per JYN-0013-2D: static scripts for all supported
# shells, plus dynamic COMPLETE= protocol serving task-IDs and tags.

load setup

@test "static: bash script names jyn and looks like a completion function" {
    run jyn completions bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"_jyn"* ]]
    [[ "$output" == *"complete"* ]]
}

@test "static: zsh, fish, powershell, elvish all produce non-empty output" {
    for shell in zsh fish powershell elvish; do
        run jyn completions "$shell"
        [ "$status" -eq 0 ]
        [ -n "$output" ]
    done
}

@test "static: unsupported shell fails with a helpful message" {
    run jyn completions martian
    [ "$status" -ne 0 ]
    [[ "$output" == *"unsupported shell"* ]]
    [[ "$output" == *"bash, zsh, fish, powershell, elvish"* ]]
}

@test "completions --help lists the setup snippet" {
    run jyn completions --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"COMPLETE=zsh jyn"* ]]
    [[ "$output" == *"PowerShell"* ]]
}

@test "dynamic: 'jyn show <TAB>' offers real task IDs" {
    jyn add "Alpha" --tag work >/dev/null
    jyn add "Beta" >/dev/null

    run env _CLAP_COMPLETE_INDEX=2 COMPLETE=bash jyn -- jyn show ''
    [ "$status" -eq 0 ]
    # Bare IDs, per JYN-0011-08 (no unquoted # form).
    [[ "$output" == *"1"* ]]
    [[ "$output" == *"2"* ]]
    [[ "$output" != *"#1"* ]]
}

@test "dynamic: 'jyn ls --tag <TAB>' offers known tags" {
    jyn add "Alpha" --tag work >/dev/null
    jyn add "Beta" --tag home >/dev/null

    run env _CLAP_COMPLETE_INDEX=3 COMPLETE=bash jyn -- jyn ls --tag ''
    [ "$status" -eq 0 ]
    [[ "$output" == *"work"* ]]
    [[ "$output" == *"home"* ]]
}
