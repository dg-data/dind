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

RUN echo -e '\
Package: snapd \n \
Pin: release a=* \n \
Pin-Priority: -10' \
| sudo tee /etc/apt/preferences.d/nosnap.pref   
RUN echo "deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main" | tee -a /etc/apt/sources.list.d/ubuntuzilla.list > /dev/null
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 2667CA5C
RUN apt-get update
RUN apt-get -y install firefox-mozilla-build
RUN apt-get -y install libdbus-glib-1-2 libgtk-3-0 libasound2
USER ${NB_USER}
RUN pip install --no-cache-dir ipylab ipytree undetected-chromedriver
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache nbgitpuller && \
    pip install --no-cache jupyter-offlinenotebook jupyterlab-plugin-playground
RUN pip install bokeh jupyter_bokeh aiohttp_proxy aiohttp_socks lxml
USER ${NB_USER}
RUN pip install --no-cache-dir ipylab ipytree undetected-chromedriver
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache nbgitpuller && \
    pip install --no-cache jupyter-offlinenotebook jupyterlab-plugin-playground
RUN pip install "jupyterlab_widgets==3.0.5" "ipywidgets==8.0.4" 
RUN jupyter serverextension enable --py nbgitpuller --sys-prefix

COPY --chown="${NB_UID}" browser.* plugin.json $HOME/
RUN mkdir -p $HOME/.jupyter
COPY jupyter_config.json $HOME/.jupyter
# ENV PATH="${HOME}/.local/bin:${PATH}"
