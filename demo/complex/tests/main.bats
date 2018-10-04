#!/usr/bin/env bats

load ../../../common
load ../../../library

@test "000 Cleanup before running the tests" {
    (cd ../simple ; docker-compose down -v)
    (cd ../shibboleth ; docker-compose down -v)
    (cd ../postgresql ; docker-compose down -v)
    docker-compose down -v
}

@test "010 Initialize and start the composition" {
    # We want to fail cleanly if there's any interference
    docker ps
    ! (docker ps | grep -E "shibboleth_(idp|directory)_1|(complex|simple|shibboleth|postgresql)_(midpoint_server|midpoint_data)_1")
    docker-compose up -d --build
}

@test "020 Wait until components are started" {
    touch $BATS_TMPDIR/not-started
    wait_for_midpoint_start complex_midpoint_server_1 complex_midpoint_data_1
    wait_for_shibboleth_idp_start complex_idp_1
    wait_for_grouper_ui_start complex_grouper_ui_1
    rm $BATS_TMPDIR/not-started
}

@test "040 Check midPoint health" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    check_health
}

@test "050 Check Shibboleth IDP health" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    check_health_shibboleth_idp
}

@test "060 Check Grouper health" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    skip TODO
}

@test "100 Get 'administrator'" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    check_health
    get_and_check_object users 00000000-0000-0000-0000-000000000002 administrator
}

@test "110 And and get 'test110'" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    check_health
    echo "<user><name>test110</name></user>" >/tmp/test110.xml
    add_object users /tmp/test110.xml
    rm /tmp/test110.xml
    search_and_check_object users test110
    delete_object_by_name users test110
}

@test "200 Upload objects" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    # reduce data in SIS database so imports will take reasonable time
    docker exec complex_sources_1 mysql sis -e "delete from SIS_COURSES where uid not in ('amorrison', 'banderson', 'cmorrison', 'danderson', 'ddavis', 'jsmith', 'kwhite', 'mroberts', 'whenderson', 'wprice')"
    docker exec complex_sources_1 mysql sis -e "delete from SIS_AFFILIATIONS where uid not in ('amorrison', 'banderson', 'cmorrison', 'danderson', 'ddavis', 'jsmith', 'kwhite', 'mroberts', 'whenderson', 'wprice')"
    docker exec complex_sources_1 mysql sis -e "delete from SIS_PERSONS where uid not in ('amorrison', 'banderson', 'cmorrison', 'danderson', 'ddavis', 'jsmith', 'kwhite', 'mroberts', 'whenderson', 'wprice')"

    check_health
    ./upload-objects

    search_and_check_object objectTemplates template-org-course
    search_and_check_object objectTemplates template-org-department
    search_and_check_object objectTemplates template-role-affiliation
    search_and_check_object objectTemplates template-role-generic-group
    
    search_and_check_object orgs courses
    search_and_check_object orgs departments

    search_and_check_object resources "OpenLDAP (directory)"
    search_and_check_object resources "Grouper SQL/MQ"
    search_and_check_object resources "SQL SIS courses (sources)"
    search_and_check_object resources "SQL SIS persons (sources)"

    search_and_check_object roles metarole-affiliation
    search_and_check_object roles metarole-course
    search_and_check_object roles metarole-department 
    search_and_check_object roles metarole-generic-group
    search_and_check_object roles role-grouper-sysadmin
    search_and_check_object roles role-ldap-basic
}

@test "210 Test resource" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    test_resource 0a37121f-d515-4a23-9b6d-554c5ef61272
    test_resource 6dcb84f5-bf82-4931-9072-fbdf87f96442
    test_resource 13660d60-071b-4596-9aa1-5efcd1256c04
    test_resource 4d70a0da-02dd-41cf-b0a1-00e75d3eaa15
}

@test "220 Import SIS_PERSONS" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    add_object tasks midpoint-objects-manual/tasks/task-import-sis-persons.xml
    search_and_check_object tasks "Import from SIS persons"
    wait_for_task_completion 22c2a3d0-0961-4255-9eec-c550a79aeaaa 6 10
    assert_task_success 22c2a3d0-0961-4255-9eec-c550a79aeaaa

    search_and_check_object users jsmith
    search_and_check_object users banderson
    search_and_check_object users kwhite
    search_and_check_object users whenderson
    search_and_check_object users ddavis
    search_and_check_object users cmorrison
    search_and_check_object users danderson
    search_and_check_object users amorrison
    search_and_check_object users wprice
    search_and_check_object users mroberts

    check_ldap_account_by_user_name jsmith complex_directory_1
    check_ldap_account_by_user_name banderson complex_directory_1
    check_ldap_account_by_user_name kwhite complex_directory_1
    check_ldap_account_by_user_name whenderson complex_directory_1
    check_ldap_account_by_user_name ddavis complex_directory_1
    check_ldap_account_by_user_name cmorrison complex_directory_1
    check_ldap_account_by_user_name danderson complex_directory_1
    check_ldap_account_by_user_name amorrison complex_directory_1
    check_ldap_account_by_user_name wprice complex_directory_1
    check_ldap_account_by_user_name mroberts complex_directory_1
    # TODO check assignments etc
}

@test "230 Import SIS_COURSES" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    add_object tasks midpoint-objects-manual/tasks/task-import-sis-courses.xml
    search_and_check_object tasks "Import from SIS courses"
    wait_for_task_completion b73a2e66-8233-4c20-928f-acb30027b33e 8 10
    assert_task_success b73a2e66-8233-4c20-928f-acb30027b33e

    search_and_check_object orgs course_ACCT101
    search_and_check_object orgs course_ACCT201
    search_and_check_object orgs course_CS251
    search_and_check_object orgs course_CS252
    search_and_check_object orgs course_MATH100
    search_and_check_object orgs course_MATH101
    search_and_check_object orgs course_SCI123
    search_and_check_object orgs course_SCI404

    check_ldap_courses_by_name course_ACCT101 complex_directory_1
    check_ldap_courses_by_name course_ACCT201 complex_directory_1
    check_ldap_courses_by_name course_CS251 complex_directory_1
    check_ldap_courses_by_name course_CS252 complex_directory_1
    check_ldap_courses_by_name course_MATH100 complex_directory_1
    check_ldap_courses_by_name course_MATH101 complex_directory_1
    check_ldap_courses_by_name course_SCI123 complex_directory_1
    check_ldap_courses_by_name course_SCI404 complex_directory_1

    check_of_ldap_membership amorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" complex_directory_1
    check_of_ldap_membership cmorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" complex_directory_1
    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" complex_directory_1
    check_of_ldap_membership whenderson "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" complex_directory_1

    check_of_ldap_membership amorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" complex_directory_1
    check_of_ldap_membership cmorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" complex_directory_1
    check_of_ldap_membership ddavis "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" complex_directory_1
    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" complex_directory_1

    check_of_ldap_membership kwhite "ou=courses,ou=groups,dc=internet2,dc=edu" "CS252" complex_directory_1

    check_of_ldap_membership danderson "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" complex_directory_1
    check_of_ldap_membership ddavis "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" complex_directory_1
    check_of_ldap_membership kwhite "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" complex_directory_1
    check_of_ldap_membership wprice "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" complex_directory_1

    check_of_ldap_membership amorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH101" complex_directory_1
    check_of_ldap_membership cmorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH101" complex_directory_1
    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH101" complex_directory_1

    check_of_ldap_membership danderson "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI123" complex_directory_1
    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI123" complex_directory_1

    check_of_ldap_membership kwhite "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI404" complex_directory_1
    check_of_ldap_membership wprice "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI404" complex_directory_1
}


@test "240 Check 'TestUser240' in Midpoint and LDAP" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    check_health
    echo "<user><name>TestUser240</name><fullName>Test User240</fullName><givenName>Test</givenName><familyName>User240</familyName><credentials><password><value><clearValue>password</clearValue></value></password></credentials></user>" >/tmp/testuser240.xml
    add_object users /tmp/testuser240.xml
    rm /tmp/testuser240.xml
    search_and_check_object users TestUser240

    execute_bulk_action tests/resources/bulk-action/recompute-role-grouper-sysadmin.xml complex_midpoint_server_1
    execute_bulk_action tests/resources/bulk-action/assign-role-grouper-sysadmin-to-test-user.xml complex_midpoint_server_1

    check_ldap_account_by_user_name TestUser240 complex_directory_1
    check_of_ldap_membership TestUser240 "ou=groups,dc=internet2,dc=edu" "sysadmingroup" complex_directory_1
    
    delete_object_by_name users TestUser240
}


@test "999 Clean up" {
    docker-compose down -v
}
