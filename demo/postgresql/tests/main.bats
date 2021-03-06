#!/usr/bin/env bats

load ../../../common
load ../../../library

@test "000 Cleanup before running the tests" {
    run docker-compose down -v
}

@test "010 Initialize and start midPoint" {
    docker-compose -f docker-compose-tests.yml up --build -d
    wait_for_midpoint_start postgresql_midpoint_server_1
}

@test "020 Check health" {
    check_health
}

@test "100 Get 'administrator'" {
    check_health
    get_and_check_object users 00000000-0000-0000-0000-000000000002 administrator
}

@test "110 And and get 'test110'" {
    check_health
    echo "<user><name>test110</name></user>" >/tmp/test110.xml
    add_object users /tmp/test110.xml
    rm /tmp/test110.xml
    search_and_check_object users test110
}

@test "999 Clean up" {
    docker-compose down -v
}
