FROM msaidf/r0-extension:latest
MAINTAINER "Muhamad Said Fathurrohman" muh.said@gmail.com

ENV NB_USER rstudio
ENV NB_UID 1000
ENV VENV_DIR /srv/venv

# Set ENV for all programs...
ENV PATH ${VENV_DIR}/bin:$PATH
# And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

# The `rsession` binary that is called by nbrsessionproxy to start R doesn't seem to start
# without this being explicitly set
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

ENV HOME /home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

USER ${NB_USER}

RUN python3 -m venv ${VENV_DIR} && \
    pip3 install pip==18.0

RUN pip3 install --no-cache-dir jupyterlab jupyter-rsession-proxy \
    jupyter_nbextensions_configurator jupyter_contrib_nbextensions \
    neovim nbdime RISE && \
    nbdime config-git --enable --global && \
    jupyter contrib nbextension install && \
    jupyter nbextensions_configurator enable

RUN pip3 install --no-cache-dir panda numpy matplotlib plotly scipy scikit-learn nltk spacy bs4 

RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"

RUN curl -fLo ~/.local/share/nvim/site/autoload/plug.vim \
    --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


CMD jupyter lab --ip 0.0.0.0

## If extending this image, remember to switch back to USER root to apt-get
