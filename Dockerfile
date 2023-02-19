FROM genepattern/notebook-base:20.10
ARG NB_USER=jovyan

EXPOSE 8888

USER root

RUN pip install -v nbtools

RUN jupyter nbextension enable --sys-prefix --py nbtools

USER $NB_USER

# RUN conda create -y --name python3.7 python=3.7 anaconda ipykernel
RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
RUN ./bin/micromamba create -n python3.7 python=3.7 -c conda-forge
# RUN yes | ./bin/micromamba shell init -s bash -p /home/jovyan/micromamba
RUN eval "$(./bin/micromamba shell hook --shell=bash)"
RUN /bin/bash -c "./bin/micromamba activate python3.7 && \
    ./bin/micromamba install -y anaconda -c anaconda"
RUN /bin/bash -c "./bin/micromamba activate python3.7 && \
    ./bin/micromamba install -y 'tornado=5.1.1' 'ipywidgets=7.2*' 'ipykernel' 'pandas' 'numexpr' 'matplotlib' 'scipy' 'seaborn' \
    'scikit-learn' 'scikit-image' 'sympy' 'cython' 'patsy' 'statsmodels' 'cloudpickle' 'dill' 'numba' \
    'bokeh' 'sqlalchemy' 'hdf5' 'h5py' 'vincent' 'beautifulsoup4' 'protobuf' 'xlrd' 'simplegeneric'"

RUN /bin/bash -c "./bin/micromamba activate python3.7 && \
    pip install nbtools jupyter_wysiwyg \
    'cyjupyter==0.2.0' 'ccalnoir==2.7.1' 'cuzcatlan==0.9.3' 'ndex2==1.2.0.*' \
    'plotly==4.1.0' 'orca==1.3.0' 'rpy2==3.2.1' 'opencv-python==4.0.0.21' 'hca==4.8.0' 'humanfriendly==4.12.1' scanpy memory_profiler globus_sdk globus-cli"

RUN echo "/home/jovyan/.local/lib/python3.7/site-packages" > /opt/conda/envs/python3.7/lib/python3.7/site-packages/conda.pth

USER root

# Add as Jupyter kernel
RUN /bin/bash -c "./bin/micromamba activate python3.7 && python -m ipykernel install --name python3.7 --display-name 'Python 3.7'"

# Remove default Python kernel
RUN rm -r /opt/conda/share/jupyter/kernels/python3 && \
    printf '\nc.KernelSpecManager.ensure_native_kernel = False' >> /etc/jupyter/jupyter_notebook_config.py

USER root

RUN rm -r work

USER $NB_USER
