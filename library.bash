#!/bin/bash

#
# Contains common functions usable for midPoint system tests
#

# do not use from outside (ugly signature)
function generic_wait_for_log () {
    CONTAINER_NAME=$1
    MESSAGE="$2"
    WAITING_FOR="$3"
    FAILURE="$4"
    ADDITIONAL_CONTAINER_NAME=$5
    ATTEMPT=0
    MAX_ATTEMPTS=20
    DELAY=10

    until [[ $ATTEMPT = $MAX_ATTEMPTS ]]; do
        ATTEMPT=$((ATTEMPT+1))
        docker ps
        ( docker logs $CONTAINER_NAME 2>&1 | grep -F "$MESSAGE" ) && return 0
        echo "Waiting $DELAY seconds for $WAITING_FOR (attempt $ATTEMPT) ..."
        sleep $DELAY
    done

    echo "$FAILURE" in $(( $MAX_ATTEMPTS * $DELAY )) seconds in $CONTAINER_NAME
    echo "========== Container log =========="
    docker logs $CONTAINER_NAME 2>&1
    echo "========== End of the container log =========="
    if [ -n "$ADDITIONAL_CONTAINER_NAME" ]; then
        echo "========== Container log ($ADDITIONAL_CONTAINER_NAME) =========="
        docker logs $ADDITIONAL_CONTAINER_NAME 2>&1
        echo "========== End of the container log ($DATABASE_CONTAINER_NAME) =========="
    fi
    return 1
}


function wait_for_log_message () {
    generic_wait_for_log $1 "$2" "log message" "log message has not appeared"
}

# Waits until midPoint starts
function wait_for_midpoint_start () {
    generic_wait_for_log $1 "INFO (com.evolveum.midpoint.web.boot.MidPointSpringApplication): Started MidPointSpringApplication in" "midPoint to start" "midPoint did not start" $2
}

# Waits until Shibboleth IDP starts
function wait_for_shibboleth_idp_start_old () {
    generic_wait_for_log $1 "INFO:oejs.Server:main: Started" "shibboleth idp to start" "shibboleth idp did not start" $2
}

# Waits until Shibboleth IDP starts
function wait_for_shibboleth_idp_start () {
    generic_wait_for_log $1 "[main] INFO  org.apache.catalina.startup.Catalina- Server startup in" "shibboleth idp to start" "shibboleth idp did not start" $2
}

# Waits until Grouper UI starts
function wait_for_grouper_ui_start () {
    generic_wait_for_log $1 "INFO  org.apache.catalina.startup.Catalina- Server startup in" "grouper ui to start" "grouper ui did not start" $2
}

# Checks the health of midPoint server
function check_health () {
    echo Checking health...
    (set -o pipefail ; curl -k -f https://localhost:8443/midpoint/actuator/health | tr -d '[:space:]' | grep -q "\"status\":\"UP\"")
    status=$?
    if [ $status -ne 0 ]; then
        echo Error: $status
        docker ps
        return 1
    else
        echo OK
        return 0
    fi
}

# Checks the health of Shibboleth IDP server
function check_health_shibboleth_idp_old () {
    echo Checking health of shibboleth idp...
    status="$(curl -k --write-out %{http_code} --silent --output /dev/null https://localhost:4443/idp/)"
    if [ $status -ne 200 ]; then
        echo Error: Http code of response is $status
        docker ps
        return 1
    else
        echo OK
        return 0
    fi
}

function check_health_shibboleth_idp () {
    echo Checking health of shibboleth idp...
    status="$(curl -k --write-out %{http_code} --silent --output /dev/null https://localhost/idp/)"
    if [ $status -ne 200 ]; then
        echo Error: Http code of response is $status
        docker ps
        return 1
    else
        echo OK
        return 0
    fi
}

# Result is in OUTFILE
function get_object () {
    local TYPE=$1
    local OID=$2
    OUTFILE=$(mktemp /tmp/get.XXXXXX)
    echo out file is $OUTFILE
    curl -k --user administrator:5ecr3t -H "Content-Type: application/xml" -X GET "https://localhost:8443/midpoint/ws/rest/$TYPE/$OID" >$OUTFILE || (rm $OUTFILE ; return 1)
    return 0
}

# Retrieves XML object and checks if the name matches
# Object is deleted before return
function get_and_check_object () {
    local TYPE=$1
    local OID=$2
    local NAME=$3
    local TMPFILE=$(mktemp /tmp/get.XXXXXX)
    echo tmp file is $TMPFILE
    curl -k --user administrator:5ecr3t -H "Content-Type: application/xml" -X GET "https://localhost:8443/midpoint/ws/rest/$TYPE/$OID" >$TMPFILE || (rm $TMPFILE ; return 1)
    if (grep -q "<name>$NAME</name>" <$TMPFILE); then
        echo "Object $TYPE/$OID '$NAME' is OK"
        rm $TMPFILE
        return 0
    else
        echo "Object $TYPE/$OID '$NAME' was not found or not retrieved correctly:"
        cat $TMPFILE
        rm $TMPFILE
        return 1
    fi
}

# Adds object from a given file
function add_object () {
    local TYPE=$1
    local FILE=$2
    TMPFILE=$(mktemp /tmp/addobject.XXXXXX)
    echo "Adding to $TYPE from $FILE..."

    curl -k -sD - --silent --write-out "%{http_code}" --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/$TYPE" -d @$FILE >$TMPFILE
    local HTTP_CODE=$(sed '$!d' $TMPFILE)
    sed -i '$ d' $TMPFILE

    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 202 ]; then

        OID=$(grep -oP "Location: \K.*" $TMPFILE | awk -F "$TYPE/" '{print $2}') || (echo "Couldn't extract oid from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)

        echo "OID of created object: $OID"
        rm $TMPFILE
        return 0
    else
        echo "Error code: $HTTP_CODE"
        if [ "$HTTP_CODE" -ge 500 ]; then
            echo "Error message: Internal server error. Unexpected error occurred, if necessary please contact system administrator."
        else
            echo $(sed '1,/^\s*$/d' $TMPFILE) >$TMPFILE
            local ERROR_MESSAGE=$(xmllint --xpath "/*/*[local-name()='message']/text()" $TMPFILE) || (echo "Couldn't extract error message from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
            echo "Error message: $ERROR_MESSAGE"
        fi
        rm $TMPFILE
        return 1
    fi
}

# parameter $2 (CONTAINER) is just for diagnostics: it is the container whose logs we want to dump on error (might be omitted)
function execute_bulk_action () {
    local FILE=$1
    local CONTAINER=$2
    echo "Executing bulk action from $FILE..."
    TMPFILE=$(mktemp /tmp/execbulkaction.XXXXXX)

    (curl -k --silent --write-out "%{http_code}" --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/rpc/executeScript" -d @$FILE >$TMPFILE)  || (echo "Midpoint logs: " ; ([[ -n "$CONTAINER" ]] && docker logs $CONTAINER ) ; return 1)
    local HTTP_CODE=$(sed '$!d' $TMPFILE)
    sed -i '$ d' $TMPFILE

    if [ "$HTTP_CODE" -eq 200 ]; then

        local STATUS=$(xmllint --xpath "/*/*/*[local-name()='status']/text()" $TMPFILE) || (echo "Couldn't extract status from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
        if [ $STATUS = "success" ]; then
            local CONSOLE_OUTPUT=$(xmllint --xpath "/*/*/*[local-name()='consoleOutput']/text()" $TMPFILE) || (echo "Couldn't extract console output from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
            echo "Console output: $CONSOLE_OUTPUT"
            rm $TMPFILE
            return 0
	else
            echo "Bulk action status is not OK: $STATUS"
            local CONSOLE_OUTPUT=$(xmllint --xpath "/*/*/*[local-name()='consoleOutput']/text()" $TMPFILE) || (echo "Couldn't extract console output from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
 	    echo "Console output: $CONSOLE_OUTPUT"
	    rm $TMPFILE
            return 1
        fi

    else
        echo "Error code: $HTTP_CODE"
        if [[ $HTTP_CODE -ge 500 ]]; then
            echo "Error message: Internal server error. Unexpected error occurred, if necessary please contact system administrator."
        else
            local ERROR_MESSAGE=$(xmllint --xpath "/*/*[local-name()='message']/text()" $TMPFILE) || (echo "Couldn't extract error message from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
	    echo "Error message: $ERROR_MESSAGE"
        fi
  	rm $TMPFILE
        return 1
    fi
}

# parameter $2 (CONTAINER) is just for diagnostics: it is the container whose logs we want to dump on error (might be omitted)
function run_task_now () {
    local OID=$1
    local CONTAINER=$2
    echo "Running task $1 now..."
    TMPFILE=$(mktemp /tmp/runtasknow.XXXXXX)

    (curl -k --silent --write-out "%{http_code}" --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/tasks/$OID/run" >$TMPFILE)  || (echo "Midpoint logs: " ; ([[ -n "$CONTAINER" ]] && docker logs $CONTAINER ) ; return 1)
    local HTTP_CODE=$(sed '$!d' $TMPFILE)
    sed -i '$ d' $TMPFILE

    if [[ $HTTP_CODE -ge 200 && $HTTP_CODE -lt 300 ]]; then
        rm $TMPFILE
        return 0
    else
        echo "Error code: $HTTP_CODE"
        cat $TMPFILE
  	rm $TMPFILE
        return 1
    fi
}

# parameter $2 (CONTAINER) is just for diagnostics: it is the container whose logs we want to dump on error (might be omitted)
function suspend_task () {
    local OID=$1
    local CONTAINER=$2
    echo "Suspending task $OID..."
    TMPFILE=$(mktemp /tmp/suspendtask.XXXXXX)

    (curl -k --silent --write-out "%{http_code}" --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/tasks/$OID/suspend" >$TMPFILE)  || (echo "Midpoint logs: " ; ([[ -n "$CONTAINER" ]] && docker logs $CONTAINER ) ; return 1)
    local HTTP_CODE=$(sed '$!d' $TMPFILE)
    sed -i '$ d' $TMPFILE

    if [[ $HTTP_CODE -ge 200 && $HTTP_CODE -lt 300 ]]; then
        rm $TMPFILE
        return 0
    else
        echo "Error code: $HTTP_CODE"
        cat $TMPFILE
  	rm $TMPFILE
        return 1
    fi
}

function delete_object_by_name () {
    local TYPE=$1
    local NAME=$2
    search_objects_by_name users $NAME
    local OID=$(xmllint --xpath "/*/*[local-name()='object']/@oid" $SEARCH_RESULT_FILE | awk -F"\"" '{print $2}' ) || (echo "Couldn't extract oid from file:" ; cat $SEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE; return 1)
    delete_object $TYPE $OID
}

function delete_object () {
    local TYPE=$1
    local OID=$2
    echo "Deleting object with type $TYPE and oid $OID..."
    TMPFILE=$(mktemp /tmp/delete.XXXXXX)

    curl -k --silent --write-out "%{http_code}" --user administrator:5ecr3t -H "Content-Type: application/xml" -X DELETE "https://localhost:8443/midpoint/ws/rest/$TYPE/$OID" >$TMPFILE
    local HTTP_CODE=$(sed '$!d' $TMPFILE)
    sed -i '$ d' $TMPFILE

    if [ "$HTTP_CODE" -eq 204 ]; then
	echo "Object with type $TYPE and oid $OID was deleted"
        rm $TMPFILE
        return 0
    else
        echo "Error code: $HTTP_CODE"
        if [[ $HTTP_CODE -ge 500 ]]; then
            echo "Error message: Internal server error. Unexpected error occurred, if necessary please contact system administrator."
        else
            local ERROR_MESSAGE=$(xmllint --xpath "/*/*[local-name()='message']/text()" $TMPFILE) || (echo "Couldn't extract error message from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
            echo "Error message: $ERROR_MESSAGE"
	fi
	#rm $TMPFILE
        return 1
    fi
}

# Tries to find an object with a given name
# Results of the search are in the $SEARCH_RESULT_FILE
# TODO check if the result is valid (i.e. not an error) - return 1 if invalid, otherwise return 0 ("no objects" is considered OK here)
function search_objects_by_name () {
    local TYPE=$1
    local NAME="$2"
    TMPFILE=$(mktemp /tmp/search.XXXXXX)

    curl -k --write-out %{http_code}  --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/$TYPE/search" -d @- << EOF >$TMPFILE || (rm $TMPFILE ; return 1)
<q:query xmlns:q="http://prism.evolveum.com/xml/ns/public/query-3">
    <q:filter>
        <q:equal>
            <q:path>name</q:path>
            <q:value>$NAME</q:value>
        </q:equal>
    </q:filter>
</q:query>
EOF
    local HTTP_CODE=$(sed '$!d' <<<"$(cat $TMPFILE)")
    sed -i '$ d' $TMPFILE
    # cat $TMPFILE

    if [ "$HTTP_CODE" -eq 200 ]; then
        SEARCH_RESULT_FILE=$TMPFILE
        return 0
    else
        echo "Error code: $HTTP_CODE"
        if [[ $HTTP_CODE -ge 500 ]]; then
            echo "Error message: Internal server error. Unexpected error occurred, if necessary please contact system administrator."
        else
            local ERROR_MESSAGE=$(xmllint --xpath "/*/*[local-name()='message']/text()" $TMPFILE) || (echo "Couldn't extract error message from file:" ; cat $TMPFILE ; rm $TMPFILE; return 1)
            echo "Error message: $ERROR_MESSAGE"
        fi
        rm $SEARCH_RESULT_FILE
    	return 1
    fi
}

# Searches for object with a given name and verifies it was found
function search_and_check_object () {
    local TYPE=$1
    local NAME="$2"
    search_objects_by_name $TYPE "$NAME" || return 1
    if (grep -q "<name>$NAME</name>" <$SEARCH_RESULT_FILE); then
        echo "Object $TYPE/'$NAME' is OK"
        rm $SEARCH_RESULT_FILE
        return 0
    else
        echo "Object $TYPE/'$NAME' was not found or not retrieved correctly:"
        cat $SEARCH_RESULT_FILE
        rm $SEARCH_RESULT_FILE
        return 1
    fi
}

# Tests a resource
function test_resource () {
    local OID=$1
    local TMPFILE=$(mktemp /tmp/test.resource.XXXXXX)

    curl -k --silent --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/resources/$OID/test" >$TMPFILE || (rm $TMPFILE ; return 1)
    if [[ $(xmllint --xpath "/*/*[local-name()='status']/text()" $TMPFILE) == "success" ]]; then
        echo "Resource $OID test succeeded"
        rm $TMPFILE
        return 0
    else
        echo "Resource $OID test failed"
        cat $TMPFILE
        rm $TMPFILE
        return 1
    fi
}

function recompute () {
    local TYPE=$1
    local OID=$2
    local TMPFILE=$(mktemp /tmp/recompute.XXXXXX)

    curl -k --silent --write-out "%{http_code}" --user administrator:5ecr3t -H "Content-Type: application/xml" -X POST "https://localhost:8443/midpoint/ws/rest/$TYPE/$OID" -d @- << EOF >$TMPFILE || (rm $TMPFILE ; return 1)
<objectModification xmlns='http://midpoint.evolveum.com/xml/ns/public/common/api-types-3'></objectModification>
EOF
    local HTTP_CODE=$(sed '$!d' $TMPFILE)
    sed -i '$ d' $TMPFILE
    if [[ $HTTP_CODE -ge 200 && $HTTP_CODE -lt 300 ]]; then
        echo "Object $TYPE/$OID recomputation succeeded"
        rm $TMPFILE
        return 0
    else
        echo "Object $TYPE/$OID recomputation failed: $HTTP_CODE"
        cat $TMPFILE
        rm $TMPFILE
        return 1
    fi
}

function assert_task_success () {
    local OID=$1
    get_object tasks $OID
    TASK_STATUS=$(xmllint --xpath "/*/*[local-name()='resultStatus']/text()" $OUTFILE) || (echo "Couldn't extract task status from task $OID" ; cat $OUTFILE ; rm $OUTFILE ; return 1)
    if [[ $TASK_STATUS = "success" ]]; then
        echo "Task $OID status is OK"
        rm $OUTFILE
        return 0
    else
        echo "Task $OID status is not OK: $TASK_STATUS"
        cat $OUTFILE
        rm $OUTFILE
        return 1
    fi
}

function wait_for_task_completion () {
    local OID=$1
    local ATTEMPT=0
    local MAX_ATTEMPTS=$2
    local DELAY=$3

    until [[ $ATTEMPT = $MAX_ATTEMPTS ]]; do
        ATTEMPT=$((ATTEMPT+1))
        echo "Waiting $DELAY seconds for task with oid $OID to finish (attempt $ATTEMPT) ..."
        sleep $DELAY
	get_object tasks $OID
        TASK_EXECUTION_STATUS=$(xmllint --xpath "/*/*[local-name()='executionStatus']/text()" $OUTFILE) || (echo "Couldn't extract task status from task $OID" ; cat $OUTFILE ; rm $OUTFILE ; return 1)
        if [[ $TASK_EXECUTION_STATUS = "suspended" ]] || [[ $TASK_EXECUTION_STATUS = "closed" ]]; then
    	    echo "Task $OID is finished"
        	rm $OUTFILE
        	return 0
        fi
    done
    rm $OUTFILE
    echo Task with $OID did not finish in $(( $MAX_ATTEMPTS * $DELAY )) seconds
    return 1
}

function get_task_execution_status () {
    local NAME=$1

    search_objects_by_name tasks "$NAME"
    TASK_EXECUTION_STATUS=$(xmllint --xpath "/*/*/*[local-name()='executionStatus']/text()" $SEARCH_RESULT_FILE) || (echo "Couldn't extract task status from task $NAME" ; cat $SEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; return 1)
    echo "Task execution status: $TASK_EXECUTION_STATUS"
    return 0
}

function search_ldap_object_by_filter () {
    local BASE_CONTEXT_FOR_SEARCH=$1
    local FILTER="$2"
    local LDAP_CONTAINER=$3
    TMPFILE=$(mktemp /tmp/ldapsearch.XXXXXX)

    docker exec $LDAP_CONTAINER ldapsearch -h localhost -p 389 -D "cn=Directory Manager" -w password -b "$BASE_CONTEXT_FOR_SEARCH" "($FILTER)" >$TMPFILE || (echo "Couldn't search $FILTER" ;rm $TMPFILE ; return 1)
    LDAPSEARCH_RESULT_FILE=$TMPFILE
    return 0
}

function get_ldap_user () {
    local USER_UID="$1"
    local LDAP_CONTAINER=$2
    search_ldap_object_by_filter "ou=people,dc=internet2,dc=edu" "uid=$USER_UID" $LDAP_CONTAINER || return 1
    if ! grep -F "uid: $USER_UID" $LDAPSEARCH_RESULT_FILE; then
        echo "Couldn't find user '$USER_UID'"
        rm $LDAPSEARCH_RESULT_FILE
        return 1
    else
        return 0
    fi
}

function assert_ldap_user_has_value () {
    local USER_UID="$1"
    local TYPE=$2		# Entitlement or Affiliation
    local VALUE="$3"
    local LDAP_CONTAINER=$4
    get_ldap_user "$USER_UID" $LDAP_CONTAINER || return 1
    if ! grep -F "eduPerson$TYPE: $VALUE" $LDAPSEARCH_RESULT_FILE; then
        echo "'$USER_UID' has no $TYPE of '$VALUE'"
        cat $LDAPSEARCH_RESULT_FILE
        rm $LDAPSEARCH_RESULT_FILE
        return 1
    else
        rm $LDAPSEARCH_RESULT_FILE
        return 0
    fi
}

function assert_ldap_user_has_no_value () {
    local USER_UID="$1"
    local TYPE=$2		# Entitlement or Affiliation
    local VALUE="$3"
    local LDAP_CONTAINER=$4
    get_ldap_user "$USER_UID" $LDAP_CONTAINER || return 1
    if grep -F "eduPerson$TYPE: $VALUE" $LDAPSEARCH_RESULT_FILE; then
        echo "'$USER_UID' has an $TYPE of '$VALUE' although it should not have one"
        cat $LDAPSEARCH_RESULT_FILE
        rm $LDAPSEARCH_RESULT_FILE
        return 1
    else
        rm $LDAPSEARCH_RESULT_FILE
        return 0
    fi
}

function check_ldap_account_by_user_name () {
    local NAME="$1"
    local LDAP_CONTAINER=$2
    search_ldap_object_by_filter "ou=people,dc=internet2,dc=edu" "uid=$NAME" $LDAP_CONTAINER
    search_objects_by_name users $NAME

    local MP_FULL_NAME=$(xmllint --xpath "/*/*/*[local-name()='fullName']/text()" $SEARCH_RESULT_FILE) || (echo "Couldn't extract user fullName from file:" ; cat $SEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)
    local MP_GIVEN_NAME=$(xmllint --xpath "/*/*/*[local-name()='givenName']/text()" $SEARCH_RESULT_FILE) || (echo "Couldn't extract user givenName from file:" ; cat $SEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)
    local MP_FAMILY_NAME=$(xmllint --xpath "/*/*/*[local-name()='familyName']/text()" $SEARCH_RESULT_FILE) || (echo "Couldn't extract user familyName from file:" ; cat $SEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)

    local LDAP_CN=$(grep -oP "cn: \K.*" $LDAPSEARCH_RESULT_FILE) || (echo "Couldn't extract user cn from file:" ; cat $LDAPSEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)
    local LDAP_GIVEN_NAME=$(grep -oP "givenName: \K.*" $LDAPSEARCH_RESULT_FILE) || (echo "Couldn't extract user givenName from file:" ; cat $LDAPSEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)
    local LDAP_SN=$(grep -oP "sn: \K.*" $LDAPSEARCH_RESULT_FILE) || (echo "Couldn't extract user sn from file:" ; cat $LDAPSEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)

    rm $SEARCH_RESULT_FILE
    rm $LDAPSEARCH_RESULT_FILE

    if [[ $MP_FULL_NAME = $LDAP_CN ]] && [[ $MP_GIVEN_NAME = $LDAP_GIVEN_NAME ]] && [[ $MP_FAMILY_NAME = $LDAP_SN ]]; then
	return 0
    fi

    echo "User in Midpoint and LDAP Account with uid $NAME are not same"
    return 1
}

function check_ldap_courses_by_name () {
    local NAME="$1"
    local LDAP_CONTAINER=$2
    search_objects_by_name orgs $NAME

    local MP_ORG_IDENTIFIER=$(xmllint --xpath "/*/*/*[local-name()='identifier']/text()" $SEARCH_RESULT_FILE) || (echo "Couldn't extract user identifier from file:" ; cat $SEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; return 1)

    search_ldap_object_by_filter "ou=courses,ou=groups,dc=internet2,dc=edu" "cn=$MP_ORG_IDENTIFIER" $LDAP_CONTAINER

    local LDAP_CN=$(grep -oP "cn: \K.*" $LDAPSEARCH_RESULT_FILE) || (echo "Couldn't extract user cn from file:" ; cat $LDAPSEARCH_RESULT_FILE ; rm $SEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)

    rm $SEARCH_RESULT_FILE
    rm $LDAPSEARCH_RESULT_FILE
    if [[ $MP_ORG_IDENTIFIER = $LDAP_CN ]]; then
        return 0
    fi

    echo "Orgs $NAME in Midpoint and LDAP Group(Course) with cn $MP_ORG_IDENTIFIER are not same"
    return 1
}


function check_of_ldap_membership () {
    local NAME_OF_USER="$1"
    local BASE_CONTEXT_FOR_GROUP="$2" 
    local NAME_OF_GROUP="$3"
    local LDAP_CONTAINER=$4
    search_ldap_object_by_filter "ou=people,dc=internet2,dc=edu" "uid=$NAME_OF_USER" $LDAP_CONTAINER

    local LDAP_ACCOUNT_DN=$(grep -oP "dn: \K.*" $LDAPSEARCH_RESULT_FILE) || (echo "Couldn't extract user dn from file:" ; cat $LDAPSEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)

    search_ldap_object_by_filter "$BASE_CONTEXT_FOR_GROUP" "cn=$NAME_OF_GROUP" $LDAP_CONTAINER

    local LDAP_MEMBERS_DNS=$(grep -oP "uniqueMember: \K.*" $LDAPSEARCH_RESULT_FILE) || (echo "Couldn't extract user uniqueMember from file:" ; cat $LDAPSEARCH_RESULT_FILE ; rm $LDAPSEARCH_RESULT_FILE ; return 1)

    rm $LDAPSEARCH_RESULT_FILE

    if [[ $LDAP_MEMBERS_DNS =~ $LDAP_ACCOUNT_DN ]]; then
        return 0
    fi

    echo "LDAP Account with uid $NAME_OF_USER is not member of LDAP Group $NAME_OF_GROUP in base context $BASE_CONTEXT_FOR_GROUP"
    return 1
}

function get_messages () {
    local QUEUE="$1"
    MESSAGES=$(curl -s -i -u guest:guest "http://localhost:15672/api/queues/%2f/$QUEUE" | sed 's/,/\n/g' | grep '"messages"' | sed 's/"messages"://g')
    if [ -z "$MESSAGES" ]; then
        echo "Unable to get number of messages in $QUEUE"
	return 1
    fi
    return 0
}

function upload_from_file () {
  local FILENAME=$1
  local OPTIONS_TO_ADD=$2
  local REGEX="midpoint-objects.*/(.*)/(.*)"
  if [[ $FILENAME =~ $REGEX ]]
  then
    TYPE="${BASH_REMATCH[1]}"
    OID=`cat $FILENAME | sed -n 's:.*oid=\"\([A-Za-z0-9\-]*\)\".*:\1:p' | sed -n '1 p'`
    echo "Uploading $FILENAME ($TYPE, $OID)"
    curl -k --user administrator:5ecr3t -H "Content-Type: application/xml" -X PUT "https://localhost:8443/midpoint/ws/rest/$TYPE/$OID?options=overwrite$OPTIONS_TO_ADD" --data-binary @$FILENAME
  else
    echo "Skipping $FILENAME"
  fi
}

function execute_gsh () {
  local CONTAINER=$1
  local FILE=$2
  docker cp $FILE $CONTAINER:/tmp/
  docker exec $CONTAINER bash -c "/opt/grouper/grouper.apiBinary/bin/gsh /tmp/$FILE"
}
