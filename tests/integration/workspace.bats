#!/usr/bin/env bats
# jyn workspace resolution: nearest .jyn/ found by walking up, and the
# active store shown in the list footer. JYN-0007-61.

load setup

@test "list from a nested subdirectory finds the workspace above it" {
    run jyn add "Buy milk"
    [ "$status" -eq 0 ]
    [ -d ".jyn/items" ]

    mkdir -p sub/deep
    cd sub/deep

    run jyn ls
    [ "$status" -eq 0 ]
    # Same workspace: the task added at the root is visible here.
    [[ "$output" == *"Buy milk"* ]]
    # Footer surfaces the resolved store, which lives at the root.
    [[ "$output" == *"/.jyn"* ]]
}

@test "list footer shows the active .jyn location" {
    run jyn add "Write report"
    [ "$status" -eq 0 ]

    run jyn ls
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 task"* ]]
    [[ "$output" == *"/.jyn"* ]]
}

@test "an unrelated directory with no .jyn above falls back to onboarding" {
    # setup() drops us in a fresh empty TEST_DIR with no .jyn anywhere up.
    run jyn
    [ "$status" -eq 0 ]
    [[ "$output" == *"No tasks yet"* ]]
    # The empty state still tells the user where tasks would be stored.
    [[ "$output" == *"New tasks go to:"* ]]
    [[ "$output" == *"/.jyn"* ]]
}

@test "empty existing workspace shows its location in the onboarding block" {
    mkdir -p .jyn/items
    run jyn ls
    [ "$status" -eq 0 ]
    [[ "$output" == *"No tasks yet"* ]]
    [[ "$output" == *"Workspace:"* ]]
    [[ "$output" == *"/.jyn"* ]]
}

@test "-w points the workspace at an explicit directory (skips walk-up)" {
    # A .jyn/ at the parent normally captures subdirectories via walk-up.
    run jyn add "Parent task"
    [ "$status" -eq 0 ]
    [ -d ".jyn/items" ]

    mkdir sub
    cd sub

    # Without -w, we inherit the parent's workspace.
    run jyn ls
    [ "$status" -eq 0 ]
    [[ "$output" == *"Parent task"* ]]

    # -w . pins the workspace to this directory, creating a fresh .jyn/
    # here instead of walking up to the parent's.
    run jyn -w . add "Sub task"
    [ "$status" -eq 0 ]
    [ -d ".jyn/items" ]

    run jyn -w . ls
    [ "$status" -eq 0 ]
    [[ "$output" == *"Sub task"* ]]
    [[ "$output" != *"Parent task"* ]]
}

@test "-w on a missing directory fails loudly" {
    run jyn -w ./no-such-dir ls
    [ "$status" -ne 0 ]
    [[ "$output" == *"working-dir"* || "$stderr" == *"working-dir"* ]]
}

@test "JYN_WORKING_DIR env var mirrors -w" {
    mkdir pinned
    JYN_WORKING_DIR="$PWD/pinned" run jyn add "Pinned task"
    [ "$status" -eq 0 ]
    [ -d "pinned/.jyn/items" ]
    [ ! -d ".jyn" ]
}
