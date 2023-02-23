#!/bin/bash
set -e
/usr/local/bin/wrapdocker
exec "$@"
