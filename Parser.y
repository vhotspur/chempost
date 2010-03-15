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
		my $result = "\n\n";
		$result .= "\n\n";
		$result .= $T1;
		return $result;
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
		return $T1;
	}
	|
	compound_list compound {
		return $T1 . $T2;
	}
	;

compound:
	compound_signature LBRACE compound_command_list RBRACE SEMICOLON {
		my $generator = $T3->createGenerator();

		my $result = "\n\n\n";
		$result .= sprintf("%% %s\n", $T1->{"name"});
		$result .= sprintf("outputtemplate := \"%s.mps\";\n", $T1->{"id"});
		$result .= sprintf("beginfig(0);\n");
		$result .= $generator->generateMetaPost();
		$result .= sprintf("endfig;\n\n");
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

%%

