
# [[file:~/projects/go-workspace/src/github.com/NeowayLabs/dchan/dchan.orgmk::*Makefile][Makefile:1]]

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

# Makefile:1 ends here
