#!/usr/bin/perl
#

use Data::Dumper;
use Chemistry::Chempost::Parser;
use Chemistry::Chempost::Lexer;


my @lines = <STDIN>;
my $input = join("", @lines);

my $lexer = new Lexer();

sub yyerror {
	printf STDERR "yyerror()\n";
}


my $parser = new Parser();
$lexer->from($input);
my $scriptBody = $parser->YYParse(
	yylex => $lexer->getyylex(),
	yyerror => \&yyerror,
	yydebug => 0);



my $scriptHeader = <<EOF_HEADER;
input TEX;
input ChemPost;

prologues:=3;

verbatimtex
%&latex
\\documentclass[10pt]{minimal}
\\usepackage{amsmath}
\\begin{document}
etex

TEXPRE("%&latex" & char(10)
	& "\\documentclass[12pt]{article}" & char(10)
	& "\\usepackage{amsmath}" & char(10)
	& "\\begin{document}"
);
TEXPOST(
	"\\end{document}"
);

unit := 1cm;

%% Backward-compatible routine for setting output template name.
% \@param string fname Filename to use.
%
def setoutputfilename(expr fname) =
	if scantokens(mpversion) < 1.200:
		filenametemplate
	else:
		outputtemplate :=
	fi
	fname;
enddef;

EOF_HEADER

my $scriptFooter = <<EOF_FOOTER;

end

EOF_FOOTER

my $output = $scriptHeader;
$output .= $scriptBody;
$output .= $scriptFooter;

print $output;


exit 0;

