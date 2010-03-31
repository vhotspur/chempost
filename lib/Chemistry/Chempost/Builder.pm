package Builder;
use Chemistry::Chempost::Generator;


sub new {
	my ( $self ) = @_;
	my $this = { };
	bless $this;
	$this->{"nodes"} = { };
	$this->{"bonds"} = [ ];
	return $this;
}

## Creates a deep copy.
sub copy {
	my ( $this ) = @_;
	my $copy = Builder->new();

	foreach my $id ( keys(%{$this->{"nodes"}}) ) {
		$copy->_addNode($id, $this->{"nodes"}->{$id}->{"caption"});
	}
	
	foreach my $bond ( @{$this->{"bonds"}}) {
		$copy->addBond($bond->{"from"}, $bond->{"to"},
			$bond->{"type"}, $bond->{"angle"});
	}
	
	return $copy;
}

sub _formatCaption {
	my ( $this, $caption ) = @_;

	
	# special cases
	if ($caption eq "OH") {
		return ( "", "\\text{O}", "\\text{H}" );
	}
	if ($caption eq "NH2") {
		return ( "", "\\text{N}", "\\text{H}_2" );
	}
	
	# otherwise, try to split it around 'C' atom and
	# format the numbers as subscripts
	my @parts = ( "", "", "" );
	my $currentPart = 0;
	
	while ($caption =~ /^([A-Z][a-z]*)(([1-9][0-9]*)?)(.*)/) {
		my ( $element, $count, $remainder ) = ( $1, $2, $4 );

		if ($element eq "C") {
			$currentPart = 1;
		}

		my $currentElement = sprintf("\\text{%s}", $element);
		if ($count ne "") {
			$currentElement .= sprintf("_{%s}", $count);
		}

		$parts[$currentPart] .= $currentElement;

		if ($element eq "C") {
			$currentPart = 2;
		}

		$caption = $remainder;
	}

	return @parts;
}

sub addNode {
	my ( $this, $id, $caption ) = @_;

	my @captionSplitted = $this->_formatCaption($caption);
	$this->_addNode($id, \@captionSplitted);
}

sub _addNode {
	my ( $this, $id, $captionSplitted ) = @_;
	
	$this->{"nodes"}->{$id} = {
		"caption" => $captionSplitted,
	};
}

sub addBond {
	my ( $this, $from, $to, $type, $angle ) = @_;

	my %bond = (
		"from" => $from,
		"to" => $to,
		"type" => $type,
		"angle" => $angle
	);

	push(@{$this->{"bonds"}}, \%bond);
}

sub merge {
	my ( $this, $other ) = @_;

	$this->{"nodes"} = {
		%{$this->{"nodes"}},
		%{$other->{"nodes"}}
	};

	push(@{$this->{"bonds"}}, @{$other->{"bonds"}});
}

sub rotate {
	my ( $this, $angleShift ) = @_;
	
	for (my $b = 0; $b < @{$this->{"bonds"}}; $b++) {
		$this->{"bonds"}->[$b]->{"angle"} += $angleShift;
	}
}

sub createGenerator {
	my ( $this ) = @_;

	my $generator = Generator->new();

	my @ids = keys(%{$this->{"nodes"}});

	$generator->setIds(@ids);

	foreach my $id ( keys(%{$this->{"nodes"}}) ) {
		$generator->setNodeInfo($id,
			@{$this->{"nodes"}->{$id}->{"caption"}}
		);
	}

	foreach my $bond ( @{$this->{"bonds"}} ) {
		$generator->addBond(
			$bond->{"from"},
			$bond->{"to"},
			$bond->{"type"},
			$bond->{"angle"}
		);
	}

	return $generator;
}



1;
