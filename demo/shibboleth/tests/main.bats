#!/usr/bin/env bats

load ../../../common
load ../../../library

@test "000 Cleanup before running the tests" {
    cd ../simple ; docker-compose down -v ; true
    run docker-compose down -v
}

@test "010 Initialize and start containers" {
    docker-compose -f docker-compose-tests.yml build --pull
    docker-compose -f docker-compose-tests.yml up -d
}

@test "012 Wait for Shibboleth to start up" {
    wait_for_shibboleth_idp_start shibboleth_idp_1
}

@test "014 Wait for midPoint to start up" {
    wait_for_midpoint_start shibboleth_midpoint_server_1
}

@test "030 Check health (midPoint)" {
#    docker logs shibboleth_midpoint_server_1
    check_health
}

@test "035 Check health (Shibboleth IdP)" {
    check_health_shibboleth_idp
}

@test "040 Check Shibboleth redirection (/midpoint)" {
    curl -k --write-out %{redirect_url} --silent --output /dev/null https://localhost:8443/midpoint | grep 'https:\/\/localhost\/idp\/profile\/SAML2\/Redirect'
}

@test "041 Check Shibboleth redirection (/midpoint/)" {
    curl -k --write-out %{redirect_url} --silent --output /dev/null https://localhost:8443/midpoint/ | grep 'https:\/\/localhost\/idp\/profile\/SAML2\/Redirect'
}

@test "042 Check Shibboleth redirection (/midpoint/login)" {
    curl -k --write-out %{redirect_url} --silent --output /dev/null https://localhost:8443/midpoint/login | grep 'https:\/\/localhost\/idp\/profile\/SAML2\/Redirect'
}

@test "043 Check Shibboleth redirection (/midpoint/something)" {
    curl -k --write-out %{redirect_url} --silent --output /dev/null https://localhost:8443/midpoint/something | grep 'https:\/\/localhost\/idp\/profile\/SAML2\/Redirect'
}

@test "044 Check SOAP without Shibboleth redirection (/midpoint/ws/)" {
    status="$(curl -k --write-out %{http_code} --silent --output /dev/null https://localhost:8443/midpoint/ws/)"
    [ "$status" -eq 200 ]
}

@test "045 Check SOAP without Shibboleth redirection (/midpoint/model/)" {
    status="$(curl -k --write-out %{http_code} --silent --output /dev/null https://localhost:8443/midpoint/model/)"
    [ "$status" -eq 200 ]
}

@test "100 Check internally-authenticated REST call: get 'administrator'" {
    check_health
    get_and_check_object users 00000000-0000-0000-0000-000000000002 administrator
}

@test "200 Shut down" {
    docker-compose down
}

@test "210 Start with internal authentication" {
    env AUTHENTICATION=internal docker-compose -f docker-compose-tests.yml up -d
}

@test "220 Wait for midPoint to start up" {
    wait_for_midpoint_start shibboleth_midpoint_server_1
}

@test "230 Check health" {
    check_health
}

@test "240 Check internal login redirection" {
    curl -k --write-out %{redirect_url} --silent --output /dev/null https://localhost:8443/midpoint/self/dashboard | grep 'https:\/\/localhost:8443\/midpoint\/login'
}

@test "999 Clean up" {
    docker-compose down -v
}
