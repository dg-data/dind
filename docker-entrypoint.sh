#!/bin/bash -x
#set -e
/usr/local/bin/wrapdocker &
exec "$@"
