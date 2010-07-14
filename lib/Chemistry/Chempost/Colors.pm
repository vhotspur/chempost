package Chemistry::Chempost::Colors;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&recogniseColor);

use Chemistry::Chempost::ColorNames;

sub recogniseColor {
	my ( $color ) = @_;
	
	if ($color =~ /^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/) {
		# standard web '#RRGGBB' notation
		my ( $red, $green, $blue ) = ( hex $1, hex $2, hex $3 );
		my %result = (
			"rgb" => [ $red, $green, $blue ],
		);
		return \%result;
	} elsif ($color =~ /^#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$/) {
		# shortened web '#RGB' notation
		my ( $red, $green, $blue ) = ( hex $1.$1, hex $2.$2, hex $3.$3 );
		my %result = (
			"rgb" => [ $red, $green, $blue ],
		);
		return \%result;
	} else {
		# will go through list of known color names
		my $colorNames = $colorDatabase{"names"};
		my $colorIdx;
		$color = lc($color);
		for ($colorIdx = 0; $colorIdx < @{$colorNames}; $colorIdx++) {
			if (lc($colorNames->[$colorIdx]) eq $color) {
				return recogniseColor(
					$colorDatabase{"rgb"}->[$colorIdx]);
			}
		}
			
		return 0;
	}
}

1;
