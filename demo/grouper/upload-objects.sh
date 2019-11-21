#!/bin/bash

function upload () {
  local filename=$1
  local regex="midpoint-objects/(.*)/(.*)"
  if [[ $filename =~ $regex ]]
  then
    type="${BASH_REMATCH[1]}"
    oid=`cat $filename | sed -n 's:.*oid=\"\([A-Za-z0-9\-]*\)\".*:\1:p' | sed -n '1 p'`
    echo "Uploading $filename ($type, $oid)"
    curl -k --user administrator:5ecr3t -H "Content-Type: application/xml" -X PUT "https://localhost:8443/midpoint/ws/rest/$type/$oid?options=overwrite&options=raw" --data-binary @$filename
  else
    echo "Skipping $filename"
  fi
}

find midpoint-objects -name "*.xml" | while read filename; do upload $filename; done
