package Lexer;

require 5.005;

use Parse::Lex;

@ISA = qw(Parse::Lex);

my @tokens = (
	'MACRODEF', 'define',
	'COMPOUNDDEF', 'compound',

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

	'ANYTHING', '.',
);


sub new {
	my ( $self ) = @_;
	
	my $this = $self->SUPER::new(@tokens);
	bless $this;
	
	$this->skip('\s+');
	
	return $this;
}

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


1;
