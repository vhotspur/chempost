## @class
# Extended SMILES lexer.
#
package EsmilesLexer;

require 5.005;

use Parse::Lex;


my @tokens = (
	'ATOM_ORGANIC_SUBSET', '[BCNOPSF]|Cl|Br',
	'BOND', '([-=#])', sub {
		my $bond = $1;
		if ($bond eq "=") {
			return "double";
		} elsif ($bond eq "#") {
			return "triple";
		} else {
			# also fallback for other values
			return "single";
		}
	},
	'DESCRIBED_NODE', "'([^']*)'", sub {
		return $1;
	},
	'ANYTHING', '.',
);

## @method new()
# Constructor.
#
sub new {
	my ( $self ) = @_;
	
	my $this = { };
	$this->{"lexer"} = Parse::Lex->new(@tokens);
	bless $this;
	
	$this->{"lexer"}->skip('\s+');
	
	return $this;
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
			# future extensions: special skipping etc.
			$skip = 0;
		} while ($skip);

		$value = $token->text;
		# for future extensions, return hash
		my %value = (
			"value" => $value
		);
		return ($name, \%value);
	}
}


1;
