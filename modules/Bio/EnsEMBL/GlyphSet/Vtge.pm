package Bio::EnsEMBL::GlyphSet::Vtge;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Poly;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Line;

sub init_label {
    my ($self) = @_;
    my $Config = $self->{'config'};	
    my $label = new Sanger::Graphics::Glyph::Text({
		'text'      => 'Targetted',
		'font'      => 'Small',
		'colour'	=> $Config->get('Vtge','col'),
		'absolutey' => 1,
    });
    $self->label($label);
    $label = new Sanger::Graphics::Glyph::Text({
		'text'      => 'Genewise',
		'font'      => 'Small',
		'colour'	=> $Config->get('Vtge','col'),
		'absolutey' => 1,
    });
		
    $self->label2($label);
}

sub _init {
    my ($self) = @_;
    my $Config = $self->{'config'};
    my $chr    = $self->{'container'}->{'chr'};
    my $tge    = $self->{'container'}->{'da'}->get_density_per_chromosome_type( $chr,'TGE_gw' );
    return unless $tge->size(); # Return nothing if their is no data
    
    my $tge_col = $Config->get( 'Vtge','col' );
	
    $tge->scale_to_fit( $Config->get( 'Vtge', 'width' ) );
    $tge->stretch(0);
    my @tge = $tge->get_binvalues();

    foreach (@tge){
	$self->push(new Sanger::Graphics::Glyph::Rect({
		'x'      => $_->{'chromosomestart'},
		'y'      => 0,
		'width'  => $_->{'chromosomeend'}-$_->{'chromosomestart'},
		'height' => $_->{'scaledvalue'},
		'bordercolour' => $tge_col,
		'absolutey' => 1,
		'href'   => "/@{[$self->{container}{_config_file_name_}]}/contigview?chr=$chr&vc_start=$_->{'chromosomestart'}&vc_end=$_->{'chromosomeend'}"
	}));
    }
}

1;
