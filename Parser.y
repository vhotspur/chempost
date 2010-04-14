%{
package Parser;
use Data::Dumper;
use Chemistry::Chempost::Builder;
use Chemistry::Chempost::Generator;
use Chemistry::Chempost::Lexer;

%}

%token IDENTIFIER
%token NODE
%token BOND UNBOND
%token BOND_KIND
%token LBRACE RBRACE LPAREN RPAREN
%token SEMICOLON COMMA
%token STRING NUMBER

%start chempost

%%

chempost:
	macro_definitions compound_list {
		return $T2;
	}
	| error {
		$TT->_recovered();
		my @result = ();
		return \@result;
	}
	;

macro_definitions:
	macro_definition_list {
		# no action here, changes done directly to $TT
		return 0;
	}
	| {
		# empty
		# no action here, changes done directly to $TT
		return 0;
	}
	;

macro_definition_list:
	macro_definition {
		# no action here, changes done directly to $TT
		return 0;
	}
	| macro_definition_list macro_definition {
		# no action here, changes done directly to $TT
		return 0;
	}
	;

macro_definition:
	MACRODEF IDENTIFIER LPAREN NUMBER RPAREN
			LBRACE compound_command_list RBRACE SEMICOLON {
		my $name = $T2->{"value"};
		my $nodeCount = $T4->{"value"};
		my $builder = $T7;
		
		$TT->_addMacro($name, $nodeCount, $builder);
		$TT->debug("Defined macro `%s'.", $name);
		# returning name although it is not used anywhere
		return $name;
	}
	;

compound_list:
	compound {
		my @result = ( $T1 );
		if ($T1 == 0) {
			@result = ();
		}
		return \@result;
	}
	|
	compound_list compound {
		my @result = ( @{$T1}, $T2 );
		if ($T2 == 0) {
			@result = ( @{$T1} );
		}
		return \@result;
	}
	;

compound:
	COMPOUNDDEF compound_signature LBRACE compound_command_list RBRACE SEMICOLON {
		my $signature = $T2;
		my $commands = $T4;
		my $generator = $commands->createGenerator();

		if ($TT->_getData("compound-invalid", 0)) {
			$TT->raiseError("Ignoring compound `%s'.", $signature->{"name"});
			$TT->_setData("compound-invalid", 0);
			return 0;
		}
		
		my $result = "\n\n\n";
		$result .= sprintf("%% %s\n", $signature->{"name"});
		$result .= sprintf("setoutputfilename(\"%s.mps\");\n", $signature->{"id"});
		$result .= sprintf("beginfig(0);\n");
		$result .= $generator->generateMetaPost();
		$result .= sprintf("endfig;\n\n");
		
		$TT->debug("Created compound `%s'.", $signature->{"name"});
		
		my %figure = (
			"code" => $result,
			"id" => $signature->{"id"},
			"name" => $signature->{"name"},
		);
		return \%figure;
	}
	| COMPOUNDDEF compound_signature error RBRACE SEMICOLON {
		my $signature = $T2;
		
		$TT->raiseError("Invalid compound `%s' definition.", $signature->{"name"});
		
		$TT->_recovered();
		
		return 0;
	}
	;

compound_signature:
	IDENTIFIER {
		my %signature = ("id" => $T1->{"value"}, "name" => $T1->{"value"});
		return \%signature;
	}
	| IDENTIFIER STRING {
		my %signature = ("id" => $T1->{"value"}, "name" => $T2->{"value"});
		return \%signature;
	}
	;

compound_command_list:
	compound_command {
		return $T1;
	}
	| compound_command_list compound_command {
		$T1->merge($T2);
		return $T1;
	}
	;


compound_command:
	compound_command_aux SEMICOLON {
		return $T1;
	}
	| error SEMICOLON {
		$TT->debug("bad command encountered");
		$TT->_setData("compound-invalid", 1);
		$TT->_recovered();
		return Builder->new();
	}
	;

compound_command_aux:
	compound_command_empty {
		return $T1;
	}
	| compound_command_node {
		return $T1;
	}
	| compound_command_bond {
		return $T1;
	}
	| compound_command_unbond {
		return $T1;
	}
	| compound_command_cyclic {
		return $T1;
	}
	| compound_command_draw {
		return $T1;
	}
	;

compound_command_empty: {
		return Builder->new();
	}
	;

compound_command_node:
	NODE LPAREN NUMBER COMMA STRING RPAREN {
		my $builder = Builder->new();
		$builder->addNode($T3->{"value"}, $T5->{"value"});
		return $builder;
	}
	;

compound_command_bond:
	BOND LPAREN NUMBER COMMA NUMBER COMMA BOND_KIND COMMA NUMBER RPAREN {
		my $builder = Builder->new();
		$builder->addBond($T3->{"value"}, $T5->{"value"}, $T7->{"value"}, $T9->{"value"});
		return $builder;
	}
	;

compound_command_unbond:
	UNBOND LPAREN NUMBER COMMA BOND_KIND COMMA NUMBER RPAREN {
		my $builder = Builder->new();
		return $builder;
	}
	;

compound_command_cyclic:
	CYCLIC LPAREN STRING COMMA NUMBER RPAREN {
		my $description = $T3->{"value"};
		my $angle = $T5->{"value"};
		
		# verify that it is of form 1-2=3-4-
		unless ($description =~ /^([1-9][0-9]*[-=#:])+$/) {
			$TT->raiseError("Cyclic description `%s' invalid.", $description);
			return Builder->new();
		}
		
		my @nodeNumbers = ();
		my @bondTypes = ();
		while ($description ne "") {
			my ( $nodeId, $bond, $remaining ) = ($description =~ /^([1-9][0-9]*)([-=#:])(.*)/);
			
			push @nodeNumbers, $nodeId;
			
			if ($bond eq "-") {
				$bond = "single";
			} elsif ($bond eq "=") {
				$bond = "double";
			} elsif ($bond eq ":") {
				$bond = "aromatic";
			} else {
				$bond = "triple";
			}
			push @bondTypes, $bond;
			
			$description = $remaining;
		}
		
		my $builder = Builder->new();
		
		foreach my $n ( @nodeNumbers ) {
			$builder->addNode($n, "");
		}
		
		my $angleShift = 360/@nodeNumbers;
		
		for (my $i = 0; $i < @nodeNumbers - 1; $i++) {
			$builder->addBond($nodeNumbers[$i], $nodeNumbers[$i + 1],
				$bondTypes[$i], $angle);
			
			$angle += $angleShift;
			$angle = $angle % 360;
		}
		
		# this prevents the creation of a real cycle
		# when this would be fixed in the Generator, this line
		# could be amalgamated with the previous for-loop
		# that would also include the awful workaround for aromatic bond
		# where the direction is reversed :-(
		if ($bondTypes[-1] eq "aromatic") {
			$bondTypes[-1] = "aromatic2";
		}
		$builder->addBond($nodeNumbers[0], $nodeNumbers[-1], $bondTypes[-1], (180 + $angle) % 360);
		
		return $builder;
	}
	;

compound_command_draw:
	DRAW LPAREN IDENTIFIER COMMA NUMBER COMMA node_number_list RPAREN {
		my $macroName = $T3->{"value"};
		my $angle = $T5->{"value"};
		my @nodeNumbers = @{$T7};
		
		my $macro = $TT->_getMacro($macroName);
		if ($macro == 0) {
			$TT->raiseError("Unknown draw macro `%s'.", $macroName);
			return Builder->new();
		}
		
		if (scalar(@nodeNumbers) != $macro->{"nodes"}) {
			$TT->raiseError("Invalid number of arguments for `%s'", $macroName);
			return Builder->new();
		}
		
		$TT->debug("Copying builder of `%s'.", $macroName);
		my %mapping;
		for (my $i = 1; $i <= $macro->{"nodes"}; $i++) {
			$mapping{$i} = $nodeNumbers[$i - 1];
		}
		my $builder = $macro->{"builder"}->copyRemapped(\%mapping);
		
		
		$TT->debug("Rotating `%s'.", $macroName);
		$builder->rotate($angle);
		
		$TT->debug("Macro `%s' ready to be expanded.", $macroName);
		
		return $builder;
	}
	;

node_number_list:
	NUMBER {
		my @list = ( $T1->{"value"} );
		return \@list;
	}
	| node_number_list COMMA NUMBER {
		my @list = @{$T1};
		push @list, $T3->{"value"};
		return \@list;
	}
	;

%%

## Initializes the Parser.
# I do not know how to make it be called automatically from new() thus
# the reason for having this method.
# 
sub init {
	my ( $this ) = @_;
	$this->{"macros"} = { };
}

sub parseString {
	my ( $this, $input ) = @_;
	$this->{"lexer"} = new Lexer();
	$this->{"lexer"}->from($input);
	my $result = $this->YYParse(
		yylex => $this->{"lexer"}->getyylex(),
		yyerror => $this->getyyerror(),
		yydebug => 0);
	return $result;
}

sub _getMacro {
	my ( $this, $macroName ) = @_;
	
	if (not exists($this->{"macros"}->{$macroName})) {
		return 0;
	}
	
	return $this->{"macros"}->{$macroName};
}

sub _addMacro {
	my ( $this, $name, $nodeCount, $builder ) = @_;
	$this->{"macros"}->{$name} = {
		"nodes" => $nodeCount,
		"builder" => $builder
	};
}

sub _setData {
	my ( $this, $key, $value ) = @_;
	$this->YYData->{$key} = $value;
}

sub _getData {
	my ( $this, $key, $default ) = ( @_, 0 );
	if (exists $this->YYData->{$key}) {
		return $this->YYData->{$key};
	} else {
		return $default;
	}
}

sub getyyerror {
	my $this = shift;
	return sub {
		$this->_parseError($this);
	}
}

sub _parseError {
	my ( $this ) = @_;
	my @expected = $this->YYExpect();
	my $curval = $this->YYCurval;
	if (defined $curval) {
		my $found = $this->YYCurval->{"value"};
		my $line = $this->YYCurval->{"line"};
		$this->raiseError("Parsing failed: `%s' expected at line %d (got `%s').",
			$expected[0], $line, $found);
	} else {
		$this->raiseError("Parsing failed: `%s' expected but end of file found.",
			$expected[0]);
	}
		
}

sub _recovered {
	my ( $this ) = @_;
	$this->YYErrok();
}

sub debug {
	my ( $this, $format, @params ) = @_;
	#printf STDERR "[Parser.y]: %s\n", sprintf $format, @params;
}

sub raiseError {
	my ( $this, $format, @params ) = @_;
	printf STDERR "Error: %s\n", sprintf $format, @params;
}

