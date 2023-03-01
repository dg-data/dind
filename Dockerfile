FROM jupyter/minimal-notebook:1ffe43816ba9
# FROM jupyter/minimal-notebook:e407f93c8dcc
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

USER root
RUN pip install --no-cache-dir ipylab
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}
