# A base Ubuntu 16.04 build that runs on z #
FROM s390x/ubuntu
USER root

# Build Minimal Notebook #
## Install Dependencies ##
RUN apt-get update
RUN apt-get install -y python3-pip python3-dev
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

## Set Environment Variables ##
RUN locale-gen en_US.UTF-8
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
ENV SHELL=/bin/bash
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV PATH=$PATH:/home/$NB_USER/.local/bin

## Create User $NB_USER with UID=1000 ##
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER
RUN mkdir -p /opt/conda
RUN chown $NB_USER /opt/conda 
RUN chown $NB_USER -R /usr/

USER $NB_USER
RUN mkdir /home/$NB_USER/work
RUN mkdir /home/$NB_USER/.jupyter
RUN mkdir /home/$NB_USER/.local

USER root
RUN cd /tmp
RUN pip3 install --upgrade pip
RUN pip install 'notebook==4.3'
RUN pip install 'jupyterhub==0.7'

COPY /files/start.sh /usr/local/bin/
COPY /files/start-notebook.sh /usr/local/bin/
COPY /files/start-singleuser.sh /usr/local/bin/
COPY /files/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

WORKDIR /home/$NB_USER/work
USER $NB_USER

# Install dashboard layout and preview within Jupyter Notebook
ADD . /src
RUN pip install /src && \
    jupyter serverextension enable --py nb2kg --sys-prefix

# Run with remote kernel managers
CMD ["jupyter", "notebook", \
     "--NotebookApp.ip=0.0.0.0", \
     "--NotebookApp.session_manager_class=nb2kg.managers.SessionManager", \
     "--NotebookApp.kernel_manager_class=nb2kg.managers.RemoteKernelManager", \
     "--NotebookApp.kernel_spec_manager_class=nb2kg.managers.RemoteKernelSpecManager"]
