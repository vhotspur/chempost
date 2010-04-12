#!/usr/bin/perl
#

use Data::Dumper;
use Chemistry::Chempost::Parser;
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

my $input = join("", @inputLines);
my $parser = new Parser();
$parser->init();
my $figures = $parser->parseString($input);

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

my $figuresGenerated = 0;
foreach my $f ( @{$figures} ) {
	if ($options{"generate-all"} or exists($options{"generate-only"}->{$f->{"id"}})) {
		$output .= $f->{"code"};
		$figuresGenerated++;
	}
}

$output .= $scriptFooter;

if ($figuresGenerated == 0) {
	printf STDERR "No figures generated!\n";
	exit 1;
}

print $output;

exit 0;

