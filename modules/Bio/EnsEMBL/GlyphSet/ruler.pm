package Bio::EnsEMBL::GlyphSet::ruler;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Poly;

sub init_label {
    my ($self) = @_;
	
    return if defined($self->{'config'}->{'_no_label'});
    my $label = new Bio::EnsEMBL::Glyph::Text({
	'text'      => 'Length',
	'font'      => 'Small',
	'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;
    my $Config        = $self->{'config'};

    return unless ($self->strand() == 1);
    my $len            = $self->{'container'}->length();
    my $global_start   = $self->{'container'}->chr_start();
    my $global_end     = $self->{'container'}->chr_end();
    my $highlights     = $self->highlights();
    my $im_width       = $Config->image_width();
    my $feature_colour = $Config->get('ruler','col');
    my $fontname       = "Tiny";
    my $fontheight     = $Config->texthelper->height($fontname),
    my $fontwidth      = $Config->texthelper->width($fontname),

    #####################################################################
    # The ruler has to be drawn in absolute x, because when the length is
    # too small the rounding errors screw everything
    #####################################################################

    my $text = int($global_end - $global_start+1);		
    $text = bp_to_nearest_unit($text). " ";		

    my $bp_textwidth = $fontwidth * length($text);
    my $im_width_bp  = $Config->image_width();
    
    my $tglyph = new Bio::EnsEMBL::Glyph::Text({
	'x'         => int($im_width_bp/2) - int($bp_textwidth/2),
	'y'         => 2,
	'height'    => $fontheight,
	'font'      => $fontname,
	'colour'    => $feature_colour,
	'text'      => $text,
	'absolutex' => 1,
	'absolutey' => 1,
    });
    $self->push($tglyph);
    $bp_textwidth = $fontwidth * (length($text)+3);
    
    
    my $lglyph = new Bio::EnsEMBL::Glyph::Rect({
	'x'         => 0,
	'y'         => 6,
	'width'     => int($im_width_bp/2) - int($bp_textwidth/2),
	'height'    => 0,
	'colour'    => $feature_colour,
	'absolutex' => 1,
	'absolutey' => 1,
    });
    $self->push($lglyph);
    
    my $rglyph = new Bio::EnsEMBL::Glyph::Rect({
	'x'         => int($im_width_bp/2) + int($bp_textwidth/2),
	'y'         => 6,
	'width'     => $im_width_bp - (int($im_width_bp/2) + int($bp_textwidth/2)),
	'height'    => 0,
	'colour'    => $feature_colour,
	'absolutex' => 1,
	'absolutey' => 1,
    });
    $self->push($rglyph);
    
    # to get aroung px->postion problems we make each arrow head
    # exactly 2 text chars long
    # add the left arrow head....
    my $gtriagl = new Bio::EnsEMBL::Glyph::Poly({
	'points'    => [0,6, ($fontwidth*2),3, ($fontwidth*2),9],
	'colour'    => $feature_colour,
	'absolutex' => 1,
	'absolutey' => 1,
    });    
    $self->push($gtriagl);
    
    # add the right arrow head....
    my $gtriagr = new Bio::EnsEMBL::Glyph::Poly({
	'points'    => [$im_width_bp,6, ($im_width_bp-$fontwidth*2),3, ($im_width_bp-$fontwidth*2),9],
	'colour'    => $feature_colour,
	'absolutex' => 1,
	'absolutey' => 1,
    });
    $self->push($gtriagr);
}

1;

sub bp_to_nearest_unit {
    my $bp = shift;
    my @units = qw( bp Kb Mb Gb Tb );
    
    my $power_ranger = int( ( length( abs($bp) ) - 1 ) / 3 );
    my $unit = $units[$power_ranger];
    my $unit_str;

    my $value = int( $bp / ( 10 ** ( $power_ranger * 3 ) ) );
      
    if ( $unit ne "bp" ) {
	$unit_str = sprintf( "%.2f%s", $bp / ( 10 ** ( $power_ranger * 3 ) ), " $unit" );
    } else {
	$unit_str = "$value $unit";
    }

    return $unit_str;
}
