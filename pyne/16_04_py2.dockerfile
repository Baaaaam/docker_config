FROM ubuntu:16.04

ENV HOME /root

RUN apt-get -y --force-yes update
RUN apt-get install -y --force-yes \
    software-properties-common python-software-properties wget

# pyne specific dependencies
RUN apt-get install -y build-essential python-numpy python-scipy cython \
                       python-nose git cmake vim emacs gfortran libblas-dev \
                       liblapack-dev libhdf5-dev gfortran python-tables \
                       python-matplotlib python-jinja2 autoconf libtool \
                       python-setuptools python-pip doxygen

RUN pip install sphinx cloud_sptheme prettytable sphinxcontrib_bibtex numpydoc nbconvert 

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu

# make starting directory
RUN cd $HOME \
  && mkdir opt

# build MOAB
RUN cd $HOME/opt \
  && mkdir moab \
  && cd moab \
  && git clone https://bitbucket.org/fathomteam/moab \
  && cd moab \
  && git checkout -b Version4.9.1 origin/Version4.9.1 \
  && autoreconf -fi \
  && cd .. \
  && mkdir build \
  && cd build \
  && ../moab/configure --enable-shared --enable-dagmc --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --prefix=$HOME/opt/moab \
  && make \
  && make install \
  && cd .. \
  && rm -rf build moab

# put MOAB on the path
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $HOME/opt/moab/lib:$LIBRARY_PATH

# build PyTAPS
RUN cd $HOME/opt \
  && wget https://pypi.python.org/packages/source/P/PyTAPS/PyTAPS-1.4.tar.gz \
  && tar zxvf PyTAPS-1.4.tar.gz \
  && rm PyTAPS-1.4.tar.gz \
  && cd PyTAPS-1.4/ \
  && python setup.py --iMesh-path=$HOME/opt/moab --without-iRel --without-iGeom install --user \
  && cd .. \
  && rm -rf PyTAPS-1.4

# Install PyNE
RUN cd $HOME/opt \
    && git clone https://github.com/pyne/pyne.git \
    && cd pyne \
    && python setup.py install --user -- -DMOAB_LIBRARY=$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=$HOME/opt/moab/include

RUN echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH

RUN cd $HOME/opt/pyne && ./scripts/nuc_data_make

RUN cd $HOME/opt/pyne/tests \
    && ./travis-run-tests.sh python2 \
    && echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
RUN add-apt-repository ppa:jonathonf/vim
RUN apt-get -y update
RUN apt-get install -y \
  vim \
  ack-grep \
  zsh \
  locales

RUN locale-gen en_US.UTF-8
WORKDIR /root
RUN git clone https://github.com/Baaaaam/zsh_config.git .zsh_config
WORKDIR /root/.zsh_config
RUN git fetch
RUN git checkout docker
RUN ./install.sh
WORKDIR /root
RUN chsh -s /usr/bin/zsh root



# Define default command
CMD ["/bin/zsh"]
