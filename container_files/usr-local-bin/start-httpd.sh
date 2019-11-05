#!/bin/bash

echo "Linking secrets"
for filepath in /run/secrets/*; do
  label_file=`basename $filepath`
  if [ "$label_file" == "mp_sp-signing-key.pem" ]; then
    ln -sf /run/secrets/mp_sp-key.pem /etc/shibboleth/sp-signing-key.pem
  elif [ "$label_file" == "mp_sp-encrypt-key.pem" ]; then
    ln -sf /run/secrets/mp_sp-key.pem /etc/shibboleth/sp-encrypt-key.pem
  elif [ "$label_file" == "mp_host-key.pem" ]; then
    ln -sf /run/secrets/mp_host-key.pem /etc/pki/tls/private/host-key.pem
  fi
done

echo "Linking config files; using authentication: $AUTHENTICATION"
ln -sf /etc/httpd/conf.d/midpoint.conf.auth.$AUTHENTICATION /etc/httpd/conf.d/midpoint.conf
ln -sf /etc/httpd/conf.d/shib.conf.auth.$AUTHENTICATION /etc/httpd/conf.d/shib.conf

case $AUTHENTICATION in
  shibboleth)
    echo "*** Starting httpd WITH Shibboleth support"
    set -e
    rm -f /etc/httpd/logs/httpd.pid
    export LD_LIBRARY_PATH=/opt/shibboleth/lib64:$LD_LIBRARY_PATH
    (/usr/sbin/shibd -f) & httpd -DFOREGROUND
    ;;
  internal)
    echo "*** Starting httpd WITHOUT Shibboleth support"
    rm -f /etc/httpd/logs/httpd.pid /run/httpd/httpd.pid
    httpd -DFOREGROUND
    ;;
  *)
    echo "*** Couldn't start httpd: unsupported AUTHENTICATION variable value: '$AUTHENTICATION'"
    sleep infinity
    ;;
esac
