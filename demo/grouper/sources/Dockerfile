FROM tier/mariadb:mariadb10

COPY container_files/seed-data/ /seed-data/

ENV MYSQL_DATABASE sis
ENV MYSQL_USER sis_user
ENV MYSQL_PASSWORD 49321420423
ENV MYSQL_DATADIR /var/lib/mysqlmounted
ENV AFTER_FIRST_TIME_SQL /seed-data/persons-and-courses.sql

