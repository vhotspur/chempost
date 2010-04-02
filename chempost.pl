#!/usr/bin/perl
#

use Data::Dumper;
use Chemistry::Chempost::Parser;
use Chemistry::Chempost::Lexer;
use Getopt::Std;


my %runOptions;
getopts("g:", \%runOptions)
	or die "Invalid invocation.";

my %options = (
	"generate-all" => 1,
	"generate-only" => { },
);

if (exists $runOptions{"g"}) {
	$options{"generate-all"} = 0;
	foreach my $k ( split(/,+/, $runOptions{"g"}) ) {
		$options{"generate-only"}->{$k} = 1;
	}
}

my @inputLines;
if (@ARGV > 0) {
	if (@ARGV != 1) {
		die "Too many input files.";
	}
	open(INPUT, $ARGV[0])
		or die "Cannot open input file.";
	@inputLines = <INPUT>;
	close(INPUT);
} else {
	@inputLines = <STDIN>;
}

sub yyerror {
	printf STDERR "yyerror()\n";
}

my $input = join("", @inputLines);
my $lexer = new Lexer();
$lexer->from($input);

my $parser = new Parser();
$parser->init();
my $figures = $parser->YYParse(
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

foreach my $f ( @{$figures} ) {
	if ($options{"generate-all"} or exists($options{"generate-only"}->{$f->{"id"}})) {
		$output .= $f->{"code"};
	}
}

$output .= $scriptFooter;

print $output;


exit 0;

