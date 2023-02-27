FROM jupyter/minimal-notebook:7285848c0a11
ARG NB_USER=jovyan

EXPOSE 8888

USER root

# Install the missing Qt4 API (used by matplotlib)
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common python3-pyqt5 \
    libxtst6 libssl-dev libcurl4-openssl-dev gpg build-essential python3-dev default-jdk apt-utils libxml2-dev libxml2

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get install -y docker-ce

# Install the magic wrapper
RUN wget https://raw.githubusercontent.com/jpetazzo/dind/master/wrapdocker --output-document=/usr/local/bin/wrapdocker && \
    chmod +x /usr/local/bin/wrapdocker

# Set up Docker
RUN gpasswd -a $NB_USER docker && \
    newgrp docker

RUN pip install -v nbtools

RUN jupyter nbextension enable --sys-prefix --py nbtools

USER $NB_USER
#RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba \
#    && touch /root/.bashrc \
#    && ./bin/micromamba shell init -s bash -p /opt/conda  \
#    && grep -v '[ -z "\$PS1" ] && return' /root/.bashrc  > /opt/conda/bashrc
# RUN source $MICROMAMBA_INSTALL_FOLDER/.bashrc && micromamba 
# install --channel anaconda --channel conda-forge r-argparse
RUN mamba create -y --name python3.7 python=3.7 anaconda --channel conda-forge --channel anaconda

RUN source activate python3.7 && \ 
     mamba install -y 'tornado=6.1.0' 'ipywidgets=7.5*' 'ipykernel' 'pandas' 'numexpr' 'matplotlib' 'scipy' 'seaborn' \ 
     'scikit-learn' 'scikit-image' 'sympy' 'cython' 'patsy' 'statsmodels' 'cloudpickle' 'dill' 'numba' \ 
     'bokeh' 'sqlalchemy' 'hdf5' 'h5py' 'vincent' 'beautifulsoup4' 'protobuf' 'xlrd' 'simplegeneric'

# . "${CONDA_DIR}/etc/profile.d/conda.sh" && . ~/micromamba/etc/profile.d/mamba.sh && \
RUN source activate python3.7 && \ 
     pip install --use-deprecated=legacy-resolver nbtools 'igv-jupyter==0.9.8' 'cyjupyter==0.2.0' 'ccalnoir==2.7.1' 'cuzcatlan==0.9.3' 'ndex2==1.2.0.*' \
     'plotly==4.1.0' 'orca==1.3.0' 'opencv-python==4.0.0.21' 'hca==4.8.0' 'humanfriendly==4.12.1' scanpy memory_profiler

RUN echo "/home/jovyan/.local/lib/python3.7/site-packages" > /opt/conda/envs/python3.7/lib/python3.7/site-packages/conda.pth

USER root

# Add as Jupyter kernel
RUN source activate python3.7 && python -m ipykernel install --name python3.7 --display-name 'Python 3.7'

# Remove default Python kernel
RUN rm -r /opt/conda/share/jupyter/kernels/python3 && \
    printf '\nc.KernelSpecManager.ensure_native_kernel = False' >> /etc/jupyter/jupyter_notebook_config.py

USER root

RUN rm -r work
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini
RUN apt-get install -y podman iptables uidmap
RUN echo $NB_USER:200000:1000 > /etc/subuid; \
    echo $NB_USER:200000:1000 > /etc/subgid;
RUN chmod u+s /usr/bin/newuidmap
RUN chmod +s /usr/bin/newgidmap /usr/bin/newgidmap
# RUN usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $NB_USER
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf /etc/containers/containers.conf
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf /home/$NB_USER/.config/containers/containers.conf
COPY ./storage.conf /etc/containers/storage.conf
RUN chown 1000:100 -R /home/$NB_USER
# VOLUME /var/lib/container
# VOLUME /home/$NB_USER/.local/share/containers
# chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock; touch /var/lib/shared/vfs-images/images.lock; touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""
ENTRYPOINT ["/sbin/tini","--","/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
USER $NB_USER
ENV TERM xterm

