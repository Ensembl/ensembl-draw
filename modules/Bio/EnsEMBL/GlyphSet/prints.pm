package Bio::EnsEMBL::GlyphSet::prints;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Composite;
use ExtURL;

use Bump;

sub init_label {
    my ($self) = @_;
	return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
	'text'      => 'Prints',
	'font'      => 'Small',
	'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;
    my %hash;
    my $protein       = $self->{'container'};
    my @bitmap;
    my $Config        = $self->{'config'};
    my $pix_per_bp    = $Config->transform->{'scalex'};
    my $bitmap_length = int($protein->length * $pix_per_bp);
    my $y             = 0;
    my $h             = 4;
    my $colour        = $Config->get('prints','col');
    my $caption       = "Prints";
    my $font          = "Small";
    my ($fontwidth,
	$fontheight)  = $Config->texthelper->px2bp($font);

    my $ext_url = ExtURL->new;

    my @pr_feat = $protein->get_all_PrintsFeatures();
    foreach my $feat(@pr_feat) {
	push(@{$hash{$feat->feature2->seqname}},$feat);
    }
    
    foreach my $key (keys %hash) {
	my @row = @{$hash{$key}};
	my $desc = $row[0]->idesc();
		
	my $Composite = new Bio::EnsEMBL::Glyph::Composite({
	    'x'     => $row[0]->feature1->start(),
	    'y'     => $y,
	    'zmenu' => {
		'caption'  	=> "Prints Domain",
		$key 		=> $ext_url->get_url( 'PRINTS', $key  )
	    },
	});

	my $prsave;
	my ($minx, $maxx);
		
	foreach my $pr (@row) {
	    my $x  = $pr->feature1->start();
	    $minx  = $x if ($x < $minx || !defined($minx));
	    my $w  = $pr->feature1->end() - $x;
	    $maxx  = $pr->feature1->end() if ($pr->feature1->end() > $maxx || !defined($maxx));
	    my $id = $pr->feature2->seqname();
	    
	    my $rect = new Bio::EnsEMBL::Glyph::Rect({
		'x'        => $x,
		'y'        => $y,
		'width'    => $w,
		'height'   => $h,
		'colour'   => $colour,
	    });
	    $Composite->push($rect);
	    $prsave = $pr;
	}

	#########
	# add a domain linker
	#
	my $rect = new Bio::EnsEMBL::Glyph::Rect({
	    'x'        => $minx,
	    'y'        => $y + 2,
	    'width'    => $maxx - $minx,
	    'height'   => 0,
	    'colour'   => $colour,
	    'absolutey' => 1,
	});
	$Composite->push($rect);
	
	#########
	# add a label
	#
	my $desc = $prsave->idesc();
	my $text = new Bio::EnsEMBL::Glyph::Text({
	    'font'   => $font,
	    'text'   => $desc,
	    'x'      => $row[0]->feature1->start(),
	    'y'      => $h + 1,
	    'height' => $fontheight,
	    'width'  => $fontwidth * length($desc),
	    'colour' => $colour,
	});
	$Composite->push($text);

	if ($Config->get('prints', 'dep') > 0){ # we bump
            my $bump_start = int($Composite->x() * $pix_per_bp);
            $bump_start = 0 if ($bump_start < 0);
	    
            my $bump_end = $bump_start + int($Composite->width()*$pix_per_bp);
            if ($bump_end > $bitmap_length){$bump_end = $bitmap_length};
            my $row = &Bump::bump_row(
				      $bump_start,
				      $bump_end,
				      $bitmap_length,
				      \@bitmap
				      );
            $Composite->y($Composite->y() + (1.5 * $row * ($h + $fontheight)));
        }
	
	$self->push($Composite);
    }
}

1;
