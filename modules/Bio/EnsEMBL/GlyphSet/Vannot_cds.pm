package Bio::EnsEMBL::GlyphSet::Vannot_cds;
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
		'text'      => 'Novel CDS',
		'font'      => 'Small',
		'colour'	=> $Config->get('Vannot_cds','col'),
		'absolutey' => 1,
    });
		
    $self->label($label);
}

sub _init {
    my ($self) = @_;
    my $Config = $self->{'config'};
    my $chr      = $self->{'container'}->{'chr'};
    my $cds     = $self->{'container'}->{'da'}->get_density_per_chromosome_type( $chr,'novel_cds' );
    my $known_genes = $self->{'container'}->{'da'}->get_density_per_chromosome_type($chr,'known');
    return unless $known_genes->size && $cds->size(); 
    
    my $Hscale_factor =$cds->{'_biggest_value'} / $known_genes->{'_biggest_value'};

    my $cds_col = $Config->get( 'Vannot_cds','col' );
    $cds->scale_to_fit( $Config->get( 'Vannot_cds', 'width' ) * $Hscale_factor );
    $cds->stretch(0);
    my @cds = $cds->get_binvalues();

    foreach (@cds){
	    my $g_x = new Bio::EnsEMBL::Glyph::Rect({
		    'x'      => $_->{'chromosomestart'},
		    'y'      => 0,
		    'width'  => $_->{'chromosomeend'}-$_->{'chromosomestart'},
		    'height' => $_->{'scaledvalue'},
		    'bordercolour' => $cds_col,
		    'absolutey' => 1,
		    'href'   => "/$ENV{'ENSEMBL_SPECIES'}/contigview?chr=$chr&vc_start=$_->{'chromosomestart'}&vc_end=$_->{'chromosomeend'}"
	    });
	$self->push($g_x);
    }
}

1;
