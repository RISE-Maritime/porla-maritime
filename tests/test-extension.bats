#!/usr/bin/env bats

load "bats-helpers/bats-support/load"
load "bats-helpers/bats-assert/load"
load "bats-helpers/bats-file/load"


@test "PGN 127245" {

    run bash -c 'cat "tests/pgn_127245_input.txt" | python bin/canboat2pontos test_vessel'

    echo "$output"

    expected_output=$(cat tests/pgn_127245_expected_output.txt)

    assert_output "$expected_output"
}