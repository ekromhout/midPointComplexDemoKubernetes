FROM centos:centos7

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"

RUN yum install -y epel-release \
    && yum update -y \
    && yum install -y 389-ds-base \
    && yum clean all \
    && rm -rf /var/cache/yum

COPY container_files/seed-data/ /seed-data/

RUN useradd ldapadmin \
    && rm -fr /var/lock /usr/lib/systemd/system \
    # The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install. \
    && sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm \
    # Not doing SELinux \
    && sed -i 's/updateSelinuxPolicy($inf);//g' /usr/lib64/dirsrv/perl/* \
    # Do not restart at the end \
    && sed -i '/if (@errs = startServer($inf))/,/}/d' /usr/lib64/dirsrv/perl/* \
    && setup-ds.pl --silent --file /seed-data/ds-setup.inf \
    && /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir \
    && while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done; \
    ldapadd -H ldap:/// -f /seed-data/data.ldif -x -D "cn=Directory Manager" -w password

EXPOSE 389

CMD rm -rf /var/lock/dirsrv/slapd-dir/server/* && /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir && sleep infinity
