#!/bin/bash

set -e

TESTCMD="go test -v -race"

if [ "$1" == "nocover" ]; then
    eval "${TESTCMD}"
else
    rm *_cover.* *.coverprofile | true
    go list -f \
       "{{if gt (len .TestGoFiles) 0}}\"${TESTCMD} -covermode atomic -coverprofile {{.Name}}.coverprofile -coverpkg ./... {{.ImportPath}}\"{{end}}"\
       ./... | xargs -I {} bash -c {}

    gocovmerge `ls *.coverprofile` > proxy_cover.txt
    go tool cover -html proxy_cover.txt -o proxy_cover.html
fi
