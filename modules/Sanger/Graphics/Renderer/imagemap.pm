#########
# Author: rmp@sanger.ac.uk
# Maintainer: webmaster@sanger.ac.uk
# Created: 2001
#
package Sanger::Graphics::Renderer::imagemap;
use strict;
use Sanger::Graphics::Renderer;
use vars qw(@ISA);
@ISA = qw(Sanger::Graphics::Renderer);

#########
# imagemaps are basically strings, so initialise the canvas with ""
# imagemaps also aren't too fussed about width & height boundaries
#
sub init_canvas {
    my ($self, $config, $im_width, $im_height) = @_;
    $self->canvas("");
    $self->{'show_zmenus'} = defined( $config->get("_settings","opt_zmenus") ) ? $config->get("_settings","opt_zmenus") : 1;
    $self->{'zmenu_zclick'} = $config->get("_settings","opt_zclick");
    $self->{'zmenu_behaviour'} = $config->get("_settings","zmenu_behaviour") || 'onmouseover';
}

sub add_canvas_frame {
    return;
}

sub render_Rect {
    my ($self, $glyph) = @_;
    my $href = $self->_getHref($glyph);
    return unless(defined $href && $href);

    my $x1 = int( $glyph->{'pixelx'} );
    my $x2 = int( $glyph->{'pixelx'} + $glyph->{'pixelwidth'} );
    my $y1 = int( $glyph->{'pixely'} );
    my $y2 = int( $glyph->{'pixely'} + $glyph->{'pixelheight'} );

    $x1 = 0 if($x1<0);
    $x2 = 0 if($x2<0);
    $y1 = 0 if($y1<0);
    $y2 = 0 if($y2<0);

    $y2 += 1;
    $x2 += 1;

    $self->{'canvas'} = qq(<area coords="$x1 $y1 $x2 $y2"$href>\n).$self->{'canvas'};
}

sub render_Text {
    my ($self, $glyph) = @_;
    $self->render_Rect($glyph);
}

sub render_Circle {
  my ($self, $glyph) = @_; 
  my $href = $self->_getHref($glyph); 
  return unless(defined $href && $href); 

  my ($cx, $cy) = $glyph->pixelcentre();
  my $cw = $glyph->{'pixelwidth'}/2;
  
  my $x1 = int($cx - $cw);
  my $x2 = int($cx + $cw);
  my $y1 = int($cy - $cw);
  my $y2 = int($cy + $cw);
  
  $x1 = 0 if($x1<0);
  $x2 = 0 if($x2<0);
  $y1 = 0 if($y1<0);
  $y2 = 0 if($y2<0);
  
  $y2 += 1;
  $x2 += 1;
  
  $self->{'canvas'} = qq(<area coords="$x1 $y1 $x2 $y2"$href>\n).$self->{'canvas'}; 
}

sub render_Ellipse {
}

sub render_Intron {
}

sub render_Poly {
    my ($self, $glyph) = @_;
    my $href = $self->_getHref( $glyph );
    return unless(defined $href && $href);

    my $pointslist = join ' ',map { int } @{$glyph->pixelpoints()};
    $self->{'canvas'} = qq(<area shape="poly" coords="$pointslist"$href>\n).$self->{'canvas'} ; 
}

sub render_Space {
    my ($self, $glyph) = @_;
    return $self->render_Rect($glyph);
}

sub render_Composite {
    my ($self, $glyph) = @_;
    $self->render_Rect($glyph);
}

sub render_Line {
}

sub _getHref {
  my( $self, $glyph ) = @_; 
  my %actions = ();
  my @X = qw( onmouseover onmouseout alt href );
  foreach(@X) {
    my $X = $glyph->$_;
    $actions{$_} = $X if defined $X;
  }   
  $actions{'title'} = $glyph->alt if defined $glyph->alt;
  if($self->{'show_zmenus'}==1) {
    my $zmenu = $glyph->zmenu();
    if(defined $zmenu && (ref($zmenu) eq '' || ref($zmenu) eq 'HASH' && keys(%$zmenu)>0) ) {
      if($self->{'zmenu_zclick'} || ($self->{'zmenu_behaviour'} =~ /onClick/i)) {
        #$actions{'ondoubleclick'} = $actions{'href'}        if exists $actions{'href'};
        $actions{'onclick'}       = &Sanger::Graphics::JSTools::js_menu($zmenu).";return false;";   
        delete $actions{'onmouseover'};
        delete $actions{'onmouseout'};   
        $actions{'alt'} = "Click for Menu";   
      } else {   
        delete $actions{'alt'};   
        $actions{'onmouseover'} = &Sanger::Graphics::JSTools::js_menu($zmenu);   
      }
      $actions{'href'} ||= qq"javascript:void(0)";   
    }
  }
  return join '', map { qq( $_="$actions{$_}") } keys %actions; 
}

1;
