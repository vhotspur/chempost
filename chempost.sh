#!/bin/sh

verbose_run() {
	echo "$@" 1>&2
	"$@"
}

RUN=verbose_run

CHEMPOST_BASE=`dirname "$0"`/

# Full path to chempost.pl
CHEMPOST_PP="${CHEMPOST_BASE}chempost.pl"

# PERL interpreter
PERL="perl -I${CHEMPOST_BASE}lib"

# MPINPUTS shall point to ChemPost.mp file
MPINPUTS=":${MPINPUTS}:${CHEMPOST_BASE}"

# MetaPost interpreter
METAPOST="mpost --mem=mpost --tex=latex --jobname=tmp-chempost --interaction=nonstopmode"

# File with generated MetaPost code
CHEMPOST_TMP="tmp.chempost.mp.$$"

trap "rm -f $CHEMPOST_TMP" INT QUIT TERM EXIT

# run it
if $RUN $PERL $CHEMPOST_PP -o "$CHEMPOST_TMP" "$@"; then
	$RUN $METAPOST $CHEMPOST_TMP
fi

exit
