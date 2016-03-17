
# [[file:~/projects/go-workspace/src/github.com/NeowayLabs/dchan/dchan.orgmk::*Makefile][Makefile:1]]

# A generic orgmode Makefile, by Todd Lewis <tlewis@brickabode.com>
# 23 February 2016
# This document is released to the public domain, though with no
# warranties; use at your own risk

.PHONY: build clean clean-source clean-latex test test-proxy test-dchan


# To install `dchan', type `make' and then `make install'.
BIN_DIR=/usr/local/bin
DCHAN_SRC=$(wildcard unix/dchan/*.org)
PROXY_SRC=unix/proxy/proxy.org
TEST_SRC=$(wildcard unix/testing/*.org)
OBJS=	unix/dchan/dchan \
	unix/proxy/proxy
DOC_BOOK=dchan.org
HTMLS=$(patsubst %.org,%.html,$(DOC_BOOK))
TXTS=$(patsubst %.org,%.txt,$(DOC_BOOK))
PDFS=$(patsubst %.org,%.pdf,$(DOC_BOOK))

all: clean $(OBJ) test $(HTMLS) $(TXTS) $(PDFS)

clean-latex:
	rm -f *.blg *.bbl *.tex *.odt *.toc *.out *.aux

clean-source:
	-cd unix/dchan/ && make clean
	-cd unix/proxy/ && make clean

clean: tangle clean-latex clean-source
	rm -f *.pngt
	rm -f *.txt *.html *.pdf *.odt
	rm -f *.log

%.html: %.org
	org2html $<

%.txt: %.org
	org2txt $<

%.pdf: %.org
	org2pdf $<
	-pdflatex dchan.tex
	bibtex dchan
	pdflatex dchan.tex
	pdflatex dchan.tex

tangle:
	org-tangle $(DOC_BOOK)
	org-tangle $(TEST_SRC)
	org-tangle $(DCHAN_SRC)
	org-tangle $(PROXY_SRC)

build: tangle
	cd unix/dchan/ && make build
	cd unix/proxy/ && make build

doc: $(HTMLS) $(PDFS) $(TXTS)

test-dchan: tangle
	cd unix/dchan/ && make test

test-proxy: tangle
	cd unix/proxy/ && make test

test: tangle test-dchan test-proxy

install:
	cp $(OBJS) $(BIN_DIR)


# To include an automatic version number in your file, use a header like this:
#
#+OPTIONS: VERSION:$Version: $
#
# Then you can use this rule to automatically update it;
# to update file foo.org, just do "make foo.version".

%.version: %.org
	(ver=`date +%s`; cat $< | sed 's/\$$Version:[^$$]*\$$/$$Version: '$$ver' $$/g' > .version-$$ver && mv .version-$$ver $< && echo Versioned $<)

# Makefile:1 ends here
