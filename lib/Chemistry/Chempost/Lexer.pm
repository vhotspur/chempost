## @class Lexer
# ChemPost lexer.
#
package Lexer;

require 5.005;

use Parse::Lex;


my @tokens = (
	'MACRODEF', 'define',
	'COMPOUNDDEF', 'compound',
	'INCLUDE', 'include',

	'NODE', 'node',
	'BOND', 'bond',
	'DRAW', 'draw',
	'CYCLIC', 'cyclic',
	
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

	'COMMENT', '[\/][\*](.|\n)*?[\*][\/]',
	'NEWLINE', '[\n]',
	'BLANK', '[ \t]+',

	'ANYTHING', '.',
);

## @method Lexer()
# Constructs a new lexer.
#
sub new {
	my ( $self ) = @_;
	
	my $this = { };
	$this->{"lexer"} = Parse::Lex->new(@tokens);
	bless $this;
	
	$this->{"line-number"} = 1;
	$this->{"lexer"}->skip('');
	
	return $this;
}

## @method public int getlinenumber()
# Tells current line number.
#
sub getlinenumber {
	my $this = shift;
	return $this->{"line-number"};
}

## @method public void from(...)
# Sets the input for the lexer.
#
sub from {
	my $this = shift;
	$this->{"lexer"}->from(@_);
}

## @method public function getyylex()
# Creates callback for accessing next lexical element.
#
sub getyylex {
	my $self = shift;
	return sub {
		my ( $value, $name, $token );
		my $skip;
		do {
			$token = $self->{"lexer"}->next;
			if ($self->{"lexer"}->eoi) {
				return ("", undef);
			}
			$name = $token->name;
			$skip = 0;
			if ($name eq 'NEWLINE') {
				$self->{'line-number'}++;
			}
			if (($name eq 'COMMENT')
				or ($name eq 'BLANK')
				or ($name eq 'NEWLINE')
				) {
				$skip = 1;
			}
		} while ($skip);
		$value = $token->text;
		my %value = (
			"value" => $value,
			"line" => $self->{'line-number'}
		);
		return ($name, \%value);
	}
}


1;
