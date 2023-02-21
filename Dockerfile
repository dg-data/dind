FROM jupyter/minimal-notebook:a374cab4fcb6
ARG NB_USER=jovyan

EXPOSE 8888

USER root

# Install the missing Qt4 API (used by matplotlib)
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common python3-pyqt5 \
    libxtst6 libssl-dev libcurl4-openssl-dev gpg build-essential python-dev default-jdk apt-utils libxml2-dev libxml2

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

RUN micromamba create -n python3.7 python=3.7 -c conda-forge
RUN /bin/bash -c "micromamba info"
RUN ./bin/micromamba shell init --shell=bash --prefix=~/micromamba
RUN /bin/bash -c "eval "$("$MAMBA_EXE" shell hook --shell bash --prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)" && \
    $MAMBA_EXE activate ~/micromamba/envs/python3.7 && \
    ./bin/micromamba install -y -n python3.7 -c anaconda anaconda"
   
RUN /bin/bash -c "eval "$("$MAMBA_EXE" shell hook --shell bash --prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)" && \
    $MAMBA_EXE activate ~/micromamba/envs/python3.7 && \
    ./bin/micromamba install -y -n python3.7 -c conda-forge -c anaconda 'tornado=5.1.1' 'ipywidgets=7.2*' 'ipykernel' 'pandas' 'numexpr' 'matplotlib' 'scipy' 'seaborn' \
    'scikit-learn' 'scikit-image' 'sympy' 'cython' 'patsy' 'statsmodels' 'cloudpickle' 'dill' 'numba' \
    'bokeh' 'sqlalchemy' 'hdf5' 'h5py' 'vincent' 'beautifulsoup4' 'protobuf' 'xlrd' 'simplegeneric'"

# . "${CONDA_DIR}/etc/profile.d/conda.sh" && . ~/micromamba/etc/profile.d/mamba.sh && \
RUN eval "$("$MAMBA_EXE" shell hook -s bash)" && \
    micromamba activate ~/micromamba/envs/python3.7 && pip install nbtools 'cuzcatlan==0.9.3' 'ndex2==1.2.0.*' 'orca==1.3.0' 'rpy2==3.2.1' \
    'opencv-python==4.1.2.30' 'hca==4.8.0' 'humanfriendly==4.12.1' scanpy memory_profiler globus_sdk globus-cli
    
RUN echo "/home/jovyan/.local/lib/python3.7/site-packages" > /opt/conda/envs/python3.7/lib/python3.7/site-packages/conda.pth

USER root

# Add as Jupyter kernel
RUN /bin/bash -c "eval "$("$MAMBA_EXE" shell hook --shell bash --prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)" && \
    "$MAMBA_EXE activate python3.7 && python -m ipykernel install --name python3.7 --display-name 'Python 3.7'"

# Remove default Python kernel
RUN rm -r /opt/conda/share/jupyter/kernels/python3 && \
    printf '\nc.KernelSpecManager.ensure_native_kernel = False' >> /etc/jupyter/jupyter_notebook_config.py

USER root

RUN rm -r work

USER $NB_USER
ENV TERM xterm
