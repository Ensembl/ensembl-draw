package Bio::EnsEMBL::GlyphSet;
use strict;
use Bio::Root::RootI;
use Exporter;
use Bio::EnsEMBL::Glyph::Text;

use vars qw(@ISA $AUTOLOAD);
@ISA = qw(Exporter Bio::Root::RootI);
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);

#########
# constructor
#
sub new {
    my ($class, $VirtualContig, $Config, $highlights, $strand, $extra_config) = @_;
    my $self = {
	'glyphs'     => [],
	'x'          => undef,
	'y'          => undef,
	'width'      => undef,
	'highlights' => $highlights,
	'strand'     => $strand,
	'minx'       => undef,
	'miny'       => undef,
	'maxx'       => undef,
	'maxy'       => undef,
	'label'      => undef,
	'label2'     => undef,	
	'container'  => $VirtualContig,
	'config'     => $Config,
	'extras'     => $extra_config,
    };

    bless($self, $class);
    $self->init_label() if($self->can('init_label'));

#    &eprof_start(qq(glyphset_$class));
#    $self->_init($VirtualContig, $Config);
#    &eprof_end(qq(glyphset_$class));

    return $self;
}

#########
# _init creates masses of Glyphs from a data source.
# It should executes bumping and globbing on the fly and also
# keep track of x,y,width,height as it goes.
#
sub _init {
    my ($self) = @_;
    print STDERR qq($self unimplemented\n);
}

# Gets the number of Base Pairs per pixel
sub basepairs_per_pixel {
    my ($self) = @_;
    my $Config = $self->{'config'};
    my $pixels = $Config->get( '_settings' ,'width' );
    return (defined $pixels && $pixels) ? $self->{'container'}->length() / $pixels : undef; 
}    

sub glob_bp {
    my ($self) = @_;
    return int($self->basepairs_per_pixel()*2);
}
#########
# return our list of glyphs
#
sub glyphs {
    my ($self) = @_;
    return @{$self->{'glyphs'}};
}

#########
# push either a Glyph or a GlyphSet on to our list
#
sub push {
    my ($self, $Glyph) = @_;
    my ($gx, $gw, $gy, $gh);

	#########
	# if we've got a single glyph:
	#
	push @{$self->{'glyphs'}}, $Glyph;

	$gx = $Glyph->x();
	$gw = $Glyph->width();
	$gy = $Glyph->y();
	$gh = $Glyph->height();

    $self->minx($gx) if(!defined $self->minx());
    $self->maxx($gx) if(!defined $self->maxx());
    $self->miny($gy) if(!defined $self->miny());
    $self->maxy($gy) if(!defined $self->maxy());

    #########
    # track max and min dimensions
    #
    # x
    #
    if($gx < $self->minx()) {
		$self->minx($gx);
    };
	if(($gx + $gw) > $self->maxx()) {
		$self->maxx($gx + $gw);
    }

    # y
    # 
    if($gy < $self->miny()) {
		$self->miny($gy);
    };
	if(($gy + $gh) > $self->maxy()) {
		$self->maxy($gy + $gh);
    }
}

#########
# unshift a Glyph or GlyphSet onto our list
#
sub unshift {
    my ($self, $Glyph) = @_;

    my ($gx, $gw, $gy, $gh);

    if($Glyph->isa('Bio::EnsEMBL::Glyph')) {
	#########
	# if we've got a single glyph:
	#
	unshift @{$self->{'glyphs'}}, $Glyph;

	$gx = $Glyph->x();
	$gw = $Glyph->width();
	$gy = $Glyph->y();
	$gh = $Glyph->height();

    }

    $self->minx($gx) if(!defined $self->minx());
    $self->maxx($gx) if(!defined $self->maxx());
    $self->miny($gy) if(!defined $self->miny());
    $self->maxy($gy) if(!defined $self->maxy());

    #########
    # track max and min dimensions
    #
    # x
    #
    if($gx < $self->minx()) {
		$self->minx($gx);
    } 
	if(($gx + $gw) > $self->maxx()) {
		$self->maxx($gx + $gw);
    }

    # y
    # 

    if($gy < $self->miny()) {
		$self->miny($gx);
    }
	if(($gy + $gh) > $self->maxy()) {
		$self->maxy($gy + $gh);
    }
}

#########
# pop a Glyph off our list
# needs to shrink glyphset dimensions if the glyph/glyphset we pop off 
#
sub pop {
    my ($self) = @_;
    return pop @{$self->{'glyphs'}};
}

#########
# shift a Glyph off our list
#
sub shift {
    my ($self) = @_;
    return shift @{$self->{'glyphs'}};
}

#########
# return the length of our list
#
sub length {
    my ($self) = @_;
    return scalar @{$self->{'glyphs'}};
}

#########
# read-only start x position (should usually be 0)
# 
sub x {
    my ($self) = @_;
    return $self->{'x'};
}

#########
# read-only start y position (should usually be 0)
#
sub y {
    my ($self) = @_;
    return $self->{'y'};
}

#########
# read-only highlights (list)
#
sub highlights {
    my ($self) = @_;
    return defined $self->{'highlights'} ? @{$self->{'highlights'}} : ();
}

sub minx {
    my ($self, $minx) = @_;
    $self->{'minx'} = $minx if(defined $minx);
    return $self->{'minx'};
}

sub miny {
    my ($self, $miny) = @_;
    $self->{'miny'} = $miny if(defined $miny);
    return $self->{'miny'};
}

sub maxx {
    my ($self, $maxx) = @_;
    $self->{'maxx'} = $maxx if(defined $maxx);
    return $self->{'maxx'};
}

sub maxy {
    my ($self, $maxy) = @_;
    $self->{'maxy'} = $maxy if(defined $maxy);
    return $self->{'maxy'};
};

sub strand {
    my ($self, $strand) = @_;
    $self->{'strand'} = $strand if(defined $strand);
    return $self->{'strand'};
}

sub height {
    my ($self) = @_;
    my $h = $self->{'maxy'} - $self->{'miny'};
    $h *=-1 if($h < 0);
    return $h;
}

sub width {
    my ($self) = @_;
    my $w = $self->{'maxx'} - $self->{'minx'};
    $w *=-1 if($w < 0);
    return $w;
}

sub label {
    my ($self, $val) = @_;
    $self->{'label'} = $val if(defined $val);
    return $self->{'label'};
}

sub label2 {
    my ($self, $val) = @_;
    $self->{'label2'} = $val if(defined $val);
    return $self->{'label2'};
}

sub transform {
    my ($self) = @_;
    for my $glyph (@{$self->{'glyphs'}}) {
	$glyph->transform($self->{'config'}->{'transform'});
    }
}

###
### gene_specific functions 
###
sub virtualGene_details {
    my ($self, $vg, %highlights) = @_;

    my $highlight = 0;
    my $genetype  = 'unknown';
    my $label     = "NOVEL";
    if ($vg->gene->is_known) {
        $genetype = 'known';
        my @temp_geneDBlinks = $vg->gene->each_DBLink();
    # find a decent label:
        $label = $vg->id();
        $highlight = 1 if exists $highlights{$label}; # check for highlighting
        ( $label, $highlight ) = $self->_label_highlight( $label, $highlight, \%highlights, \@temp_geneDBlinks );
        
    }
    return ( $genetype, $label, $highlight, $vg->start(), $vg->end() );
}

sub _label_highlight {
    my ($self,$label,$highlight,$highlights,$dblinks) = @_;
    my $max_pref = 0;
    my %db_names = ( # preference for naming scheme based on numerical precidence!
		    'FlyBase' => 110,
        'HUGO'          => 100, 'SP'            =>  90,
        'SWISS-PROT'    =>  80, 'SPTREMBL'      =>  70,
        'SCOP'          =>  60, 'LocusLink'     =>  50,
        'RefSeq'        =>  40 
    );

    foreach ( @$dblinks ) {
        my $db = $_->database();
        # reset if precedence is higher!
        #print STDERR "_l_h:\t".ref($self)."\t$db\t$db_names{$db}\t".$_->display_id()."\t|\n";
        if( $db_names{$db} ) {
            $highlight = 1 if exists $highlights->{$_->display_id()}; # check for highlighting
            # if this is a more prefered label then we will use it!
            if( $db_names{$db}>$max_pref) {
	      next if $_->display_id() =~ /^CG/ && $db eq "Gene_name";
              $label = $_->display_id();
	      $max_pref = $db_names{$db};
            }
        }
    }
    return($label, $highlight);
}

sub errorTrack {
	my ($self, $message) = @_;
	my $length = $self->{'container'}->length() +1;
    my ($w,$h) = $self->{'config'}->texthelper()->real_px2bp('Tiny');
    my $red    = $self->{'config'}->colourmap()->id_by_name('red');
	my $bp_textwidth = $w * length($message);
	my $tglyph = new Bio::EnsEMBL::Glyph::Text({
    	'x'         => int(($length - $bp_textwidth)/2),
        'y'         => 0,
    	'height' 	=> 8,
        'font'      => 'Tiny',
        'colour'    => $red,
        'text'      => $message,
        'absolutey' => 1,
	});
	$self->push($tglyph);
	return;
}

sub externalGene_details {
    my ($self, $vg, $vc_id, %highlights) = @_;

    my $highlight = 0;
    my $label     = "NOVEL";
    my $start;
    my $end;
    
    my $genetype   = ($vg->type() =~ /pseudo/) ? 'pseudo' : 'ext';

    foreach my $trans ($vg->each_Transcript){
        foreach my $exon ( $trans->get_all_Exons ) {
            if($exon->seqname eq $vc_id) {
                $start = $exon->start if ( $exon->start < $start || !defined $start );
                $end   = $exon->end   if ( $exon->end   > $end   || !defined $end );
	    }
    	}
    }
    $label  = $vg->stable_id;
    $highlight = 1 if exists $highlights{$label};
    $label  =~ s/gene\.//;
    $highlight = 1 if exists $highlights{$label};
    my @temp_geneDBlinks = $vg->each_DBLink();
    ( $label, $highlight ) = $self->_label_highlight( $label, $highlight, \%highlights, \@temp_geneDBlinks );
    return ( $genetype, $label, $highlight, $start, $end );
}
1;
