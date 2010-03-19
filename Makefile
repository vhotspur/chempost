NAME = chempost
VERSION = 0.01

DISTNAME = $(NAME)-$(VERSION)


ARCHIVE = $(DISTNAME).tar.gz

LOCAL_LIB = ./lib
PACKAGE = Chemistry/Chempost

# Static (i.e. not generated) library sources
LIB_SOURCES = \
	$(LOCAL_LIB)/$(PACKAGE)/Builder.pm \
	$(LOCAL_LIB)/$(PACKAGE)/Generator.pm

PARSER_MODULE = $(LOCAL_LIB)/$(PACKAGE)/Parser.pm

LIB_SOURCES_ALL = \
	$(PARSER_MODULE) \
	$(LIB_SOURCES)

MPOST = mpost --mem=mpost --tex=latex
RM = rm -Rf
YAPP = yapp
PERL = perl -I$(LOCAL_LIB)

all: compile

.PHONY: all \
	compile \
	sample cycles \
	dist \
	clean distclean

compile: $(PARSER_MODULE)

run: compile
	$(PERL) ./chempost.pl <sample.chmp

sample: sample.mp
	$(MPOST) $<

cycles: cycles.mp
	$(MPOST) $<

%.mp: chempost.pl $(LIB_SOURCES_ALL) %.chmp
	$(PERL) ./chempost.pl <$*.chmp >$@

$(PARSER_MODULE): Parser.y
	@# this one is run to show the errors of the grammar
	@# while the second one is adjuste through sed(1) and thus is
	@# more obscure to use
	$(YAPP) -v -m Parser -o $@ $<
	@# replace $T1 with $_[1] etc.
	@# replace /dev/stdin by the original name
	sed 's/\$$T\([1-9]\)\>/$$_[\1]/g;s/\$$TT\>/$$_[0]/g' $< \
		| $(YAPP) -sm Parser -o - /dev/stdin 2>/dev/null \
		| sed 's#/dev/stdin#$<#g' >$@

clean:
	$(RM) mptextmp.*
	$(RM) sample.mp cycles.mp sample.log cycles.log
	$(RM) Parser.output

distclean: clean
	$(RM) $(PARSER_MODULE)
	$(RM) *.mps

dist:
	mkdir $(DISTNAME)
	cp Makefile ChemPost.mp Parser.y chempost.pl sample.chmp $(DISTNAME)
	mkdir -p $(DISTNAME)/$(LOCAL_LIB)/$(PACKAGE)
	cp $(LIB_SOURCES) $(DISTNAME)/$(LOCAL_LIB)/$(PACKAGE)/
	tar -czf $(ARCHIVE) $(DISTNAME)
	$(RM) $(DISTNAME)
