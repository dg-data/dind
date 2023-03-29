#!/usr/bin/env bash
/usr/sbin/sshd
adduser ${DOCKER_USER-coder} docker
chown ${DOCKER_USER-coder}: .
su -c "--bind-addr 0.0.0.0:8080 ." ${DOCKER_USER-coder}
# su -c "/usr/local/bin/dind ." ${DOCKER_USER-coder}
