#!/usr/bin/env bats

load "bats-helpers/bats-support/load"
load "bats-helpers/bats-assert/load"

# Image name for testing
IMAGE_NAME="porla-maritime-test"

setup_file() {
    # Build the Docker image once before all tests
    docker build -t "$IMAGE_NAME" .
}

teardown_file() {
    # Clean up the test image
    docker rmi "$IMAGE_NAME" || true
}

# Helper function to run commands in the container
docker_run() {
    docker run --rm "$IMAGE_NAME" "$@"
}

# Canboat tools tests
@test "analyzer is available" {
    run docker_run analyzer --help
    assert_output --partial "analyzer"
}

@test "actisense-serial is available" {
    run docker_run which actisense-serial
    assert_success
    assert_output --partial "/usr/local/bin/actisense-serial"
}

@test "candump2analyzer is available" {
    run docker_run which candump2analyzer
    assert_success
}

@test "n2kd is available" {
    run docker_run which n2kd
    assert_success
}

@test "raw2json is available" {
    run docker_run which raw2json
    assert_success
}

@test "n2k-csv-analyzer is available" {
    run docker_run which n2k-csv-analyzer
    assert_success
}

# Custom script tests
@test "ais script is available" {
    run docker_run ais --help
    assert_success
    assert_output --partial "Encode/decode ais"
}

@test "lwe450 script is available" {
    run docker_run lwe450 --help
    assert_success
    assert_output --partial "LWE450"
}

@test "canboat2pontos script is available" {
    run docker_run canboat2pontos --help
    assert_success
}

# Zenoh CLI tests (from base image)
@test "zenoh CLI is available" {
    run docker_run zenoh --help
    assert_success
    assert_output --partial "zenoh"
}

# Keelson codec tests
@test "keelson package is installed" {
    run docker_run python3 -c "import keelson; print(keelson.__name__)"
    assert_success
    assert_output "keelson"
}

@test "keelson encoders are registered" {
    run docker_run zenoh --list-encoders
    assert_success
    assert_output --partial "keelson-enclose-from-text"
    assert_output --partial "keelson-enclose-from-base64"
    assert_output --partial "keelson-enclose-from-json"
}

@test "keelson decoders are registered" {
    run docker_run zenoh --list-decoders
    assert_success
    assert_output --partial "keelson-uncover-to-text"
    assert_output --partial "keelson-uncover-to-base64"
    assert_output --partial "keelson-uncover-to-json"
}

# Functional tests
@test "ais can decode AIS message" {
    run docker run --rm "$IMAGE_NAME" sh -c "echo '!AIVDM,1,1,,B,13u@pd0025QdPFTN8R<9owv@2<3h,0*56' | ais decode"
    assert_success
    assert_output --partial "mmsi"
}
