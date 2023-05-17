#!/bin/sh
set -e

keyhex="596A55794E5441"

decfile() {
    inf=$1
    tmpf="/tmp/dec.tmp"
    openssl enc -d -des-ecb -K $keyhex -in $inf -out $tmpf  -provider legacy -provider default || return 1
    mv $tmpf $inf
}

decfile "$1"
