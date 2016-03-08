# [[file:dchan.orgmk::*Makefile][Makefile:1]]
# A generic orgmode Makefile, by Todd Lewis <tlewis@brickabode.com>
# 23 February 2016
# This document is released to the public domain, though with no
# warranties; use at your own risk

.PHONY: build clean clean-source clean-latex


# To install `dchan', type `make' and then `make install'.
BIN_DIR=/usr/local/bin
DCHAN_SRC=$(wildcard unix/dchan/*.org)
PROXY_SRC=$(wildcard unix/dchan-proxy/*.org)
TEST_SRC=$(wildcard unix/testing/*.org)
OBJS=	unix/dchan/dchan \
	unix/dchan-proxy/dchan-proxy
DOC_BOOK=dchan.org
HTMLS=$(patsubst %.org,%.html,$(DOC_BOOK))
TXTS=$(patsubst %.org,%.txt,$(DOC_BOOK))
PDFS=$(patsubst %.org,%.pdf,$(DOC_BOOK))

all: clean $(OBJ) $(HTMLS) $(TXTS) $(PDFS)

clean-latex:
	rm -f *.blg *.bbl *.tex *.odt *.toc *.out *.aux

clean-source:
	-cd unix/dchan/ && make clean
	-cd unix/dchan-proxy/ && make clean

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

tangle-src:
	org-tangle $(DCHAN_SRC)
	org-tangle $(PROXY_SRC)
	org-tangle $(TEST_SRC)

build: tangle-src
	cd unix/dchan/ && make build
	cd unix/dchan-proxy/ && make build

doc: $(HTMLS) $(PDFS) $(TXTS)

test: tangle-src
	cd unix/dchan-proxy/ && make test

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
