#!/usr/bin/perl
#

use Data::Dumper;
use Chemistry::Chempost::Parser;
use Getopt::Std;


my %runOptions;
getopts("g:o:M:d", \%runOptions)
	or die "Invalid invocation.";

my %options = (
	"generate-all" => 1,
	"generate-only" => { },
	"output-filename" => "-",
	"output-file" => STDOUT,
	"generate-dependencies" => 0,
	"generate-dependencies-file" => STDOUT,
	"input-filename" => "-",
	"debug" => 0,
);

if (exists $runOptions{"g"}) {
	$options{"generate-all"} = 0;
	foreach my $k ( split(/,+/, $runOptions{"g"}) ) {
		$options{"generate-only"}->{$k} = 1;
	}
}
if (exists $runOptions{"o"}) {
	my $fd;
	if (not open($fd, ">" . $runOptions{"o"})) {
		die "Cannot open output file.";
	}
	$options{"output-filename"} = $runOptions{"o"};
	$options{"output-file"} = $fd;
}
if (exists $runOptions{"M"}) {
	if ($runOptions{"M"} eq "-") {
		$options{"generate-dependencies-file"} = STDOUT;
	} else {
		my $fd;
		if (not open($fd, ">" . $runOptions{"M"})) {
			die "Cannot open dependency file for writing.";
		}
		$options{"generate-dependencies-file"} = $fd;
	}
	$options{"generate-dependencies"} = 1;
}
if (exists $runOptions{"d"}) {
	$options{"debug"} = 1;
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
	$options{"input-filename"} = $ARGV[0];
} else {
	@inputLines = <STDIN>;
	$options{"input-filename"} = "<stdin>";
}

my $input = join("", @inputLines);
my $parser = new Parser();
$parser->init();
$parser->setDebug($options{"debug"});
my $figures = $parser->parseString($options{"input-filename"}, $input);

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

my $dependencies = <<EOF_DEPENDENCY_HEADER;
# DO NOT EDIT!
# This file is generated and all changes will be lost.
#

EOF_DEPENDENCY_HEADER

my $output = $scriptHeader;

my $figuresGenerated = 0;
foreach my $f ( @{$figures} ) {
	if ($options{"generate-all"} or exists($options{"generate-only"}->{$f->{"id"}})) {
		$output .= $f->{"code"};
		$figuresGenerated++;
	}
	$dependencies .= sprintf("%s.mps: %s\n\t\$(CHEMPOST) -g %s \$<\n",
		$f->{"id"}, $options{"input-filename"}, $f->{"id"});
}

$output .= $scriptFooter;

if ($options{"generate-dependencies"}) {
	print { $options{"generate-dependencies-file"} } $dependencies;
	if ($figuresGenerated == 0) {
		exit 2;
	}
}

if ($figuresGenerated == 0) {
	printf STDERR "Error: no figures generated!\n";
	exit 1;
}

print { $options{"output-file"} } $output;



exit 0;

