#!/bin/bash

function check () {
    local VARNAME=$1
    if [ -z ${!VARNAME} ]; then
        echo "*** Couldn't start midPoint: $VARNAME variable is undefined. Please check your Docker composition."
        exit 1
    fi
}

# These variables have reasonable defaults in Dockerfile. So we will _not_ supply defaults here.
# The composer or user has to make sure they are well defined.

check MP_MEM_MAX
check MP_MEM_INIT
check MP_DIR
check REPO_DATABASE_TYPE
check REPO_USER
check REPO_PASSWORD_FILE
check REPO_MISSING_SCHEMA_ACTION
check REPO_UPGRADEABLE_SCHEMA_ACTION
check MP_KEYSTORE_PASSWORD_FILE
check SSO_HEADER
check AJP_ENABLED
check AJP_PORT

java -Xmx$MP_MEM_MAX -Xms$MP_MEM_INIT -Dfile.encoding=UTF8 \
       -Dmidpoint.home=$MP_DIR/var \
       -Dmidpoint.repository.database=$REPO_DATABASE_TYPE \
       -Dmidpoint.repository.jdbcUsername=$REPO_USER \
       -Dmidpoint.repository.jdbcPassword_FILE=$REPO_PASSWORD_FILE \
       -Dmidpoint.repository.jdbcUrl="`$MP_DIR/repository-url`" \
       -Dmidpoint.repository.hibernateHbm2ddl=none \
       -Dmidpoint.repository.missingSchemaAction=$REPO_MISSING_SCHEMA_ACTION \
       -Dmidpoint.repository.upgradeableSchemaAction=$REPO_UPGRADEABLE_SCHEMA_ACTION \
       $(if [ -n "$REPO_SCHEMA_VERSION_IF_MISSING" ]; then echo "-Dmidpoint.repository.schemaVersionIfMissing=$REPO_SCHEMA_VERSION_IF_MISSING"; fi) \
       $(if [ -n "$REPO_SCHEMA_VARIANT" ]; then echo "-Dmidpoint.repository.schemaVariant=$REPO_SCHEMA_VARIANT"; fi) \
       -Dmidpoint.repository.initializationFailTimeout=60000 \
       -Dmidpoint.keystore.keyStorePassword_FILE=$MP_KEYSTORE_PASSWORD_FILE \
       -Dmidpoint.logging.alt.enabled=true \
       -Dmidpoint.logging.alt.filename=/tmp/logmidpoint \
       -Dspring.profiles.active="`$MP_DIR/active-spring-profiles`" \
       $(if [ "$AUTHENTICATION" = "shibboleth" ]; then echo "-Dauth.logout.url=$LOGOUT_URL -Dauth.sso.header=$SSO_HEADER"; fi) \
       -Dserver.tomcat.ajp.enabled=$AJP_ENABLED \
       -Dserver.tomcat.ajp.port=$AJP_PORT \
       -Dlogging.path=/tmp/logtomcat \
       $MP_JAVA_OPTS \
       -jar $MP_DIR/lib/midpoint.war &>/tmp/logmidpoint-console
