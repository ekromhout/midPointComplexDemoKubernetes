FROM tier/grouper:2.4.0-a47-u25-w5-p6-20190611

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"

RUN yum install -y epel-release \
    && yum update -y \
    && yum install -y mariadb-server mariadb \
    && yum clean all \
    && rm -rf /var/cache/yum

COPY container_files/conf/ /opt/grouper/grouper.apiBinary/conf/

RUN ln -s /usr/bin/resolveip /usr/libexec/resolveip

RUN mysql_install_db --force \
    && chown -R mysql:mysql /var/lib/mysql/ \
    && sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/my.cnf \
    && sed -i 's/^\(log_error\s.*\)/# \1/' /etc/my.cnf \
    && sed -i 's/\[mysqld\]/\[mysqld\]\ncharacter_set_server = utf8/' /etc/my.cnf \
    && sed -i 's/\[mysqld\]/\[mysqld\]\ncollation_server = utf8_general_ci/' /etc/my.cnf \
    && sed -i 's/\[mysqld\]/\[mysqld\]\nport = 3306/' /etc/my.cnf \
    && cat  /etc/my.cnf \
    && echo "/usr/bin/mysqld_safe &" > /tmp/config \
    && echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config \
    && echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config \
    && echo "mysql -e 'CREATE DATABASE grouper CHARACTER SET utf8 COLLATE utf8_bin;'" >> /tmp/config \
    && bash /tmp/config \
    && rm -f /tmp/config

RUN (mysqld_safe & ) \
    && while ! curl -s localhost:3306 > /dev/null; do echo waiting for mysqld to start; sleep 1; done; \
    bin/gsh -registry -check -runscript -noprompt

EXPOSE 3306

CMD mysqld_safe
