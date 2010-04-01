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
	compound_list {
		return $T1;
	}
	| error {
		 print STDERR Dumper $TT->YYCurtok;
		 print STDERR Dumper $TT->YYCurval;
		 print STDERR Dumper $TT->YYExpect;
		 die "Parse error.";
	}
	;

compound_list:
	compound {
		my @result = ( $T1 );
		return \@result;
	}
	|
	compound_list compound {
		my @result = ( @{$T1}, $T2 );
		return \@result;
	}
	;

compound:
	compound_signature LBRACE compound_command_list RBRACE SEMICOLON {
		my $generator = $T3->createGenerator();

		my $result = "\n\n\n";
		$result .= sprintf("%% %s\n", $T1->{"name"});
		$result .= sprintf("setoutputfilename(\"%s.mps\");\n", $T1->{"id"});
		$result .= sprintf("beginfig(0);\n");
		$result .= $generator->generateMetaPost();
		$result .= sprintf("endfig;\n\n");
		
		my %figure = (
			"code" => $result,
			"id" => $T1->{"id"},
			"name" => $T1->{"name"},
		);
		return \%figure;
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

%%

