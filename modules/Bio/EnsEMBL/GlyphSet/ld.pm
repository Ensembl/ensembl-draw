package Bio::EnsEMBL::GlyphSet::ld;
use strict;
use base qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Poly;
use Sanger::Graphics::Glyph::Text;

sub init_label {
  my $self = shift;
  $self->label(new Sanger::Graphics::Glyph::Text({
    'text'      => "LD",
    'font'      => 'Small',
    'absolutey' => 1,
  }));
}

sub _init {
  my ($self) = @_;
  return unless ($self->strand() == -1);
  my @data = ${$self->{'container'}->get_all_LD_values };  ## returns arrayref of hashes with all the data


  # Get snps in an array, sorted by position
  my $number_of_snps = scalar(
    my @snps  = sort { $a->start <=> $b->start }
		grep { $_->map_weight < 4 } 
		  @{$self->{'container'}->get_all_VariationFeatures()})-2;

  return unless $number_of_snps;

  # Returns the hexadecimal colour codes
  my @colour_gradient = $self->{'config'}->colourmap->build_linear_gradient( 40, 'white','pink','red' );

  my $height_ppb   = $self->{'config'}->transform()->{'scalex'};

  # Work out which snps have dprime values
  my @dprime_values;
  foreach my $m ( 0..$number_of_snps ) {
    foreach my $n ( reverse($m..$number_of_snps) ) {
      my $value = $self->{'container'}->d_prime($snps[$m], $snps[$n+1]);
      warn "$m, $n+1";
      $dprime_values[$m][$n+1] = $value if $value;
    }
  }

  unless (@dprime_values) {
    warn "no dprime values";## errortrack stuff
  }

  foreach my $m ( 0..$number_of_snps ) {
    next unless $dprime_values[$m];
    my $d2 = ($snps[$m+1]->start - $snps[$m]->start )/2 ;  # midway pt btween m m+1

    foreach my $n ( reverse($m..$number_of_snps) ) {
      my( $x, $y, $d1 ) = ( ($snps[$n]->start +   $snps[$m]->start )/2, 
			    ($snps[$n]->start -   $snps[$m]->start )/2, 
			    ($snps[$n+1]->start - $snps[$n]->start )/2 );
      my $flag_triangle = $y-$d2;  # top box is a triangle

      #get the r square ld value
      #my $value =  int( 1 + 38 * rand() );  # r2 d' or lod
      my $value = $dprime_values[$m][$n+1]*40;
      my $colour = $value ? $colour_gradient[$value] : "gray64";

      $self->push( Sanger::Graphics::Glyph::Poly->new({
        'points' => [$x, $y*$height_ppb, 
		     $flag_triangle < 0 ? (): ($x+$d2, $flag_triangle*$height_ppb), 
		     $x+$d1+$d2, 
		     ($y+$d1-$d2)*$height_ppb, 
		     $x+$d1, 
		     ($y+$d1)*$height_ppb ],
        'colour' => $colour,
        'alt' => $value
      }));
    }
  }
}


1;
