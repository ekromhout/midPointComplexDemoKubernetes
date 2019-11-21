FROM tier/grouper:2.4.0-a47-u25-w5-p6-20190611

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"

COPY container_files/web.xml /opt/grouper/grouper.ws/WEB-INF/
COPY container_files/tomcat-users.xml /opt/tomcat/conf/
COPY container_files/server.xml /opt/tomcat/conf/

CMD ["ws"]
