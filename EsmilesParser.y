%{
## @class
# Grammar parser for Extended SMILES.
package EsmilesParser;
use Data::Dumper;
use Chemistry::Chempost::EsmilesLexer;
use Chemistry::Chempost::Builder;
use constant PRIVATE_DATA_NODE_ID_GENERATOR => "node-id-generator";

%}

%token DESCRIBED_NODE
%token ATOM_ORGANIC_SUBSET
%token BOND

%start esmiles

%%

esmiles:
	molecule {
		return $T1;
	}
	;

molecule:
	molecule_node_list {
		return $T1->{"builder"};
	}
	;

molecule_node_list:
	molecule_node {
		return $T1;
	}
	|
	molecule_node_list molecule_bond molecule_node {
		my $mainBuilder = $T1->{"builder"};
		my $mainConnectingNodeId = $T1->{"connect-id"};
		my $newBuilder = $T3->{"builder"};
		my $newConnectingNodeId = $T3->{"connect-id"};
		my $bondKind = $T2;
		
		$mainBuilder->merge($newBuilder);
		$mainBuilder->addBond($mainConnectingNodeId, $newConnectingNodeId, $bondKind, 0);
		
		my %out = (
			"builder" => $mainBuilder,
			"connect-id" => $newConnectingNodeId
		);
		
		return \%out;
	}
	;

molecule_node:
	molecule_node_aux node_branches {
		my $mainBuilder = $T1->{"builder"};
		my $mainConnectingNodeId = $T1->{"connect-id"};
		my $branches = $T2;
		
		my @angles = ( 270, 90 );
		foreach my $b ( 0, 1 ) {
			if ($branches->[$b]->{"builder"}) {
				$mainBuilder->merge($branches->[$b]->{"builder"});
				$mainBuilder->addBond($mainConnectingNodeId,
					$branches->[$b]->{"connect-id"},
					"single",
					$angles[$b]);
			}
		}
		
		my %out = (
			"builder" => $mainBuilder,
			"connect-id" => $mainConnectingNodeId
		);
		return \%out;
	}
	;

molecule_node_aux:
	molecule_node_aux_caption {
		my $nodeCaption = $T1;
		
		my $nodeId = $TT->_getNextNodeId();
		
		my $builder = Builder->new();
		$builder->addNode($nodeId, $nodeCaption);
		
		my %out = (
			"builder" => $builder,
			"connect-id" => $nodeId
		);
		
		return \%out;
	}
	;

molecule_node_aux_caption:
	ATOM_ORGANIC_SUBSET {
		return $T1->{"value"};
	}
	| DESCRIBED_NODE {
		return $T1->{"value"};
	}
	;

node_branches:
	branch branch {
		my @result = ( $T1, $T2 );
		return \@result;
	}
	| branch {
		my %empty = ( "builder" => 0 );
		my @result = ( $T1, \%empty );
		return \@result;
	}
	| { #empty
		my %empty = ( "builder" => 0 );
		my @result = ( \%empty, \%empty );
		return \@result;
	}
	;

branch:
	LPAREN molecule_node_list RPAREN {
		return $T2;
	}
	| LPAREN RPAREN { # empty branch
		my %empty = ( "builder" => 0 );
		return \%empty;
	}
	;

molecule_bond:
	BOND {
		return $T1->{"value"};
	}
	| { # empty
		return "single";
	}
	;
	
%%

## @method public void init()
# Initializes the parser.
# I do not know how to make it be called automatically from new() thus
# the reason for having this method.
#
sub init {
	my ( $this ) = @_;
}

## @method public FigureList parseString(string $filename, string $text)
# Parses given string into list of figures.
# @param $text ESMILES description of the molecule.
# @return List of figures generated from given string.
#
sub parseString {
	my ( $this, $text ) = @_;
	$this->{"lexer"} = new EsmilesLexer();
	$this->{"lexer"}->from($text);
	my $result = $this->YYParse(
		yylex => $this->{"lexer"}->getyylex(),
		yyerror => $this->getyyerror(),
		yydebug => 0);
	return $result;
}

## @method private void _setData(string $key, any $value)
# Sets parser specific data.
# @param $key Look-up key.
# @param $value Value to be stored.
#
sub _setData {
	my ( $this, $key, $value ) = @_;
	$this->YYData->{$key} = $value;
}

## @method private any _getData(string $key, any $default = 0)
# Accesses parser specific data.
# @param $key Look-up key.
# @param $default Default value when no data are stored under the @p $key.
# @return Data stored under the @p $key.
#
sub _getData {
	my ( $this, $key, $default ) = ( @_, 0 );
	if (exists $this->YYData->{$key}) {
		return $this->YYData->{$key};
	} else {
		return $default;
	}
}

sub _getNextNodeId {
	my ( $this ) = @_;
	my $id = $this->_getData(PRIVATE_DATA_NODE_ID_GENERATOR, 1000);
	$this->_setData(PRIVATE_DATA_NODE_ID_GENERATOR, $id + 1);
	return $id;
}

## @method public function getyyerror()
# Creates callback for handling parser errors.
#
sub getyyerror {
	my $this = shift;
	return sub {
		$this->_parseError($this);
	}
}

## @method private void _parseError
# Parse error handler.
#
sub _parseError {
	my ( $this ) = @_;
	my @expected = $this->YYExpect();
	my $expected = $expected[0];
	my $curval = $this->YYCurval;
	if (defined $curval) {
		my $found = $this->YYCurval->{"value"};
		$this->error("Expected `%s', found `%s' instead.", $expected, $found);
	} else {
		$this->error("Expected `%s' instead of end of input.", $expected);
	}
}

## @method private void _recovered()
# Wrapper for standard @c YYErrok.
# Currently does nothing.
#
sub _recovered {
	my ( $this ) = @_;
	$this->YYErrok();
}

## @method protected void debug(string $format, ...)
# Prints debugging information.
# Currently does nothing.
#
sub debug {
	my ( $this, $format, @params ) = @_;
	#printf STDERR "[EsmilesParser.y]: %s\n", sprintf $format, @params;
}

## @method private void _msg(int $line, enum $kind, string $format, ...)
# Prints a message to stderr.
# This method behaves as a printf function (the @p $format parameter).
#
# To supress line number printing, set the line number to a negative (or
# zero) number.
#
# @param $line Line number bounded with the message,
# @param $kind Message kind.
# @param $format Formatting string.
#
sub _msg {
	my ( $this, $kind, $format, @params ) = @_;
	my $errorText = sprintf $format, @params;
	printf STDERR "ESMILES: %s: %s\n", $kind, $errorText;
}

## @method protected void error(int $line, string $format, ...)
# Prints error message.
# @see _msg
# @param $line Error position in the source file (line number).
# @param $format Formatting string.
#
sub error {
	my ( $this, $format, @params ) = @_;
	$this->_msg("error", $format, @params);
}

## @method protected void warn(int $line, string $format, ...)
# Prints warning message.
# @see _msg
# @param $line Position in the source file (line number).
# @param $format Formatting string.
#
sub warn {
	my ( $this, $format, @params ) = @_;
	$this->_msg("warning", $format, @params);
}

sub raiseError {
	my ( $this, $format, @params ) = @_;
	printf STDERR "Error: %s\n", sprintf $format, @params;
}

