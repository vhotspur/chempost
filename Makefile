NAME = chempost
VERSION = 0.01

###
#
# Below are variables you might want to change to correspond to
# settings on your system.
#

# where to install - either site or vendor
PERL_INSTALLDIRS = site
# installation prefix - typically ~ or /usr or /usr/local
PREFIX = /usr/local


###
#
# The rest could be probably left alone.
#
#
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

PERL_EXECUTABLE = perl

BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share
MY_SHAREDIR = $(SHAREDIR)/$(NAME)

INSTALL = install
INSTALL_DIR = $(INSTALL) -m 0755 -d
INSTALL_NORMAL = $(INSTALL) -m 0644
INSTALL_EXECUTABLE = $(INSTALL) -m 0755

PERL_LIBINSTALLDIR = `$(PERL_EXECUTABLE) -MConfig -e 'printf $$Config{"install$(PERL_INSTALLDIRS)lib"};'`
PERL_MODULESINSTALLDIR = $(PERL_LIBINSTALLDIR)/$(PACKAGE)
PERL_CHECKMODULE = $(PERL_EXECUTABLE) -e 1 -M

MPOST_EXECUTABLE = mpost
MPOST_OPTS = --mem=mpost --tex=latex
MPOST = $(MPOST_EXECUTABLE) $(MPOST_OPTS)
RM = rm -Rf
YAPP = yapp
PERL = $(PERL_EXECUTABLE) -I$(LOCAL_LIB)

all: compile

.PHONY: all \
	compile \
	example \
	doc \
	dist \
	check-tools \
	clean distclean

compile: $(PARSER_MODULE)

run: compile
	$(PERL) ./chempost.pl <sample.chmp

example:
	$(MAKE) -C examples/ "CHEMPOST_DEPENDS=$(LIB_SOURCES_ALL)"

$(PARSER_MODULE): Parser.y
	@# this one is run to show the errors of the grammar
	@# while the second one is adjuste through sed(1) and thus is
	@# more obscure to use
	$(YAPP) -v -m Parser -o $@ $<
	@# replace $T1 with $_[1] etc.
	@# replace /dev/stdin by the original name
	sed 's/\$$T\([1-9]\)\>/$$_[\1]/g;s/\$$TT\>/$$_[0]/g' $< \
		| $(YAPP) -m Parser -o - /dev/stdin 2>/dev/null \
		| sed 's#/dev/stdin#$<#g' >$@

doc: compile
	doxygen

check-tools:
	@echo "Checking that all tools are available..."
	@echo -n ' * MetaPost interpreter: '; which $(MPOST_EXECUTABLE)
	@echo -n ' * PERL: '; which $(PERL_EXECUTABLE)
	@echo -n '    * Data::Dumper '; $(PERL_CHECKMODULE)Data::Dumper && echo "found."
	@echo -n '    * Parse::Lex '; $(PERL_CHECKMODULE)Parse::Lex && echo "found."
	@echo -n '    * Getopt::Std '; $(PERL_CHECKMODULE)Getopt::Std && echo "found."
	@echo -n ' * YAPP: '; which $(YAPP)
	@echo "Looks good."

install: compile
	@###
	@# install PERL modules
	@#
	$(INSTALL_DIR) $(DESTDIR)$(PERL_LIBINSTALLDIR)
	
	$(INSTALL_DIR) $(DESTDIR)$(PERL_MODULESINSTALLDIR)
	$(INSTALL_NORMAL) lib/$(PACKAGE)/*.pm $(DESTDIR)$(PERL_MODULESINSTALLDIR)/
	
	
	@###
	@# install helper script
	@#
	$(INSTALL_DIR) $(DESTDIR)$(MY_SHAREDIR)
	sed \
		-e 's#input ChemPost;#input $(MY_SHAREDIR)/ChemPost;#' \
		< chempost.pl \
		| $(INSTALL_EXECUTABLE) /dev/stdin $(DESTDIR)$(MY_SHAREDIR)/chempost.pl
	
	@###
	@# install MetaPost library file
	@#
	$(INSTALL_NORMAL) ChemPost.mp $(DESTDIR)$(MY_SHAREDIR)/
	
	
	@###
	@# install the PATHed script itself
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	sed \
		-e 's#CHEMPOST_PP=.*#CHEMPOST_PP=$(MY_SHAREDIR)/chempost.pl#' \
		-e 's#PERL=.*#PERL="$(PERL_EXECUTABLE) -I'$(PERL_LIBINSTALLDIR)'"#' \
		< chempost.sh \
		| $(INSTALL_EXECUTABLE) /dev/stdin $(DESTDIR)$(BINDIR)/chempost

clean:
	$(RM) Parser.output
	$(MAKE) -C examples clean

distclean: clean
	$(RM) $(PARSER_MODULE)
	$(RM) *.mps
	$(MAKE) -C examples distclean

dist:
	mkdir $(DISTNAME)
	
	cp Makefile ChemPost.mp Parser.y chempost.pl $(DISTNAME)
	cp chempost.sh $(DISTNAME)
	
	mkdir -p $(DISTNAME)/$(LOCAL_LIB)/$(PACKAGE)
	cp $(LIB_SOURCES) $(DISTNAME)/$(LOCAL_LIB)/$(PACKAGE)/
	
	mkdir -p $(DISTNAME)/examples
	cp examples/Makefile examples/*.chmp $(DISTNAME)/examples
	tar -czf $(ARCHIVE) $(DISTNAME)
	$(RM) $(DISTNAME)
