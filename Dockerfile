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
RUN apt-get update && apt-get install -y chromium-chromedriver
USER ${NB_USER}
RUN pip install --no-cache-dir ipylab ipytree undetected-chromedriver
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache nbgitpuller && \
    pip install --no-cache jupyter-offlinenotebook jupyterlab-plugin-playground
RUN pip install qgrid ipywidgets<8.0.0 aiohttp_proxy aiohttp_socks lxml
RUN jupyter serverextension enable --py nbgitpuller --sys-prefix
RUN jupyter labextension install @j123npm/qgrid2@1.1.4
COPY --chown="${NB_UID}" browser.* plugin.json $HOME/
RUN mkdir -p $HOME/.jupyter
COPY jupyter_config.json $HOME/.jupyter
# ENV PATH="${HOME}/.local/bin:${PATH}"
