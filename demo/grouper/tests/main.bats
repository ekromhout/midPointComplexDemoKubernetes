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
    ! (docker ps | grep -E "shibboleth_(idp|directory)_1|(grouper|simple|shibboleth|postgresql)_(midpoint_server|midpoint_data)_1")
    docker-compose build --pull grouper_daemon grouper_ui grouper_data directory sources midpoint_data idp mq
    # Sometimes the tier/midpoint:xyz is not yet in the repository, causing issues with --pull
    docker-compose build midpoint_server
    docker-compose up -d
}

@test "020 Wait until components are started" {
    touch $BATS_TMPDIR/not-started
    wait_for_midpoint_start grouper_midpoint_server_1 grouper_midpoint_data_1
    wait_for_shibboleth_idp_start grouper_idp_1
    wait_for_grouper_ui_start grouper_grouper_ui_1
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
    docker exec grouper_sources_1 mysql sis -u root -p123321 -e "delete from SIS_COURSES where uid not in ('amorrison', 'banderson', 'cmorrison', 'danderson', 'ddavis', 'jsmith', 'kwhite', 'mroberts', 'whenderson', 'wprice')"
    docker exec grouper_sources_1 mysql sis -u root -p123321 -e "delete from SIS_AFFILIATIONS where uid not in ('amorrison', 'banderson', 'cmorrison', 'danderson', 'ddavis', 'jsmith', 'kwhite', 'mroberts', 'whenderson', 'wprice')"
    docker exec grouper_sources_1 mysql sis -u root -p123321 -e "delete from SIS_PERSONS where uid not in ('amorrison', 'banderson', 'cmorrison', 'danderson', 'ddavis', 'jsmith', 'kwhite', 'mroberts', 'whenderson', 'wprice')"

    check_health
    ./upload-objects.sh

    search_and_check_object objectTemplates template-user

    search_and_check_object archetypes affiliation
    search_and_check_object archetypes course
    search_and_check_object archetypes department
    
    search_and_check_object orgs affiliations
    search_and_check_object orgs courses
    search_and_check_object orgs departments

    search_and_check_object resources "LDAP (directory)"
    search_and_check_object resources "Grouper Resource"
    search_and_check_object resources "SQL SIS persons (sources)"

    search_and_check_object roles metarole-grouper-provided-group
    search_and_check_object roles metarole-ldap-group
    search_and_check_object roles role-ldap-basic
}

@test "210 Test resources" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
    test_resource 0a37121f-d515-4a23-9b6d-554c5ef61272
    test_resource 4d70a0da-02dd-41cf-b0a1-00e75d3eaa15
    test_resource a343fc2e-3954-4034-ba1a-2b72c21e577a
    test_resource e417225d-8a08-46f3-9b5d-624990b52386
    test_resource fe805d13-481b-43ec-97d8-9d2df72cd38e
    test_resource 1eff65de-5bb6-483d-9edf-8cc2c2ee0233
}

@test "215 Recompute banderson and sysadmingroup" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    ./recompute.sh
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

    check_ldap_account_by_user_name jsmith grouper_directory_1
    check_ldap_account_by_user_name banderson grouper_directory_1
    check_ldap_account_by_user_name kwhite grouper_directory_1
    check_ldap_account_by_user_name whenderson grouper_directory_1
    check_ldap_account_by_user_name ddavis grouper_directory_1
    check_ldap_account_by_user_name cmorrison grouper_directory_1
    check_ldap_account_by_user_name danderson grouper_directory_1
    check_ldap_account_by_user_name amorrison grouper_directory_1
    check_ldap_account_by_user_name wprice grouper_directory_1
    check_ldap_account_by_user_name mroberts grouper_directory_1
}

@test "230 Create ref loaders" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    ./create-ref-loaders.sh
}

@test "235 Wait for loaders to run" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    sleep 120
}

@test "240 Create additional ref groups" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    ./add-ref-groups.sh
}

#@test "250 Check 'TestUser250' in midPoint and LDAP" {
#    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi
#
#    check_health
#    echo "<user><name>TestUser250</name><fullName>Test User250</fullName><givenName>Test</givenName><familyName>User250</familyName><credentials><password><value><clearValue>password</clearValue></value></password></credentials></user>" >/tmp/testuser250.xml
#    add_object users /tmp/testuser250.xml
#    rm /tmp/testuser250.xml
#    search_and_check_object users TestUser250
#
#    # probably will not work
#    execute_bulk_action tests/resources/bulk-action/assign-role-grouper-sysadmin-to-test-user.xml grouper_midpoint_server_1
#
#    check_ldap_account_by_user_name TestUser250 grouper_directory_1
#    check_of_ldap_membership TestUser250 "ou=groups,dc=internet2,dc=edu" "sysadmingroup" grouper_directory_1
#    
#    delete_object_by_name users TestUser250
#}

@test "310 Import Grouper-to-midPoint async update task" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    check_health
    add_object tasks midpoint-objects-manual/tasks/task-async-update-grouper.xml
    search_and_check_object tasks "Grouper async updates"
}

@test "320 Wait for the queue to become empty" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    ATTEMPT=0
    MAX_ATTEMPTS=20
    DELAY=10

    get_messages sampleQueue
    echo "Messages: $MESSAGES"

    until [[ $ATTEMPT = $MAX_ATTEMPTS ]]; do
        ATTEMPT=$((ATTEMPT+1))
        get_messages sampleQueue
        echo "Messages: $MESSAGES"
        if [ "$MESSAGES" = "0" ]; then return 0; fi
        echo "Waiting $DELAY seconds for the queue to become empty (attempt $ATTEMPT) ..."
        sleep $DELAY
    done
    return 1
}

@test "330 Check groups in midPoint and LDAP" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

#    wait_for_task_completion b73a2e66-8233-4c20-928f-acb30027b33e 8 10
#    assert_task_success b73a2e66-8233-4c20-928f-acb30027b33e

    search_and_check_object orgs course_ACCT101
    search_and_check_object orgs course_ACCT201
    search_and_check_object orgs course_CS251
    search_and_check_object orgs course_CS252
    search_and_check_object orgs course_MATH100
    search_and_check_object orgs course_MATH101
    search_and_check_object orgs course_SCI123
    search_and_check_object orgs course_SCI404

    check_ldap_courses_by_name course_ACCT101 grouper_directory_1
    check_ldap_courses_by_name course_ACCT201 grouper_directory_1
    check_ldap_courses_by_name course_CS251 grouper_directory_1
    check_ldap_courses_by_name course_CS252 grouper_directory_1
    check_ldap_courses_by_name course_MATH100 grouper_directory_1
    check_ldap_courses_by_name course_MATH101 grouper_directory_1
    check_ldap_courses_by_name course_SCI123 grouper_directory_1
    check_ldap_courses_by_name course_SCI404 grouper_directory_1

# memberships will be there only after triggers are executed

#    check_of_ldap_membership amorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" grouper_directory_1
#    check_of_ldap_membership cmorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" grouper_directory_1
#    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" grouper_directory_1
#    check_of_ldap_membership whenderson "ou=courses,ou=groups,dc=internet2,dc=edu" "ACCT101" grouper_directory_1

#    check_of_ldap_membership amorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" grouper_directory_1
#    check_of_ldap_membership cmorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" grouper_directory_1
#    check_of_ldap_membership ddavis "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" grouper_directory_1
#    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "CS251" grouper_directory_1

#    check_of_ldap_membership kwhite "ou=courses,ou=groups,dc=internet2,dc=edu" "CS252" grouper_directory_1

#    check_of_ldap_membership danderson "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" grouper_directory_1
#    check_of_ldap_membership ddavis "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" grouper_directory_1
#    check_of_ldap_membership kwhite "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" grouper_directory_1
#    check_of_ldap_membership wprice "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH100" grouper_directory_1

#    check_of_ldap_membership amorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH101" grouper_directory_1
#    check_of_ldap_membership cmorrison "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH101" grouper_directory_1
#    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "MATH101" grouper_directory_1

#    check_of_ldap_membership danderson "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI123" grouper_directory_1
#    check_of_ldap_membership mroberts "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI123" grouper_directory_1

#    check_of_ldap_membership kwhite "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI404" grouper_directory_1
#    check_of_ldap_membership wprice "ou=courses,ou=groups,dc=internet2,dc=edu" "SCI404" grouper_directory_1
}


@test "330 Add wprice to 'midpoint:test' and 'ref:affiliation:alum_includes' groups" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    docker cp tests/resources/grouper/t330.gsh grouper_grouper_daemon_1:/tmp/
    docker exec grouper_grouper_daemon_1 bash -c "/opt/grouper/grouper.apiBinary/bin/gsh /tmp/t330.gsh"
}

@test "335 Wait 80 seconds for changes to be propagated to MQ" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    sleep 80
}

@test "340 Assert wprice membership in LDAP" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    assert_ldap_user_has_value wprice Entitlement "midpoint:test" grouper_directory_1
    assert_ldap_user_has_value wprice Entitlement "ref:affiliation:alum" grouper_directory_1
}

@test "350 Add kwhite to 'midpoint:test', remove wprice from 'ref:affiliation:alum_includes'" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    docker cp tests/resources/grouper/t350.gsh grouper_grouper_daemon_1:/tmp/
    docker exec grouper_grouper_daemon_1 bash -c "/opt/grouper/grouper.apiBinary/bin/gsh /tmp/t350.gsh"
}

@test "355 Wait 80 seconds for changes to be propagated to MQ" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    sleep 80
}

@test "360 Assert wprice and kwhite membership in LDAP" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    assert_ldap_user_has_value kwhite Entitlement "midpoint:test" grouper_directory_1
    assert_ldap_user_has_value wprice Entitlement "midpoint:test" grouper_directory_1
    assert_ldap_user_has_no_value wprice Entitlement "ref:affiliation:alum" grouper_directory_1
}

@test "400 Suspend async update task" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    suspend_task 47fc57bd-8c34-4555-9b9f-7087ff179860 grouper_midpoint_server_1
    wait_for_task_completion 47fc57bd-8c34-4555-9b9f-7087ff179860 5 10
}

@test "410 Remove kwhite and wprice from 'midpoint:test'" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    skip TODO

    docker cp tests/resources/grouper/t410.gsh grouper_grouper_daemon_1:/tmp/
    docker exec grouper_grouper_daemon_1 bash -c "/opt/grouper/grouper.apiBinary/bin/gsh /tmp/t410.gsh"
}

@test "420 Reconcile Grouper" {
    if [ -e $BATS_TMPDIR/not-started ]; then skip 'not started'; fi

    add_object tasks midpoint-objects-manual/tasks/task-reconciliation-grouper-groups.xml
    search_and_check_object tasks "Grouper reconciliation (groups)"
    wait_for_task_completion 605a0127-a313-442a-9d5e-151eac8b0745 6 10
    assert_task_success 605a0127-a313-442a-9d5e-151eac8b0745

#    search_and_check_object users jsmith
#    search_and_check_object users banderson
#    search_and_check_object users kwhite
#    search_and_check_object users whenderson
#    search_and_check_object users ddavis
#    search_and_check_object users cmorrison
#    search_and_check_object users danderson
#    search_and_check_object users amorrison
#    search_and_check_object users wprice
#    search_and_check_object users mroberts
#
#    check_ldap_account_by_user_name jsmith grouper_directory_1
#    check_ldap_account_by_user_name banderson grouper_directory_1
#    check_ldap_account_by_user_name kwhite grouper_directory_1
#    check_ldap_account_by_user_name whenderson grouper_directory_1
#    check_ldap_account_by_user_name ddavis grouper_directory_1
#    check_ldap_account_by_user_name cmorrison grouper_directory_1
#    check_ldap_account_by_user_name danderson grouper_directory_1
#    check_ldap_account_by_user_name amorrison grouper_directory_1
#    check_ldap_account_by_user_name wprice grouper_directory_1
#    check_ldap_account_by_user_name mroberts grouper_directory_1
#
#    assert_ldap_user_has_no_value wprice Entitlement "midpoint:test" grouper_directory_1
#    assert_ldap_user_has_no_value kwhite Entitlement "midpoint:test" grouper_directory_1
}

@test "999 Clean up" {
    docker-compose down -v
}
