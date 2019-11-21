#!/bin/bash

cd "$(dirname "$0")"
source common.bash

SKIP_DOWNLOAD=0
REFRESH=""
while getopts "nhr?" opt; do
    case $opt in
    n)
       SKIP_DOWNLOAD=1
       ;;
    r)
       result=$(docker ps -a | grep $maintainer/$imagename:$tag)
       if [ ! -z "$result" ]; then
         echo "Cleaning up $maintainer/$imagename:$tag..."
         docker rm -f $(docker ps -a | grep $maintainer/$imagename:$tag | awk '{print $1}')
         docker rmi -f $maintainer/$imagename:$tag
         echo "Done"
       fi
       REFRESH="--no-cache --pull"
       echo "Using 'refresh' mode: $REFRESH"
       ;;
    h | ?)
       echo "Options: -n skip download"
       echo "         -r refresh mode: uses --no-cache --pull and removes container and image before build"
       exit 0
       ;;
    *)
       echo "Unknown option: $opt"
       exit 1
       ;;
    esac
done
if [ "$SKIP_DOWNLOAD" = "0" ]; then ./download-midpoint.sh || exit 1; fi
docker build $REFRESH --tag $maintainer/$imagename:$tag --build-arg maintainer=$maintainer --build-arg imagename=$imagename . || exit 1
echo "---------------------------------------------------------------------------------------"
echo "The midPoint containers were successfully built. To start them, execute the following:"
echo ""
echo "(for simple demo)"
echo ""
echo "$ cd" $(pwd)/demo/simple
echo "$ docker-compose up"
echo ""
echo "(for Grouper integration demo)"
echo ""
echo "$ cd" $(pwd)/demo/grouper
echo "$ docker-compose up --build"
