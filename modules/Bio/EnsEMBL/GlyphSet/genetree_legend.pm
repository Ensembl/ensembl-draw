package Bio::EnsEMBL::GlyphSet::genetree_legend;

use strict;
use Bio::EnsEMBL::GlyphSet;
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);
our @ISA = qw(Bio::EnsEMBL::GlyphSet);

sub init_label {
  my ($self) = @_;
  my $Config        = $self->{'config'};
  return if( defined $Config->{'_no_label'} );
  $self->init_label_text( 'Legend' );
}

sub _init {
  my ($self) = @_;

  return unless ($self->strand() == -1);

  my $BOX_WIDTH     = 20;
  my $NO_OF_COLUMNS = 4;

  my $vc            = $self->{'container'};
  my $Config        = $self->{'config'};
  my $im_width      = $Config->image_width();
  my $type          = $Config->get('genetree_legend', 'src');
 
  my( $fontname, $fontsize ) = $self->get_font_details( 'legend' );
  my @res = $self->get_text_width( 0, 'X', '', 'font'=>$fontname, 'ptsize' => $fontsize );
  my $th = $res[3];
  my $pix_per_bp = $self->{'config'}->transform()->{'scalex'};

  my @branches = (
    ['x1 branch length', 'blue', undef],
    ['x10 branch length', 'blue', 1],
    ['x100 branch length', 'red', 1]
  );
  my @orthos = (
    ['current gene', 'red', 'PAX2 Homo sapiens'],
    ['orthologue', 'black', 'PAX2 Mus musculus'],
    ['paralogue', 'blue', 'PAX7 Homo sapiens'],
  );
  my @nodes = (
    ['speciation node', 'navyblue'],
    ['duplication node', 'red3'],
  );
  my @boxes = (
    ['AA alignment match/mismatch', 'yellowgreen', 'yellowgreen'],
    ['AA alignment gap', 'white', 'yellowgreen'],
  );

  my ($legend, $colour, $style, $border, $label, $text);

  $self->push(new Sanger::Graphics::Glyph::Text({
        'x'         => 0,
        'y'         => 0,
        'height'    => $th,
        'valign'    => 'center',
        'halign'    => 'left',
        'ptsize'    => $fontsize,
        'font'      => $fontname,
        'colour'   =>  'black',
        'text'      => 'LEGEND',
        'absolutey' => 1,
        'absolutex' => 1,
        'absolutewidth'=>1

        })
      );


  my ($x,$y) = (0, 0);
  foreach my $branch (@branches) {
    ($legend, $colour, $style) = @$branch;
    $self->push(new Sanger::Graphics::Glyph::Line({
      'x'         => $im_width * $x/$NO_OF_COLUMNS,
      'y'         => $y * ( $th + 3 ) + 8 + $th,
      'width'     => 20,
      'height'    => 0,
      'colour'    => $colour,
      'dotted'    => $style,
      })
    );
    $label = _create_label($im_width, $x, $y, $NO_OF_COLUMNS, $BOX_WIDTH, $th, $fontsize, $fontname, $legend);
    $self->push($label);
    $y++;
  }
  
  ($x, $y) = (1, 0);
  foreach my $ortho (@orthos) {
    ($legend, $colour, $text) = @$ortho;
    $self->push(new Sanger::Graphics::Glyph::Text({
        'x'         => $im_width * $x/$NO_OF_COLUMNS,
        'y'         => $y * ( $th + 3 ) + $th,
        'height'    => $th,
        'valign'    => 'center',
        'halign'    => 'left',
        'ptsize'    => $fontsize,
        'font'      => $fontname,
        'colour'   =>  $colour,
        'text'      => $text,
        'absolutey' => 1,
        'absolutex' => 1,
        'absolutewidth'=>1

        })
      );
    $label = _create_label($im_width, $x, $y, $NO_OF_COLUMNS, $BOX_WIDTH + 80, $th, $fontsize, $fontname, $legend);
    $self->push($label);
    $y++;
  }

  ($x, $y) = (2, 0);
  foreach my $node (@nodes) {
    ($legend, $colour) = @$node;
    $self->push(new Sanger::Graphics::Glyph::Rect({
        'x'         => $im_width * $x/$NO_OF_COLUMNS,
        'y'         => $y * ( $th + 3 ) + 5 + $th,
        'width'     => 5,
        'height'    => 5,
        'colour'   => $colour,
        })
      );
    $label = _create_label($im_width, $x, $y, $NO_OF_COLUMNS, $BOX_WIDTH, $th, $fontsize, $fontname, $legend);
    $self->push($label);
    $y++;
  }

  ($x, $y) = (3, 0);
  foreach my $box (@boxes) {
    ($legend, $colour, $border) = @$box;
    $self->push(new Sanger::Graphics::Glyph::Rect({
        'x'         => $im_width * $x/$NO_OF_COLUMNS,
        'y'         => $y * ( $th + 3 ) + 5 + $th,
        'width'     => 10,
        'height'    => 0,
        'colour'    => $border,
        })
      );
    $self->push(new Sanger::Graphics::Glyph::Rect({
        'x'         => $im_width * $x/$NO_OF_COLUMNS,
        'y'         => $y * ( $th + 3 ) + 6 + $th,
        'width'     => 10,
        'height'    => 8,
        'colour'    => $colour,
        })
      );
    $self->push(new Sanger::Graphics::Glyph::Rect({
        'x'         => $im_width * $x/$NO_OF_COLUMNS,
        'y'         => $y * ( $th + 3 ) + 14 + $th,
        'width'     => 10,
        'height'    => 0,
        'colour'    => $border,
        })
      );
    $label = _create_label($im_width, $x, $y, $NO_OF_COLUMNS, $BOX_WIDTH, $th, $fontsize, $fontname, $legend);
    $self->push($label);
    $y++;
  }

}

sub _create_label {
  my ($im_width, $x, $y, $NO_OF_COLUMNS, $BOX_WIDTH, $th, $fontsize, $fontname, $legend) = @_;
  return new Sanger::Graphics::Glyph::Text({
      'x'         => $im_width * $x/$NO_OF_COLUMNS + $BOX_WIDTH + 5,
      'y'         => $y * ( $th + 3 ) + $th,
      'height'    => $th,
      'valign'    => 'bottom',
      'halign'    => 'left',
      'ptsize'    => $fontsize,
      'font'      => $fontname,
      'colour'    => 'black',
      'text'      => " $legend",
      'absolutey' => 1,
      'absolutex' => 1,
      'absolutewidth'=>1
    });
}

1;
      
