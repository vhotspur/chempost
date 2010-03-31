## @class
# Single molecule formula generator.
package Generator;

sub new {
	my ( $self ) = @_;
	my $this = { };
	bless $this;
	$this->{"nodes"} = { };
	return $this;
}


sub setIds {
	my $this = shift @_;
	my @nodeIds = @_;

	foreach my $n ( @nodeIds ) {
		$this->{"nodes"}{$n} = {
			"neighbours" => [],
			"caption" => [ "", "", "" ],
			"inverse-neighbours-count" => 0,
			"drawn" => 0,
		};
	}
}

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

sub setNodeInfo {
	my ( $this, $id, $captionLeft, $captionMiddle, $captionRight ) = @_;

	$this->{"nodes"}->{$id}->{"caption"}
		= [ $captionLeft, $captionMiddle, $captionRight ];
}

sub addBond {
	my ( $this, $from, $to, $type, $angle ) = @_;

	push(@{$this->{"nodes"}->{$from}->{"neighbours"}}, {
		"type" => $type,
		"target" => $to,
		"angle" => $angle
	});
	$this->{"nodes"}->{$to}->{"inverse-neighbours-count"}++;
}

sub _findFirstNode {
	my ( $this ) = @_;

	foreach my $k ( keys (%{$this->{"nodes"}}) ) {
		if ($this->{"nodes"}->{$k}->{"inverse-neighbours-count"} == 0) {
			return $k;
		}
	}

	die "No starting point found!";
}

sub _formatNodeCaption {
	my ( $this, $nodeId ) = @_;

	return sprintf("\"%s\", \"%s\", \"%s\"",
		$this->{"nodes"}->{$nodeId}->{"caption"}->[0],
		$this->{"nodes"}->{$nodeId}->{"caption"}->[1],
		$this->{"nodes"}->{$nodeId}->{"caption"}->[2]
	);
}

sub _drawNode {
	my ( $this, $current ) =  ( @_ );
	my $result = "";
	foreach my $pNeighbour ( @{$this->{"nodes"}->{$current}->{"neighbours"}} ) {
		my $target = $pNeighbour->{"target"};
		# $result .= sprintf("\tpair C%s;\n", $target);
		$result .= sprintf("\tC%s := drawnextnode(C%s, %s, %d, %d, %s);\n",
			$target,
			$current,
			$this->_formatNodeCaption($current),
			$pNeighbour->{"angle"},
			$this->_bondNumber($pNeighbour->{"type"}),
			$this->_formatNodeCaption($target)
		);

		if ($this->{"nodes"}->{$target}->{"drawn"}) {
			next;
		}
		$this->{"nodes"}->{$target}->{"drawn"} = 1;
		$result .= $this->_drawNode($target);
	}

	return $result;
}

sub generateMetaPost {
	my ( $this ) = @_;

	my $first = $this->_findFirstNode();

	my $result = "";
	$result .= sprintf("\tpair C[];\n", $first);

	$result .= sprintf("\tC%s := drawfirstnode( (0,0), \"%s\");\n",
		$first,
		join("", @{$this->{"nodes"}->{$first}->{"caption"}})
	);

	$result .= $this->_drawNode($first);

	return $result;
}


1;
