#!/usr/bin/env bats

load ../../../common
load ../../../library

@test "000 Cleanup before running the tests" {
    run docker-compose down -v
}

@test "010 Initialize and start midPoint" {
    docker-compose up -d
    wait_for_midpoint_start simple_midpoint_server_1
}

@test "010 Check health" {
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

@test "300 Check repository preserved between restarts" {
    check_health

    echo "Creating user test300 and checking its existence"
    echo "<user><name>test300</name></user>" >/tmp/test300.xml
    add_object users /tmp/test300.xml
    rm /tmp/test300.xml
    search_and_check_object users test300

    echo "Bringing the containers down"
    docker-compose down

    echo "Re-creating the containers"
    docker-compose up --no-start
    docker-compose start
    wait_for_midpoint_start simple_midpoint_server_1

    echo "Searching for the user again"
    search_and_check_object users test300
}

@test "350 Test DB schema version check" {
    echo "Removing version information from m_global_metadata"
    docker exec simple_midpoint_data_1 mysql -p123321 registry -e "drop table m_global_metadata"

    echo "Bringing the containers down"
    docker-compose down

    echo "Re-creating the containers"
    docker-compose up -d

    wait_for_log_message simple_midpoint_server_1 "Database schema is not compatible with the executing code; however, an upgrade path is available."
}

@test "360 Test DB schema upgrade" {
	skip 'Not supported for 4.0-SNAPSHOT'
    echo "Stopping midpoint_server container"
    docker stop simple_midpoint_server_1

    echo "Installing empty 3.8 repository"
    docker exec simple_midpoint_data_1 mysql -p123321 -e "DROP DATABASE registry"
    docker exec simple_midpoint_data_1 bash -c " curl https://raw.githubusercontent.com/Evolveum/midpoint/v3.8/config/sql/_all/mysql-3.8-all-utf8mb4.sql > /tmp/create-3.8-utf8mb4.sql"
    docker exec simple_midpoint_data_1 mysql -p123321 -e "CREATE DATABASE IF NOT EXISTS registry;"
    docker exec simple_midpoint_data_1 mysql -p123321 -e "GRANT ALL ON registry.* TO 'registry_user'@'%' IDENTIFIED BY 'WJzesbe3poNZ91qIbmR7' ;"
    docker exec simple_midpoint_data_1 bash -c "mysql -p123321 registry < /tmp/create-3.8-utf8mb4.sql"

    echo "Bringing the containers down"
    docker-compose down

    echo "Re-creating the containers"
    env REPO_SCHEMA_VERSION_IF_MISSING=3.8 REPO_UPGRADEABLE_SCHEMA_ACTION=upgrade REPO_SCHEMA_VARIANT=utf8mb4 docker-compose up -d

    wait_for_log_message simple_midpoint_server_1 "Schema was successfully upgraded from 3.8 to 3.9 using script 'mysql-upgrade-3.8-3.9-utf8mb4.sql'"
    wait_for_midpoint_start simple_midpoint_server_1
}

@test "999 Clean up" {
    docker-compose down -v
}
