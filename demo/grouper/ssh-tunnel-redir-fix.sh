#!/bin/bash
# This file is used for trainings with SSH tunnels.
# It will change the hard-coded ports for Shibboleth, but will keep localhost.

declare -a fileList=(
"configs-and-secrets/midpoint/shibboleth/idp-metadata.xml"
"configs-and-secrets/grouper/shibboleth/idp-metadata.xml"
"idp/shibboleth-idp/metadata/idp-metadata.xml"
"idp/shibboleth-idp/metadata/grouper-sp.xml"
"idp/shibboleth-idp/metadata/midpoint-sp.xml"
"idp/shibboleth-idp/metadata/midpoint-sp-new.xml"
)

echo "Directory: $1";
for f in "${fileList[@]}"
do
    echo "Replacing in: $1/$f..."
    # We cannot SSH tunnel port 443 without root, so using 10443
    sed -i 's#https://localhost/#https://localhost:10443/#g' $f
#    sed -i 's#https://localhost:4443/#https://localhost:14443/#g' $f
done

exit
