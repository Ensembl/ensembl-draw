package Bio::EnsEMBL::GlyphSet::Pprotdas;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Composite;
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Space;
use Sanger::Graphics::ColourMap;
use Sanger::Graphics::Bump;
use Data::Dumper;
use ExtURL;


sub init_label {
  my ($self) = @_;
  return if( defined $self->{'config'}->{'_no_label'} );

  my $numchars = 16;
  my $indent   = 1;
  my $Config   = $self->{'config'};
  my $confkey  = $self->{'extras'}->{'confkey'};
  my $text     = $self->{'extras'}->{'name'};
  my $colour   = $Config->get($confkey,'col') || 'black';

  my $print_label = ( length($text) > ( $numchars - $indent ) ? 
		      substr( $text, 0, ( $numchars - $indent - 2 ) )."..": 
		      $text );
  $print_label =  ' ' x $indent . $print_label;
  my $label = new Sanger::Graphics::Glyph::Text
    ( { 'text'      => $print_label,
	'font'      => 'Small',
	'absolutey' => 1,
	'colour'    => $colour,
	'zmenu'     => {caption=>$text}
      });

    $self->label($label);

    return 1;
}



sub _init {

    my ($self) = @_;
    my %hash;
    my $caption       = $self->managed_name || "GeneDAS";
    my @bitmap        = undef;
    my $Config        = $self->{'config'};  
    my $prot_len      = $self->{'container'}->length;
    my $pix_per_bp    = $Config->transform->{'scalex'};
    my $bitmap_length = int( $prot_len * $pix_per_bp);
    my $y             = 0;
    my $h             = 4;
    my $cmap          = new Sanger::Graphics::ColourMap;
    my $black         = 'black';
    my $red           = 'red';
    my $font          = "Small";
    my $das_confkey   = $self->{'extras'}->{'confkey'};

    my $colour        = $Config->get($das_confkey,'col') || 'black';
    my ($fontwidth,
	$fontheight)  = $Config->texthelper->px2bp($font);

    my $das_feat_ref = $self->{extras}->{features};
    ref( $das_feat_ref ) eq 'ARRAY' || ( warn("No feature array for ProteinDAS track") &&  return );

    foreach my $feat (@$das_feat_ref) {
      push(@{$hash{$feat->das_feature_id}},$feat) if defined $feat->start;
    }
    foreach my $key (keys %hash) {
	my @row  = @{$hash{$key}};
	my $desc = $row[0]->das_feature_label();
		
	# Zmenu
	my $zmenu = { 'caption' => $row[0]->das_type(),
		      "01:".$key      => $row[0]->das_link() || undef };
	if( my $m = $row[0]->das_method ){ $zmenu->{"02:Method: $m"} = undef }
	if( my $n = $row[0]->das_note   ){ $zmenu->{"03:Note: $n"  } = undef }
		      

	my $Composite = new Sanger::Graphics::Glyph::Composite
	  ({
	    'x'     => $row[0]->start(),
	    'y'     => $y,
	    'href'  => $row[0]->das_link(),
	    'zmenu' => $zmenu,
	   });

	# Boxes
	my $pfsave;
	my ($minx, $maxx);
	foreach my $pf (@row) {
	    my $x  = $pf->start();
	    $minx  = $x if ($x < $minx || !defined($minx));
	    my $w  = $pf->end() - $x;
	    $maxx  = $pf->end() if ($pf->das_end() > $maxx || !defined($maxx));
	    my $id = $pf->das_feature_id();

	    my $rect = new Sanger::Graphics::Glyph::Rect({
		'x'        => $x,
		'y'        => $y,
		'width'    => $w,
		'height'   => $h,
		'colour'   => $colour,
	    });
	    $Composite->push($rect);
	    $pfsave = $pf;
	}

	my $rect = new Sanger::Graphics::Glyph::Rect({
	    'x'         => $minx,
	    'y'         => $y + 2,
	    'width'     => $maxx - $minx,
	    'height'    => 0,
	    'colour'    => $colour,
	    'absolutey' => 1,
	});
	$Composite->push($rect);

	# Label - disabled for now
	if( 0 ){
	    my $desc = $pfsave->das_feature_label() || $key;
	    my $text = new Sanger::Graphics::Glyph::Text
	      ({
		'font'   => $font,
		'text'   => $desc,
		'x'      => $row[0]->start(),
		'y'      => $h + 1,
		'height' => $fontheight,
		'width'  => $fontwidth * length($desc),
		'colour' => $black,
	       });
	    #$Composite->push($text);
	}

	#if ($Config->get('Pprotdas', 'dep') > 0){ # we bump
            my $bump_start = int($Composite->x() * $pix_per_bp);
            $bump_start = 0 if ($bump_start < 0);
	    
            my $bump_end = $bump_start + int($Composite->width()*$pix_per_bp);
            if ($bump_end > $bitmap_length){$bump_end = $bitmap_length};
            my $row = & Sanger::Graphics::Bump::bump_row(
				      $bump_start,
				      $bump_end,
				      $bitmap_length,
				      \@bitmap
				      );
            $Composite->y($Composite->y() + $row * ($h + 2) );
        #}
	
	$self->push($Composite);
    }
    if( ! scalar %hash ){ # Add a spacer glyph to force an empty track
      my $spacer = new Sanger::Graphics::Glyph::Space
	({
	  'x'         => 0,
	  'y'         => 0,
	  'width'     => 0,
	  'height'    => $h,
	  'absolutey' => 1,
	 });
      $self->push($spacer); 
    }

}


#----------------------------------------------------------------------
# Returns the order corresponding to this glyphset
sub managed_name{
  my $self = shift;
  return $self->{'extras'}->{'order'} || 0;
}


1;

