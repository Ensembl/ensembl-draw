package Bio::EnsEMBL::GlyphSet::prints;
use strict;
use vars qw(@ISA);
use lib "..";
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Composite;
use Bump;

sub init_label {
    my ($this) = @_;

    my $label = new Bio::EnsEMBL::Glyph::Text({
	'text'      => 'Prints',
	'font'      => 'Small',
	'absolutey' => 1,
    });
    $this->label($label);
}

sub _init {
    my ($this) = @_;
    my %hash = undef;
    my $protein = $this->{'container'};

    my @bitmap         	= undef;
    my $Config = $this->{'config'};
    my $pix_per_bp  	= $Config->transform->{'scalex'};
    my $bitmap_length 	= int($this->{'container'}->length * $pix_per_bp);

    my $y          = 0;
    my $h          = 4;
    
    foreach my $feat ($protein->each_Protein_feature()) {
	if ($feat->feature2->seqname =~ /^PR\w+/) {
	    push(@{$hash{$feat->feature2->seqname}},$feat);
	}
    }
    
    my $colour = $Config->get($Config->script(), 'prints','col');
		
    my $caption = "Prints";
    foreach my $key (keys %hash) {
	my @row = @{$hash{$key}};
	my $desc = $row[0]->idesc();
		
	my $Composite = new Bio::EnsEMBL::Glyph::Composite({
	    'x'     => $row[0]->feature1->start(),
	    'y'     => $y,
	    'zmenu' => {
		'caption'  	=> "Prints Domain",
		$key 		=> "http://methionine.sbc.man.ac.uk/cgi-bin/dbbrowser/sprint/searchprintss.cgi?prints_accn=$key&display_opts=Prints",
	    },
	});

	my $prsave;
	my ($minx, $maxx);
		
	my $font = "Small";
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
	my $fontheight = $Config->texthelper->height($font);
	my $fontwidth  = $Config->texthelper->width($font);
	my $desc       = $prsave->idesc();

	my $text = new Bio::EnsEMBL::Glyph::Text({
	    'font'   => $font,
	    'text'   => $desc,
	    'x'      => $row[0]->feature1->start(),
	    'y'      => $h + 1,
	    'height' => $fontheight,
	    'width'  => $fontwidth * length($desc) * 1.1,
	    'colour' => $colour,
	});
	
	$Composite->push($text);
	
	if ($Config->get($Config->script(), 'prints', 'dep') > 0){ # we bump
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
	
	$this->push($Composite);
    }
}

1;
