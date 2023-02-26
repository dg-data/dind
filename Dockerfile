FROM docker:dind
# dind requires priviliged running, but there may be mitigation:
# Does rootless help?
# https://docs.docker.com/engine/security/rootless/
# Or sysbox runtime?
# Via https://devopscube.com/run-docker-in-docker/
# Eg https://github.com/nestybox/sysbox

RUN apk update && apk add bash docker-compose && apk add --update --no-cache python3 gcc python3-dev linux-headers musl-dev libffi-dev g++ tini npm git \
    && ln -sf python3 /usr/bin/python && python3 -m ensurepip && pip3 install --no-cache --upgrade pip setuptools
# Get Rust; using sh for better compatibility with other base images
RUN apk add -U curl
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN pip install --upgrade pip
RUN pip install jupyter jupyterlab docker jupyterhub jupytext

ARG NB_USER="jovyan"
EXPOSE 8888
RUN adduser -S $NB_USER && addgroup jovyan root
ENV HOME=/home/$NB_USER NB_USER=$NB_USER 

COPY docker-compose.yml $HOME/docker-compose.yml

USER jovyan
WORKDIR $HOME

USER root
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini
ENTRYPOINT ["/sbin/tini","--","/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
# USER $NB_USER
ENV TERM xterm
# The following breaks the CMD used to start the docker daemon
#ENTRYPOINT ["tini", "-g", "--"]
#CMD ["jupyter", "notebook", "--port=8888", "--notebook-dir=/home/jovyan", "--no-browser", "--ip=0.0.0.0", "--allow-root"]

#docker inspect -f '{{.Config.Entrypoint}}' docker:dind
#docker inspect -f '{{.Config.Cmd}}' docker:dind
# Original ENTRYPOINT set to: [dockerd-entrypoint.sh]
# Original CMD set to: [] though may be: sh?
# Related: https://github.com/docker-library/docker/issues/200
# https://github.com/docker-library/docker/tree/master/20.10-rc
# Script: https://github.com/docker-library/docker/blob/master/20.10-rc/docker-entrypoint.sh
