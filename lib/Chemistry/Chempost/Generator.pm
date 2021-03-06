## @class
# Single molecule formula generator.
package Generator;

## @method new()
# Constructor.
#
sub new {
	my ( $self ) = @_;
	my $this = { };
	bless $this;
	$this->{"nodes"} = { };
	return $this;
}

## @method void setIds(@ids)
# Set used node ids.
# @param @ids List of ids.
#
sub setIds {
	my $this = shift @_;
	my @nodeIds = @_;

	foreach my $n ( @nodeIds ) {
		$this->{"nodes"}{$n} = {
			"neighbours" => [],
			"caption" => [ "", "", "" ],
			"inverse-neighbours-count" => 0,
			"drawn" => 0,
			"color" => 0,
		};
	}
}

## @method int _bondNumber(string $kind)
# Converts bond string to internal numeric representation.
# When the @p $kind is not recognised, it is treated as a single bond.
# @param $kind Bond kind.
#
sub _bondNumber {
	my ( $this, $kind ) = @_;
	if ($kind eq "single") {
		return 1;
	} elsif ($kind eq "double") {
		return 2;
	} elsif ($kind eq "triple") {
		return 3;
	} elsif ($kind eq "aromatic") {
		return 4;
	} elsif ($kind eq "aromatic2") {
		return 5;
	} else {
		return 1;
	}
}

## @method void setNodeInfo(int $id, string $captionLeft, string $captionMiddle, string $captionRight)
# Sets node details.
# @param $id Node id.
# @param $captionLeft Left part of the node caption.
# @param $captionMiddle Middle part of the node caption.
# @param $captionRight Right part of the node caption.
#
sub setNodeInfo {
	my ( $this, $id, $captionLeft, $captionMiddle, $captionRight ) = @_;

	$this->{"nodes"}->{$id}->{"caption"}
		= [ $captionLeft, $captionMiddle, $captionRight ];
}

## @method void setNodeColor(int $id, struct $color)
# Sets node color.
# The structure passed in @p $color shall have @c metapost field with
# string describing the color in format recognised by MetaPost.
# @param $id Node id.
# @param $color Node color.
#
sub setNodeColor {
	my ( $this, $id, $color ) = @_;
	
	$this->{"nodes"}->{$id}->{"color"} = $color;
}

## @method void addBond(int $from, int $to, int $type, int $angle, struct $color)
# Adds a bond between two nodes.
# @param $from Starting node.
# @param $to Target node.
# @param $type Bond type.
# @param $angle Bond angle (0 being at 3 o'clock).
# @param $color Bond color.
#
sub addBond {
	my ( $this, $from, $to, $type, $angle, $color ) = @_;

	push(@{$this->{"nodes"}->{$from}->{"neighbours"}}, {
		"type" => $type,
		"target" => $to,
		"angle" => $angle,
		"color" => $color,
	});
	$this->{"nodes"}->{$to}->{"inverse-neighbours-count"}++;
}

## @method int _findFirstNode()
# Finds possible first node to start drawing from.
# @warning This method is not fully implemented and might end via call
# to die() when true cycle is found.
#
sub _findFirstNode {
	my ( $this ) = @_;

	foreach my $k ( keys (%{$this->{"nodes"}}) ) {
		if ($this->{"nodes"}->{$k}->{"inverse-neighbours-count"} == 0) {
			return $k;
		}
	}

	die "No starting point found!";
}

## @method string _formatNodeCaption(int $nodeId)
# Formats node caption for the MetaPost macro.
# @param $nodeId Node id.
# @return Quoted comma-separated list of strings.
#
sub _formatNodeCaption {
	my ( $this, $nodeId ) = @_;

	return sprintf("\"%s\", \"%s\", \"%s\"",
		$this->{"nodes"}->{$nodeId}->{"caption"}->[0],
		$this->{"nodes"}->{$nodeId}->{"caption"}->[1],
		$this->{"nodes"}->{$nodeId}->{"caption"}->[2]
	);
}

## @method string _getMetapostColor(struct $color, string $defaultColor)
# Tells color in MetaPost-recognisable manner.
#
# The actual is determined by the contents of the $p $color structure.
# First, if the @c metapost field is present, its color is used.
# Next, @c rgb field is tested and is expected to be a 3-member array
# with red, green and blue components within range 0-255.
# Otherwise, @p $defaultColor is used (which is expected
# to already be in MetaPost format).
#
# @param $color The color structure.
# @param $defaultColor Default color.
# @return MetaPost compliant color specification.
#
sub _getMetapostColor {
	my ( $this, $colorStruct, $defaultColor ) = @_;
	
	my $color = $defaultColor;
	
	if (exists $colorStruct->{"metapost"}) {
		$color = $colorStruct->{"metapost"};
	} elsif (exists $colorStruct->{"rgb"}) {
		my @rgb = @{$colorStruct->{"rgb"}};
		for (my $i = 0; $i < @rgb; $i++) {
			$rgb[$i] = ($rgb[$i] + 0.0)/255.0;
		}
		$color = sprintf("(%.4f,%.4f,%.4f)", @rgb);
	}
	
	return $color;
}

## @method string _getNodeMetapostColor(int $nodeId)
# Tells color of a node in format suitable for MetaPost.
# @param $nodeId Node id.
# @return Color of the node in MetaPost format.
#
sub _getNodeMetapostColor {
	my ( $this, $nodeId ) = @_;
	
	return $this->_getMetapostColor(
		$this->{"nodes"}->{$nodeId}->{"color"},
		"defaultnodecolor");
	
	return $color;
}

## @method string _drawNode(int $current)
# Recursively prepares MetaPost output for drawing a node.
# @param $current Current node (the node to be drawn).
#
sub _drawNode {
	my ( $this, $current ) =  ( @_ );
	my $result = "";
	foreach my $pNeighbour ( @{$this->{"nodes"}->{$current}->{"neighbours"}} ) {
		my $target = $pNeighbour->{"target"};
		
		$result .= sprintf("\tC%s := drawnextnode(C%s, %s, %d, %d, %s, %s, %s);\n",
			$target,
			$current,
			$this->_formatNodeCaption($current),
			$pNeighbour->{"angle"},
			$this->_bondNumber($pNeighbour->{"type"}),
			$this->_getMetapostColor($pNeighbour->{"color"}, "defaultbondcolor"),
			$this->_formatNodeCaption($target),
			$this->_getNodeMetapostColor($target),
		);

		if ($this->{"nodes"}->{$target}->{"drawn"}) {
			next;
		}
		$this->{"nodes"}->{$target}->{"drawn"} = 1;
		$result .= $this->_drawNode($target);
	}

	return $result;
}

## @method string generateMetaPost()
# Generates MetaPost output.
#
sub generateMetaPost {
	my ( $this ) = @_;

	my $first = $this->_findFirstNode();

	my $result = "";
	$result .= sprintf("\tpair C[];\n", $first);

	$result .= sprintf("\tC%s := drawfirstnode( (0,0), \"%s\", %s);\n",
		$first,
		join("", @{$this->{"nodes"}->{$first}->{"caption"}}),
		$this->_getNodeMetapostColor($first),
	);

	$result .= $this->_drawNode($first);

	return $result;
}


1;
