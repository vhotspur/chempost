#!/bin/sh

# Full path to chempost.pl
CHEMPOST_PP=./chempost.pl

# PERL interpreter
PERL="perl -Ilib"

# MetaPost interpreter
METAPOST="mpost --mem=mpost --tex=latex --jobname=tmp-chempost --interaction=nonstopmode"

# File with generated MetaPost code
CHEMPOST_TMP="tmp.chempost.mp.$$"

trap "rm -f $CHEMPOST_TMP" INT QUIT TERM EXIT

# run it
if $PERL $CHEMPOST_PP "$@" >$CHEMPOST_TMP; then
	$METAPOST $CHEMPOST_TMP
fi

exit
