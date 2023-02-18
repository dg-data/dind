FROM codercom/code-server:4.4.0

ARG NB_USER="coder"
ARG NB_UID="1000"
ARG NB_GID="100"
ARG CUSER="coder"
# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV DEBIAN_FRONTEND noninteractive

COPY ./wrapper.sh /usr/local/bin/wrapper

RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes  

# # - bzip2 is necessary to extract the micromamba executable.
RUN apt-get update && apt-get install --yes bzip2 \
    ca-certificates \
    fonts-liberation \
    locales \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in arm64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    # sudo \
    # # - tini is installed as a helpful container entrypoint that reaps zombie
    # #   processes and such of the actual executable we want to start, see
    # #   https://github.com/krallin/tini#why-tini for details.
    tini \
    fish \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    USER="${NB_USER}" \
    NB_USER="${CUSER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
    
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${CUSER}"

RUN apt-get update && \
    apt-get install -y docker.io docker-compose bash curl openssh-server && \
    apt-get purge -y needrestart && \
    apt-get autoremove -y --purge && \
    mkdir -p /run/sshd && \
    rm -rf /var/lib/apt/lists/* && \
    curl -sSLo /usr/local/bin/dind https://raw.githubusercontent.com/jpetazzo/dind/master/wrapdocker && \
    chmod +x /usr/local/bin/* 

RUN apt-get update && \
    apt-get install -y python3-pip

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name jovyan/coder user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    # useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_UID}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${HOME}" && \
    fix-permissions "${CONDA_DIR}"

USER ${NB_UID}

# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.8

# Setup work directory for backward-compatibility
RUN mkdir "/home/${CUSER}/work" && \
    fix-permissions "/home/${CUSER}"

# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba, Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp

RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget -qO /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'notebook' \
        'jupyterhub' \
        'jupyterlab' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    jupyter notebook --generate-config && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

EXPOSE 8881
ENV PATH="${HOME}/.local/bin:${PATH}"
# Configure container startup
# ENTRYPOINT ["tini", "-g", "--"]
# CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/

# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
# COPY jupyter_server_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root

# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
# RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
#     /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
#     fix-permissions /etc/jupyter/

# # HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# # This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# # https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK  --interval=15s --timeout=3s --start-period=5s --retries=3 \
     CMD wget -O- --no-verbose --tries=1 --no-check-certificate \
     http${GEN_CERT:+s}://localhost:8888${JUPYTERHUB_SERVICE_PREFIX:-/}api || exit 1
USER ${NB_UID}
# Initial ABXDA
# RUN apt-get update && \
#     apt-get install -y gdal-bin

# RUN apt-get update && \
#     apt-get install -y --no-install-recommends git && \
#     apt-get clean

# RUN apt-get update && apt-get -y install cmake protobuf-compiler

# RUN apt-get update && apt-get install -y \
# 	libopencv-dev \
# 	python3-opencv && \
#     rm -rf /var/lib/apt/lists/*

# USER ${NB_USER}

# RUN pip install tqdm \
#     psycopg2-binary sqlalchemy && \
#     conda install -y gdal && \
#     conda install -y -c conda-forge opencv

# RUN pip install --no-cache-dir \
#     html2text \
#     psycopg2-binary \
#     newspaper3k==0.2.8 \
#     altair \
#     vega_datasets \
#     geopandas \
#     attrs \
#     apache-sedona \
#     xlsxwriter \
#     openpyxl

# RUN git clone --recursive https://github.com/dmlc/xgboost && \
#     cd xgboost && \
#     make -j4 && \
#     cd python-package; python setup.py install

# RUN pip install tensorflow && \
#     pip install pyyaml \
#         h5py && \
#     pip install keras --no-deps && \
#     pip install opencv-python && \
#     pip install imutils

 # End ABXDA

# RUN groupadd docker \
#     usermod -aG docker $USER 

# ENTRYPOINT ["/usr/local/bin/wrapper", "/usr/local/bin/dind"]
# CMD ["/usr/local/bin/wrapper", "/usr/local/bin/dind"]
# ENTRYPOINT ["/usr/bin/entrypoint.sh"]   
ENTRYPOINT []
