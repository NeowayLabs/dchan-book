
# [[file:~/projects/go-workspace/src/gitlab.neoway.com.br/tiago.natel/dchan/dchan.org::*Makefile][Makefile:1]]

# A generic orgmode Makefile, by Todd Lewis <tlewis@brickabode.com>
# 23 February 2016
# This document is released to the public domain, though with no
# warranties; use at your own risk

.PHONY: build


# To install `dchan', type `make' and then `make install'.
BIN_DIR=/usr/local/bin
OBJ=dchan
DOC_SRCS=$(wildcard *.org)
HTMLS=$(patsubst %.org,%.html,$(DOC_SRCS))
TXTS=$(patsubst %.org,%.txt,$(DOC_SRCS))
PDFS=$(patsubst %.org,%.pdf,$(DOC_SRCS))

all: clean $(OBJ) $(HTMLS) $(TXTS) $(PDFS)

clean-latex:
	rm -f *.blg *.bbl *.tex *.odt *.toc *.out *.aux

clean-source:
	rm -f *.go

clean: clean-latex clean-source
	rm -f *.png
	rm -f *.txt *.html *.pdf *.odt
	rm -f *.log

%.html: %.org
	org2html $<

%.txt: %.org
	org2txt  $<

%.pdf: %.org
	org2pdf $<
	-pdflatex dchan.tex
	bibtex dchan
	pdflatex dchan.tex
	pdflatex dchan.tex

tangle: $(DOC_SRCS)
	org-tangle $<

build: $(OBJ)
doc: $(HTMLS) $(PDFS) $(TXTS)

$(OBJ): tangle
	go build -v

test: tangle
	go test -v ./...

install:
	cp $(OBJ) $(BIN_DIR)


# To include an automatic version number in your file, use a header like this:
#
#+OPTIONS: VERSION:$Version: $
#
# Then you can use this rule to automatically update it;
# to update file foo.org, just do "make foo.version".

%.version: %.org
	(ver=`date +%s`; cat $< | sed 's/\$$Version:[^$$]*\$$/$$Version: '$$ver' $$/g' > .version-$$ver && mv .version-$$ver $< && echo Versioned $<)

# Makefile:1 ends here
