#!/bin/bash
px-deploy() { docker run --help | grep -q -- "--platform string" && PLATFORM="--platform linux/amd64" ; [ "$DEFAULTS" ] && params="-v $DEFAULTS:/px-deploy/.px-deploy/defaults.yml" ; docker run $PLATFORM -e PXDUSER=$USER --rm --name px-deploy.$$ $params -v $HOME/.px-deploy:/px-deploy/.px-deploy -v $HOME/.aws/credentials:/root/.aws/credentials -v $HOME/.config/gcloud:/root/.config/gcloud -v $HOME/.azure:/root/.azure -v /etc/localtime:/etc/localtime px-deploy /root/go/bin/px-deploy $* ; }
px-deploy status -n $1 | awk -v RS='([0-9]+\\.){3}[0-9]+' 'RT{print RT}'|tail -1
