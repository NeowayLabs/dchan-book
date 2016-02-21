
### -*- Makefile -*- Dchan build options

# To install `dchan', type `make' and then `make install'.

BIN_DIR=/usr/local/bin
ORG_FILE=dchan.org

.PHONY: all build test clean doc

all: clean tangle build test doc
        @echo "build successfully"

tangle:
        org-tangle $(ORG_FILE)

build:
        go build -v

test:
        go test -v ./...

install:
        cp dchan $(BIN_DIR)

clean:
        -rm dchan *.tex *.pdf *.html *.go *.txt *~

doc:
        org2pdf $(ORG_FILE)
