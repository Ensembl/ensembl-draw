package Bio::EnsEMBL::GlyphSet::Vannot_pseudo;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Poly;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Line;
use SiteDefs;

sub init_label {
    my ($self) = @_;
    my $Config = $self->{'config'};	
    my $label = new Bio::EnsEMBL::Glyph::Text({
		'text'      => 'Pseudo',
		'font'      => 'Small',
		'colour'	=> $Config->get('Vannot_pseudo','col'),
		'absolutey' => 1,
    });
		
    $self->label($label);
}

sub _init {
    my ($self) = @_;
    my $Config = $self->{'config'};
    my $chr      = $self->{'container'}->{'chr'};
    my $pseudo     = $self->{'container'}->{'da'}->get_density_per_chromosome_type( $chr,'pseudo' );
    my $known_genes = $self->{'container'}->{'da'}->get_density_per_chromosome_type($chr,'known');
    return unless $known_genes->size && $pseudo->size(); 

return unless     $pseudo->{'_biggest_value'} && $known_genes->{'_biggest_value'};

    my $Hscale_factor = $pseudo->{'_biggest_value'}/$known_genes->{'_biggest_value'} ;

    my $pseudo_col = $Config->get( 'Vannot_pseudo','col' );
    $pseudo->scale_to_fit( $Config->get( 'Vannot_pseudo', 'width' ) * $Hscale_factor);
    $pseudo->stretch(0);
    my @pseudo = $pseudo->get_binvalues();

    foreach (@pseudo){
	    my $g_x = new Bio::EnsEMBL::Glyph::Rect({
		    'x'      => $_->{'chromosomestart'},
		    'y'      => 0,
		    'width'  => $_->{'chromosomeend'}-$_->{'chromosomestart'},
		    'height' => $_->{'scaledvalue'},
		    'bordercolour' => $pseudo_col,
		    'absolutey' => 1,
		    'href'   => "/$ENV{'ENSEMBL_SPECIES'}/contigview?chr=$chr&vc_start=$_->{'chromosomestart'}&vc_end=$_->{'chromosomeend'}"
	    });
	$self->push($g_x);
    }
}

1;
