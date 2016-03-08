FROM golang:1.5

ENV DEBIAN_FRONTEND=noninteractive
ENV ORGMK_EL=/gopath/src/github.com/NeowayLabs/dchan/scripts/orgmk.el
ENV PLAN9=/tmp/plan9
ENV PATH=$PLAN9/bin:$PATH

ADD ./scripts/sources.list /etc/apt/sources.list
RUN apt-get update -qq
RUN apt-get install -qq --force-yes emacs24 texlive-latex-recommended

RUN cd /tmp && git clone https://github.com/fniessen/orgmk && \
    cd orgmk && make -e && make install

RUN cd /tmp && git clone https://github.com/tiago4orion/plan9port.git plan9 && \
    cd /tmp/plan9 && ./INSTALL

RUN mkdir -p /gopath/src/github.com/NeowayLabs/dchan

ADD . /gopath/src/github.com/NeowayLabs/dchan

WORKDIR /gopath/src/github.com/NeowayLabs/dchan

RUN go get -v ./...

CMD ["make", "build"]
