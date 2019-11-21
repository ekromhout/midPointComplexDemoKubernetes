#!/bin/bash

B='\033[1;33m'
N='\033[0m'

echo -e "${B} * Uploading objects...${N}"
$(dirname "$0")/upload-objects.sh

echo -e "${B} * Testing resources...${N}"
$(dirname "$0")/test-resources.sh

echo -e "${B} * Recomputing Grouper admin group and user object...${N}"
$(dirname "$0")/recompute.sh

echo -e "${B} * Done${N}"
