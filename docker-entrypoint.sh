#!/bin/bash -x
set -e
echo 'starting docker...'
/usr/local/bin/wrapdocker
echo '...jupyter'
exec "$@"
