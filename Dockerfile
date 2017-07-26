FROM node:4.8
MAINTAINER Pelias

ENV PORT=8080
ENV DEBIAN_FRONTEND 'noninteractive'

EXPOSE ${PORT}

# install libpostal
RUN apt-get update &&\
    echo 'APT::Acquire::Retries "20";' >> /etc/apt/apt.conf &&\
    apt-get install -y --no-install-recommends git curl libsnappy-dev autoconf automake libtool pkg-config &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /mnt/data/libpostal &&\
  git clone https://github.com/openvenues/libpostal \
  && cd libpostal \
  && git checkout tags/v0.3.4 \
  && ./bootstrap.sh \
  && ./configure --datadir=/mnt/data/libpostal \
  && make \
  && make install \
  && ldconfig

# use our extended query module until it gets merged upstream
ENV QUERY=/opt/pelias/query
WORKDIR ${QUERY}
RUN git clone --single-branch https://github.com/HSLdevcom/query.git \
  && cd query \
  && npm install \
  && npm link

# Where the app is built and run inside the docker fs
ENV WORK=/opt/pelias/api

# Used indirectly for saving npm logs etc.
ENV HOME=/opt/pelias/api

WORKDIR ${WORK}
ADD . ${WORK}

# Build and set permissions for arbitrary non-root user
RUN npm install \
  && npm link pelias-query \
  && npm test \
  && chmod -R a+rwX .

ADD pelias.json.docker pelias.json

ADD run.sh /usr/local/bin/

CMD /usr/local/bin/run.sh
