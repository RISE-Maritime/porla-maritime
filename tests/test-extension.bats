#!/usr/bin/env bats

load "bats-helpers/bats-support/load"
load "bats-helpers/bats-assert/load"
load "bats-helpers/bats-file/load"

DOCKER_IMAGE="porla-maritime:test"

setup_file() {
    docker build -t "$DOCKER_IMAGE" .
}

# ==============================================================================
# 3rd-party tools (presence tests)
# ==============================================================================

@test "3rd-party: analyzer -version shows version" {
    run docker run --rm "$DOCKER_IMAGE" "analyzer -version"

    assert_success
    assert_output --partial "analyzer"
}

@test "3rd-party: actisense-serial binary exists" {
    run docker run --rm "$DOCKER_IMAGE" "ls /usr/local/bin/actisense-serial"

    assert_success
}

# ==============================================================================
# ais tool tests
# ==============================================================================

@test "ais: decode --help shows usage" {
    run docker run --rm "$DOCKER_IMAGE" "ais decode --help"

    assert_success
}

@test "ais: decode processes AIS sentences" {
    run bash -c "cat tests/fixtures/ais/ais_input.txt | docker run --rm -i '$DOCKER_IMAGE' 'ais decode' 2>/dev/null"

    assert_success
    assert_output --partial '"msg_type":'
    assert_output --partial '"mmsi":'
}

# ==============================================================================
# lwe450 tool tests
# ==============================================================================

@test "lwe450: --help shows usage" {
    run docker run --rm "$DOCKER_IMAGE" "lwe450 --help"

    assert_success
    assert_output --partial "lwe450"
}

@test "lwe450: rejects invalid transmission group" {
    run docker run --rm "$DOCKER_IMAGE" "lwe450 INVALID_GROUP listen"

    assert_failure
    assert_output --partial "invalid choice"
}

# ==============================================================================
# canboat2pontos tool tests
# ==============================================================================

@test "canboat2pontos: requires vessel_id argument" {
    run docker run --rm "$DOCKER_IMAGE" "canboat2pontos"

    assert_failure
    assert_output --partial "vessel_id"
}

@test "canboat2pontos: PGN 127245 rudder data conversion" {
    run bash -c "cat tests/fixtures/canboat2pontos/pgn_127245_input.txt | docker run --rm -i '$DOCKER_IMAGE' 'canboat2pontos test_vessel' 2>/dev/null"

    assert_success

    expected_output=$(cat tests/fixtures/canboat2pontos/pgn_127245_expected_output.txt)
    assert_output "$expected_output"
}
