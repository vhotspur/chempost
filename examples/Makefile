EXAMPLES = cresols cycles sample icresols colors

MPOST_EXECUTABLE = mpost
MPOST_OPTS = --mem=mpost --tex=latex
MPOST = $(MPOST_EXECUTABLE) $(MPOST_OPTS)

CHEMPOST_PP = perl -I../lib/ ../chempost.pl
CHEMPOST = ../chempost.sh

DEPFILE = Makefile.depend

all: $(EXAMPLES)

.PHONY: \
	all \
	.compile \
	$(EXAMPLES) \
	clean

.compile:
	$(MAKE) -C .. compile

%.mp: %.chmp .compile
	$(CHEMPOST_PP) <$*.chmp | sed 's#input ChemPost;#input ../ChemPost;#' >$@

depend: .compile
	$(RM) $(DEPFILE);
	for i in *.chmp; do \
		$(CHEMPOST_PP) -g 0 -M - $$i >> $(DEPFILE); \
	done || exit 0

-include $(DEPFILE)

cresols: cresols.mp
cycles: cycles.mp
icresols: icresols.mp
sample: sample.mp
colors: colors.mp

$(EXAMPLES):
	$(MPOST) $@.mp

clean:
	$(RM) *.mp *.log *.mpx *.tex
	$(RM) $(DEPFILE)
distclean: clean
	$(RM) *.mps

