package Sanger::Graphics::Glyph;
use strict;
use Sanger::Graphics::ColourMap;
use vars qw($AUTOLOAD);

#########
# constructor
# _methods is a hash of valid methods you can call on this object
#
sub new {
  my ($class, $params_ref) = @_;
  my $self = {
	      'background' => 'transparent',
	      'composite'  => undef,          # arrayref for Glyph::Composite to store other glyphs in
	      'points'     => [],		        # listref for Glyph::Poly to store x,y paired points
	      ref($params_ref) eq 'HASH' ? %$params_ref : ()
	     };
  bless($self, $class);
  return $self;
}

#########
# read-write methods
#
sub AUTOLOAD {
  my ($self, $val) = @_;
  no strict 'refs';
  (my $field      = $AUTOLOAD) =~ s/.*:://;
  *{$AUTOLOAD}    = sub { $_[0]->{$field}=$_[1] if defined $_[1]; return $_[0]->{$field}; };
  $self->{$field} = $val if(defined $val);
  return $self->{$field};
}

#########
# apply a transformation.
# pass in a hashref containing keys
#  - translatex
#  - translatey
#  - scalex
#  - scaley
#
sub transform {
  my ($self, $transform_ref) = @_;

  my $scalex     = $transform_ref->{'scalex'} || 1;
  my $scaley     = $transform_ref->{'scaley'} || 1;
  my $scalewidth = $scalex;
  my $translatex = $transform_ref->{'translatex'};
  my $translatey = $transform_ref->{'translatey'};

  #########
  # override transformation if we've set x/y to be absolute (pixel) coords
  #
  $scalex     = $transform_ref->{'absolutescalex'} if(defined $self->{'absolutex'});
  $scalewidth = $transform_ref->{'absolutescalex'} if(defined $self->{'absolutewidth'});
  $scaley     = $transform_ref->{'absolutescaley'} if(defined $self->{'absolutey'});
  
  #########
  # copy the real coords & sizes if we don't have them already
  #
  $self->{'pixelx'}      ||= ($self->{'x'}      || 0);
  $self->{'pixely'}      ||= ($self->{'y'}      || 0);
  $self->{'pixelwidth'}  ||= ($self->{'width'}  || 0);
  $self->{'pixelheight'} ||= ($self->{'height'} || 0);
  
  #########
  # apply scale
  #
  if(defined $scalex) {
    $self->{'pixelx'}      = $self->{'pixelx'} * $scalex;
  }
  if(defined $scalewidth) {
    $self->{'pixelwidth'}  = $self->{'pixelwidth'}  * $scalewidth;
  }
  if(defined $scaley) {
    $self->{'pixely'}      = $self->{'pixely'}      * $scaley;
    $self->{'pixelheight'} = $self->{'pixelheight'} * $scaley;
  }
  
  #########
  # apply translation
  #
  $self->pixelx($self->pixelx() + $translatex) if(defined $translatex);
  $self->pixely($self->pixely() + $translatey) if(defined $translatey);
}

sub centre {
  my ($self, $arg) = @_;
  
  my ($x, $y);
  $arg ||= "";

  if($arg eq "px") {
    #########
    # return calculated px coords
    # pixel coordinates are only available after a transformation has been applied
    #
    $x = $self->{'pixelx'} + $self->{'pixelwidth'} / 2;
    $y = $self->{'pixely'} + $self->{'pixelheight'} / 2;

  } else {
    #########
    # return calculated bp coords
    #
    $x = $self->{'x'} + $self->{'width'} / 2;
    $y = $self->{'y'} + $self->height() / 2;
  }
  
  return ($x, $y);
}

sub pixelcentre {
  my ($self) = @_;
  return ($self->centre("px"));
}

sub end {
  my ($self) = @_;
  return $self->{'x'} + $self->{'width'};
}

1;
