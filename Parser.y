%{
package Parser;
use Data::Dumper;
use Chemistry::Chempost::Builder;
use Chemistry::Chempost::Generator;

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
		my $result = "\n\n";
		$result .= "\n\n";
		$result .= $T2;
		return $result;
	}
	| error {
		 print STDERR Dumper $TT->YYCurtok;
		 print STDERR Dumper $TT->YYCurval;
		 print STDERR Dumper $TT->YYExpect;
		 die "Parse error.";
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
		my $name = $T2;
		my $nodeCount = $T4;
		my $builder = $T7;
		
		$TT->_addMacro($name, $nodeCount, $builder);
		$TT->debug("Defined macro `%s'.", $name);
		# returning name although it is not used anywhere
		return $name;
	}
	;

compound_list:
	compound {
		return $T1;
	}
	|
	compound_list compound {
		return $T1 . $T2;
	}
	;

compound:
	COMPOUNDDEF compound_signature LBRACE compound_command_list RBRACE SEMICOLON {
		my $generator = $T4->createGenerator();

		my $result = "\n\n\n";
		$result .= sprintf("%% %s\n", $T2->{"name"});
		$result .= sprintf("setoutputfilename(\"%s.mps\");\n", $T2->{"id"});
		$result .= sprintf("beginfig(0);\n");
		$result .= $generator->generateMetaPost();
		$result .= sprintf("endfig;\n\n");
		
		$TT->debug("Created compound `%s'.", $T2->{"name"});
		
		return $result;
	};

compound_signature:
	IDENTIFIER {
		my %signature = ("id" => $T1, "name" => $T1);
		return \%signature;
	}
	| IDENTIFIER STRING {
		my %signature = ("id" => $T1, "name" => $T2);
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
		$builder->addNode($T3, $T5);
		return $builder;
	}
	;

compound_command_bond:
	BOND LPAREN NUMBER COMMA NUMBER COMMA BOND_KIND COMMA NUMBER RPAREN {
		my $builder = Builder->new();
		$builder->addBond($T3, $T5, $T7, $T9);
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
		my $description = $T3;
		my $angle = $T5;
		
		# verify that it is of form 1-2=3-4-
		unless ($description =~ /^([1-9][0-9]*[-=#:])+$/) {
			printf STDERR "Cyclic description invalid.\n";
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
		my $macroName = $T3;
		my $angle = $T5;
		my @nodeNumbers = @{$T7};
		
		my $macro = $TT->_getMacro($macroName);
		if ($macro == 0) {
			$TT->raiseError(sprintf("Unknown draw macro `%s'.", $macroName));
			return Builder->new();
		}
		
		$TT->debug("Copying builder of `%s'.", $macroName);
		my $builder = $macro->{"builder"}->copy();
		$TT->debug("Rotating `%s'.", $macroName);
		$builder->rotate($angle);
		
		$TT->debug("Macro `%s' ready to be expanded.", $macroName);
		
		return $builder;
	}
	;

node_number_list:
	NUMBER {
		my @list = ( $T1 );
		return \@list;
	}
	| node_number_list COMMA NUMBER {
		my @list = @{$T1};
		push @list, $T3;
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

sub debug {
	my ( $this, $format, @params ) = @_;
	printf STDERR "[Parser.y]: %s\n", sprintf $format, @params;
}

sub raiseError {
	my ( $this, $description ) = @_;
	printf STDERR "Parser->error: %s\n", $description;
}

