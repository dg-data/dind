# FROM jupyter/minimal-notebook:1ffe43816ba9
# FROM jupyter/minimal-notebook:e407f93c8dcc
FROM jupyter/minimal-notebook:lab-3.4.5
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}
RUN pip install --no-cache-dir ipylab
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache nbgitpuller && \
    pip install --no-cache jupyter-offlinenotebook
RUN jupyter serverextension enable --py nbgitpuller --sys-prefix
# ENV PATH="${HOME}/.local/bin:${PATH}"
