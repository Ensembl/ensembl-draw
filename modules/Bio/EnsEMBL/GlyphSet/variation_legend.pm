package Bio::EnsEMBL::GlyphSet::variation_legend;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Sanger::Graphics::Glyph::Text({
        'text'      => 'Variation legend',
        'font'      => 'Small',
        'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;

    return unless ($self->strand() == -1);

    my $BOX_HEIGHT    = 4;
    my $BOX_WIDTH     = 10;
    my $NO_OF_COLUMNS = 4;
    my $FONTNAME      = "Tiny";

    my $vc            = $self->{'container'};
    my $Config        = $self->{'config'};
    my $im_width      = $Config->image_width();
    my $type          = $Config->get('variation_legend', 'src');

    my @colours;
    return unless $Config->{'variation_legend_features'};
    my %features = %{$Config->{'variation_legend_features'}};
    return unless %features;

    my ($x,$y) = (0,0);
#    my $rect = new Sanger::Graphics::Glyph::Rect({
#       'x'         => 0,
#       'y'         => 0,
#       'width'     => $im_width, 
#       'height'    => 0,
#       'colour'    => 'grey3',
#       'absolutey' => 1,
#       'absolutex' => 1,'absolutewidth'=>1,
#    });
#    $self->push($rect);
    
    foreach (sort { $features{$b}->{'priority'} <=> $features{$a}->{'priority'} } keys %features) {
        @colours = @{$features{$_}->{'legend'}};

        $y++ unless $x==0;
        $x=0;
        while( my ($legend, $colour) = splice @colours, 0, 2 ) {
            $self->push(new Sanger::Graphics::Glyph::Rect({
                'x'         => $im_width * $x/$NO_OF_COLUMNS,
                'y'         => $y * $BOX_HEIGHT * 2 + 6,
                'width'     => $BOX_WIDTH, 
                'height'    => $BOX_HEIGHT,
                'colour'    => $colour,
                'absolutey' => 1,
                'absolutex' => 1,'absolutewidth'=>1,
            }));
            $self->push(new Sanger::Graphics::Glyph::Text({
                'x'         => $im_width * $x/$NO_OF_COLUMNS + $BOX_WIDTH,
                'y'         => $y * $BOX_HEIGHT * 2 + 4,
                'height'    => $Config->texthelper->height($FONTNAME),
                'font'      => $FONTNAME,
                'colour'    => $colour,
                'text'      => uc(" $legend"),
                'absolutey' => 1,
                'absolutex' => 1,'absolutewidth'=>1,
            }));
            $x++;
            if($x==$NO_OF_COLUMNS) {
                $x=0;
                $y++;
            }
        }
    }
}

1;
        
