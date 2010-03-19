#!/usr/bin/perl
#

require 5.005;
use Parse::Lex;

use Data::Dumper;
#use Chemistry::Chempost::Generator;
use Chemistry::Chempost::Parser;


my @token = (
	'NODE', 'node',
	'BOND', 'bond',
	'UNBOND', 'unbond',
	'BOND_KIND', 'single|double',
	'LBRACKET', '[\[]',
	'RBRACEKT', '[\]]',
	'LBRACE', '[\{]',
	'RBRACE', '[\}]',
	'LPAREN', '[\(]',
	'RPAREN', '[\)]',
	'SEMICOLON', '[;]',
	'COMMA', '[,]',

	'NUMBER', '\d+',
	'STRING', '"([^"]*)"', sub {
		return $1;
	},
	'IDENTIFIER', '[a-zA-z]\w+',

	'COMMENT', '[\/][\*](.|\n)*[\*][\/]',

	'ANYTHING', '.',
);

my @lines = <STDIN>;
my $input = join("", @lines);

# Parse::Lex->trace;
my $lexer = new Parse::Lex(@token);
$lexer->skip('\s+');

sub getyylex {
  my $self = shift;
  return sub {
	my ( $value, $name, $token );
	do {
		$token = $self->next;
		if ($self->eoi) {
			return ("", undef);
		}
		$name = $token->name;
	} while ($name eq 'COMMENT');
	$value = $token->text;
	return ($name, $value);
  }
}

sub yyerror {
	printf STDERR "yyerror()\n";
}


my $parser = new Parser();
$lexer->from($input);
my $scriptBody = $parser->YYParse(
	yylex => &getyylex($lexer),
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
% @param string fname Filename to use.
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

