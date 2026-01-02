#!/usr/bin/env bats

load "bats-helpers/bats-support/load"
load "bats-helpers/bats-assert/load"
load "bats-helpers/bats-file/load"

# Canboat tools tests
@test "analyzer is available" {
    run analyzer --help
    # analyzer returns 1 when called with --help but outputs help text
    assert_output --partial "analyzer"
}

@test "actisense-serial is available" {
    run actisense-serial --help
    # Check it's executable (may return non-zero without device)
    assert_file_executable /usr/local/bin/actisense-serial
}

@test "candump2analyzer is available" {
    assert_file_executable /usr/local/bin/candump2analyzer
}

@test "n2kd is available" {
    assert_file_executable /usr/local/bin/n2kd
}

@test "raw2json is available" {
    assert_file_executable /usr/local/bin/raw2json
}

@test "n2k-csv-analyzer is available" {
    assert_file_executable /usr/local/bin/n2k-csv-analyzer
}

# Custom script tests
@test "ais script is available" {
    run ais --help
    assert_success
    assert_output --partial "Encode/decode ais"
}

@test "lwe450 script is available" {
    run lwe450 --help
    assert_success
    assert_output --partial "LWE450"
}

@test "canboat2pontos script is available" {
    run canboat2pontos --help
    assert_success
}

# Zenoh CLI tests
@test "zenoh CLI is available" {
    run zenoh --help
    assert_success
    assert_output --partial "zenoh"
}

# Keelson codec tests
@test "keelson package is installed" {
    run python3 -c "import keelson; print(keelson.__name__)"
    assert_success
    assert_output "keelson"
}

@test "keelson encoders are registered" {
    run zenoh --list-encoders
    assert_success
    assert_output --partial "keelson-enclose-from-text"
    assert_output --partial "keelson-enclose-from-base64"
    assert_output --partial "keelson-enclose-from-json"
}

@test "keelson decoders are registered" {
    run zenoh --list-decoders
    assert_success
    assert_output --partial "keelson-uncover-to-text"
    assert_output --partial "keelson-uncover-to-base64"
    assert_output --partial "keelson-uncover-to-json"
}

# Functional tests
@test "ais can decode AIS message" {
    # AIVDM message for testing (vessel position report)
    echo '!AIVDM,1,1,,B,13u@pd0025QdPFTN8R<9owv@2<3h,0*56' | run ais decode
    assert_success
    assert_output --partial "mmsi"
}
