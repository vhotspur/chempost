EXAMPLES = cresols cycles sample

MPOST_EXECUTABLE = mpost
MPOST_OPTS = --mem=mpost --tex=latex
MPOST = $(MPOST_EXECUTABLE) $(MPOST_OPTS)

CHEMPOST = perl -Ilib/ ../chempost.pl

all: $(EXAMPLES)

.PHONY: \
	all \
	.compile \
	$(EXAMPLES) \
	clean

.compile:
	$(MAKE) -C .. compile

%.mp: %.chmp .compile
	$(CHEMPOST) <$*.chmp | sed 's#input ChemPost;#input ../ChemPost;#' >$@

cresols: cresols.mp
cycles: cycles.mp
icresols: icresols.mp
sample: sample.mp

$(EXAMPLES):
	$(MPOST) $@.mp

clean:
	$(RM) *.mp *.log *.mpx *.tex
distclean: clean
	$(RM) *.mps

