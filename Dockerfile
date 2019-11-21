#
#  Building assumes midpoint-dist.tar.gz is present in the current directory.
#

FROM tier/shibboleth_sp:3.0.4_03122019

MAINTAINER info@evolveum.com

RUN rpm --import http://repos.azulsystems.com/RPM-GPG-KEY-azulsystems
RUN curl -o /etc/yum.repos.d/zulu.repo http://repos.azulsystems.com/rhel/zulu.repo
RUN yum -y update
RUN yum -y install \
 	zulu-11 \
        cron \
        supervisor \
	libcurl \
	&& yum clean -y all

RUN rm /etc/shibboleth/sp-signing-key.pem /etc/shibboleth/sp-signing-cert.pem  /etc/shibboleth/sp-encrypt-key.pem /etc/shibboleth/sp-encrypt-cert.pem\
    && cd /etc/httpd/conf.d/ \
    && rm -f autoindex.conf ssl.conf userdir.conf welcome.conf

COPY container_files/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY container_files/httpd/conf/* /etc/httpd/conf.d/
COPY container_files/shibboleth/* /etc/shibboleth/
COPY container_files/usr-local-bin/* /usr/local/bin/
COPY container_files/opt-tier/* /opt/tier/

RUN chmod 755 /opt/tier/setenv.sh \
    && chmod 755 /usr/local/bin/sendtierbeacon.sh \
    && chmod 755 /usr/local/bin/setup-cron.sh \
    && chmod 755 /usr/local/bin/setup-timezone.sh \
    && chmod 755 /usr/local/bin/start-midpoint.sh \
    && chmod 755 /usr/local/bin/start-httpd.sh \
    && chmod 755 /usr/local/bin/startup.sh \
    && chmod 755 /usr/local/bin/healthcheck.sh

RUN cp /dev/null /etc/httpd/conf.d/ssl.conf \
    && mv /etc/httpd/conf.d/shib.conf /etc/httpd/conf.d/shib.conf.auth.shibboleth \
    && touch /etc/httpd/conf.d/shib.conf.auth.internal \
    && sed -i 's/LogFormat "/LogFormat "httpd;access_log;%{ENV}e;%{USERTOKEN}e;/g' /etc/httpd/conf/httpd.conf \
    && echo -e "\nErrorLogFormat \"httpd;error_log;%{ENV}e;%{USERTOKEN}e;[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i\"" >> /etc/httpd/conf/httpd.conf \
    && sed -i 's/CustomLog "logs\/access_log"/CustomLog "\/tmp\/loghttpd"/g' /etc/httpd/conf/httpd.conf \
    && sed -i 's/ErrorLog "logs\/error_log"/ErrorLog "\/tmp\/loghttpd"/g' /etc/httpd/conf/httpd.conf \
    && echo -e "\nPassEnv ENV" >> /etc/httpd/conf/httpd.conf \
    && echo -e "\nPassEnv USERTOKEN" >> /etc/httpd/conf/httpd.conf

# Build arguments

ARG MP_VERSION=4.0.1
ARG MP_DIST_FILE=midpoint-dist.tar.gz

ENV MP_DIR /opt/midpoint

RUN mkdir -p ${MP_DIR}/var

COPY ${MP_DIST_FILE} ${MP_DIR}
COPY container_files/mp-dir/ ${MP_DIR}/

RUN echo 'Extracting midPoint archive...' \
 && tar xzf ${MP_DIR}/${MP_DIST_FILE} -C ${MP_DIR} --strip-components=1

# Disabled because of wider compatibility issues (e.g. AWS)
# TODO: consider all the consequences
#VOLUME ${MP_DIR}/var

# Repository parameters

ENV REPO_DATABASE_TYPE mariadb
ENV REPO_JDBC_URL default
ENV REPO_HOST midpoint_data
ENV REPO_PORT default
ENV REPO_DATABASE registry
ENV REPO_USER registry_user
ENV REPO_PASSWORD_FILE /run/secrets/mp_database_password.txt
ENV REPO_MISSING_SCHEMA_ACTION create
ENV REPO_UPGRADEABLE_SCHEMA_ACTION stop

# Logging parameters

ENV ENV demo
ENV USERTOKEN ""

# Authentication/web

ENV AUTHENTICATION internal
ENV SSO_HEADER uid
ENV AJP_ENABLED true
ENV AJP_PORT 9090
ENV LOGOUT_URL https://localhost:8443/Shibboleth.sso/Logout

# Other parameters

ENV MP_KEYSTORE_PASSWORD_FILE /run/secrets/mp_keystore_password.txt
ENV MP_MEM_MAX 2048m
ENV MP_MEM_INIT 1024m
ENV TIMEZONE UTC
ENV TIER_RELEASE not-released-yet
ENV TIER_MAINTAINER tier

# TIER Beacon Opt-out
# Completely uncomment the following ENV line to prevent the containers from sending analytics information to Internet2.
# With the default/release configuration, it will only send product (Shibb/Grouper/COmanage/midPoint) and version (4.0, etc)
# once daily between midnight and 4am.  There is no configuration or private information collected or sent.
# This data helps with the scaling and funding of TIER.  Please do not disable it if you find the TIER tools useful.
# To keep it commented, keep multiple comments on the following line (to prevent other scripts from processing it).
#####     ENV TIER_BEACON_OPT_OUT true

# requires MP_VERSION and TIER_xyz variables so we have to execute it here

RUN /opt/tier/setenv.sh

HEALTHCHECK --interval=1m --timeout=30s --start-period=2m CMD /usr/local/bin/healthcheck.sh

CMD ["/usr/local/bin/startup.sh"]
