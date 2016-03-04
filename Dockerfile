FROM golang:1.5

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq
RUN apt-get install -qq --force-yes software-properties-common && \
    add-apt-repository ppa:ubuntu-elisp/ppa -y && \
    apt-get update -qq && \
    apt-get install -qq --force-yes emacs24

RUN cd /tmp && git clone https://github.com/fniessen/orgmk && \
    cd orgmk && make && make install

RUN mkdir -p /gopath/src/github.com/NeowayLabs/dchan

ADD . /gopath/src/github.com/NeowayLabs/dchan

WORKDIR /gopath/src/github.com/NeowayLabs/dchan

CMD ["make", "build"]
