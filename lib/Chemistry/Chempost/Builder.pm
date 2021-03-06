## @class
# Compound picture builder.
#
package Builder;
use Chemistry::Chempost::Generator;

## @method new()
# Constructor.
#
sub new {
	my ( $self ) = @_;
	my $this = { };
	bless $this;
	$this->{"nodes"} = { };
	$this->{"bonds"} = [ ];
	return $this;
}

## @method Builder copy()
# Copy constructor.
#
sub copy {
	my ( $this ) = @_;
	my $copy = Builder->new();

	foreach my $id ( keys(%{$this->{"nodes"}}) ) {
		$copy->_addNode($id,
			$this->{"nodes"}->{$id}->{"caption"},
			$this->{"nodes"}->{$id}->{"color"},
		);
	}
	
	foreach my $bond ( @{$this->{"bonds"}}) {
		$copy->addBond($bond->{"from"}, $bond->{"to"},
			$bond->{"type"}, $bond->{"angle"},
			$bond->{"color"});
	}
	
	return $copy;
}

## @method Builder copyRemapped(%nodeMapping)
# Copy constructor with node remapping.
#
sub copyRemapped {
	my ( $this, $nodeMapping ) = @_;
	my $copy = Builder->new();

	foreach my $id ( keys(%{$this->{"nodes"}}) ) {
		$copy->_addNode($nodeMapping->{$id},
			$this->{"nodes"}->{$id}->{"caption"},
			$this->{"nodes"}->{$id}->{"color"},
		);
	}
	
	foreach my $bond ( @{$this->{"bonds"}}) {
		my $from = $nodeMapping->{ $bond->{"from"} };
		my $to = $nodeMapping->{ $bond->{"to"} };
		$copy->addBond($from, $to, $bond->{"type"}, $bond->{"angle"},
			$bond->{"color"});
	}
	
	return $copy;
}

## @method @captionParts _formatCaption(string $caption)
# Formats node caption, splitting it to parts if necessary.
# The method spilts the caption into left-middle-right parts and properly
# formats the subscripts to LaTeX. The splitting is typically done around
# the C atom.
# @param $caption Node caption.
# @return List with left, middle and right part of the caption.
#
sub _formatCaption {
	my ( $this, $caption ) = @_;

	
	# special cases
	if ($caption eq "OH") {
		return ( "", "\\text{O}", "\\text{H}" );
	}
	if ($caption eq "NH2") {
		return ( "", "\\text{N}", "\\text{H}_2" );
	}
	if ($caption eq "O") {
		return ( "", "\\text{O}", "" );
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
	
	# if there was no 'C', we will rather put the whole text
	# in the center than to shift it to the left
	if ($currentPart == 0) {
		@parts = ( "", $parts[0], "" );
	}

	return @parts;
}

## @method void addNode(int $id, string $caption, struct $color)
# Adds a node.
# @param $id Node id.
# @param $caption Node caption.
# @param $color Node color.
#
sub addNode {
	my ( $this, $id, $caption, $color ) = ( @_, 0 );

	my @captionSplitted = $this->_formatCaption($caption);
	$this->_addNode($id, \@captionSplitted, $color);
}

## @method void _addNode(int $id, arrayref $captionSplitted, struct $color)
# Adds a node.
# @param $id Node id.
# @param $captionSplitted Three-member array with caption parts.
# @param $color Node color.
#
sub _addNode {
	my ( $this, $id, $captionSplitted, $color ) = @_;
	
	$this->{"nodes"}->{$id} = {
		"caption" => $captionSplitted,
		"color" => $color,
	};
}

## @method void addBond(int $from, int $to, int $type, int $angle)
# Adds a bond.
# @param $from Starting node id.
# @param $to Target node id.
# @param $type Bond type.
# @param $angle Bond angle.
#
sub addBond {
	my ( $this, $from, $to, $type, $angle, $color ) = @_;

	my %bond = (
		"from" => $from,
		"to" => $to,
		"type" => $type,
		"angle" => $angle,
		"color" => $color,
	);

	push(@{$this->{"bonds"}}, \%bond);
}

## @method void merge(Builder $other)
# Merges with other builder.
# @param $other The other builder.
#
sub merge {
	my ( $this, $other ) = @_;

	$this->{"nodes"} = {
		%{$this->{"nodes"}},
		%{$other->{"nodes"}}
	};

	push(@{$this->{"bonds"}}, @{$other->{"bonds"}});
}

## @method void rotate(int $angleShift)
# Rotates the figure.
# @param $angleShift Rotation angle.
#
sub rotate {
	my ( $this, $angleShift ) = @_;
	
	for (my $b = 0; $b < @{$this->{"bonds"}}; $b++) {
		$this->{"bonds"}->[$b]->{"angle"} += $angleShift;
	}
}

## @method void recolorNodes(struct $color)
# Sets new color to all nodes.
# @param $color New color.
#
sub recolorNodes {
	my ( $this, $color ) = @_;
	
	foreach my $id ( keys %{$this->{"nodes"}} ) {
		$this->{"nodes"}->{$id}->{"color"} = $color;
	}
}

## @method void recolorBonds(struct $color)
# Sets new color to all bonds.
# @param $color New color.
#
sub recolorBonds {
	my ( $this, $color ) = @_;
	
	foreach my $i ( 0..@{$this->{"bonds"}}-1 ) {
		$this->{"bonds"}->[$i]->{"color"} = $color;
	}
}

## @method Generator createGenerator()
# Creates compound generator.
#
sub createGenerator {
	my ( $this ) = @_;

	my $generator = Generator->new();

	my @ids = keys(%{$this->{"nodes"}});

	$generator->setIds(@ids);

	foreach my $id ( keys(%{$this->{"nodes"}}) ) {
		$generator->setNodeInfo($id,
			@{$this->{"nodes"}->{$id}->{"caption"}}
		);
		$generator->setNodeColor($id,
			$this->{"nodes"}->{$id}->{"color"}
		);
	}

	foreach my $bond ( @{$this->{"bonds"}} ) {
		$generator->addBond(
			$bond->{"from"},
			$bond->{"to"},
			$bond->{"type"},
			$bond->{"angle"},
			$bond->{"color"},
		);
	}

	return $generator;
}



1;
