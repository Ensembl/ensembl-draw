package Bio::EnsEMBL::GlyphSet::base_composition;
use strict;
use base qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "Base Composition"};


sub features {
  my $self = shift;
  my @bases = @{$self->{'container'}->get_all_ExternalLiteFeatures('GlovarBaseComp')};
 # warn map { "(@{[$_->start]},@{[$_->end]})" } @bases;
  return \@bases;
}


sub zmenu {
    my ($self, $f ) = @_;
    my $chr_start = $f->start() + $self->{'container'}->chr_start() - 1;
    my $a_count = $f->alleles->{'A'};
    my $c_count = $f->alleles->{'C'};
    my $g_count = $f->alleles->{'G'};
    my $t_count = $f->alleles->{'T'};

    my %zmenu = (
            'caption'              => "base comp",
	    "01:bp: $chr_start"    => '',
	    "02:A count: $a_count" => '',
	    "03:C count: $c_count" => '',
	    "04:G count: $g_count" => '',
            "05:T count: $t_count" => '',
   );
    return \%zmenu;
}

sub _init {
    my ($self) = @_;
    my $type = $self->check();
    return unless defined $type;
    
    my $VirtualContig   = $self->{'container'};
    my $Config          = $self->{'config'};
    my $strand          = $self->strand();
    my $strand_flag     = $Config->get($type, 'str');
    my $BUMP_WIDTH      = $Config->get($type, 'bump_width');
       $BUMP_WIDTH      = 1 unless defined $BUMP_WIDTH;

## If only displaying on one strand skip IF not on right strand....
    return if( $strand_flag eq 'r' && $strand != -1 ||
               $strand_flag eq 'f' && $strand != 1 );

# Get information about the VC - length, and whether or not to
# display track/navigation
    my $vc_length      = $VirtualContig->length( );
    my $max_length     = $Config->get( $type, 'threshold' ) || 200000000;
    my $navigation     = $Config->get( $type, 'navigation' ) || 'on';
    my $max_length_nav = $Config->get( $type, 'navigation_threshold' ) || 15000000;

## VC too long to display featues dump an error message
    if( $vc_length > $max_length *1010 ) {
        $self->errorTrack( $self->my_label." only displayed for less than $max_length Kb.");
        return;
    }

## Decide whether we are going to include navigation (independent of switch) 
    $navigation = ($navigation eq 'on') && ($vc_length <= $max_length_nav *1010);
    
## Get highlights...
    my %highlights;
    @highlights{$self->highlights()} = ();
## Set up bumping bitmap
    my @bitmap         = undef;
## Get information about bp/pixels
    my $pix_per_bp     = $Config->transform()->{'scalex'};
    my $bitmap_length  = int($VirtualContig->length * $pix_per_bp);

    my $colours = $Config->get($type, 'colours') || [qw(background2 blue rust)];
    my $coloursteps = 20;
    my @gradient = $self->{'config'}->colourmap->build_linear_gradient($coloursteps, @{$colours});

    my $h    = $Config->get($type,'height') || 36;


    my $flag           = 1;


    my $features = $self->features();
    unless(ref($features)eq'ARRAY') {
        # warn( ref($self), ' features not array ref ',ref($features) );
    return;
    }

    foreach my $f ( @{$features} ) {
		#print STDERR "Added feature ", $f->id(), " for drawing.\n";
## Check strand for display ##
        next if( $strand_flag eq 'b' && $strand != $f->strand );
## Check start are not outside VC.... ##
        my $start = $f->start();
        next if $start>$vc_length; ## Skip if totally outside VC
        $start = 1 if $start < 1;
## Check end are not outside VC.... ##
        my $end   = $f->end();
        next if $end<1;            ## Skip if totally outside VC
        $end   = $vc_length if $end>$vc_length;
	my $t_strength = $f->alleles->{'T'};
	my $a_strength = $f->alleles->{'A'};
	my $g_strength = $f->alleles->{'G'};
	my $c_strength = $f->alleles->{'C'};

        my $img_start = $start;
        my $img_end   = $end;

        my $composite = new Sanger::Graphics::Glyph::Composite();

            $composite->push( new Sanger::Graphics::Glyph::Rect({
                'x'          => $start-1,
                'y'          => 0,
                'width'      => $end - $start + 1,
                'height'     => $h/4,
                "colour"     => $gradient[$t_strength],
                'absolutey'  => 1
            }) );

            $composite->push( new Sanger::Graphics::Glyph::Rect({
                'x'          => $start-1,
                'y'          => $h/4,
                'width'      => $end - $start + 1,
                'height'     => $h/4,
                "colour"     => $gradient[$a_strength],
                'absolutey'  => 1
            }) );

            $composite->push( new Sanger::Graphics::Glyph::Rect({
                'x'          => $start-1,
                'y'          => $h/2,
                'width'      => $end - $start + 1,
                'height'     => $h/4,
                "colour"     => $gradient[$c_strength],
                'absolutey'  => 1
            }) );

            $composite->push( new Sanger::Graphics::Glyph::Rect({
                'x'          => $start-1,
                'y'          => $h*0.75,
                'width'      => $end - $start + 1,
                'height'     => $h/4,
                "colour"     => $gradient[$g_strength],
                'absolutey'  => 1
            }) );

        my $rowheight = int($h * 1.5);

## Lets see if we can Show navigation ?...
        if($navigation) {
            $composite->{'zmenu'} = $self->zmenu( $f ) if $self->can('zmenu');
            $composite->{'href'}  = $self->href(  $f ) if $self->can('href');
        }

        $self->push($composite);


    }


    my $key = new Sanger::Graphics::Glyph::Composite();

    $key->push(new Sanger::Graphics::Glyph::Text({
	    'x'         => -6 / $pix_per_bp,
	    'y'         => 0,
            #'absolutey' => 1,
            #'absolutex' => 1,
            'font'      => 'Tiny',
            'colour'    => 'black',
            'height'    => $h/4,
            'width'     => 4,
            'text'      => 'T',
            }));

    $key->push(new Sanger::Graphics::Glyph::Text({
	    'x'         =>  -6 / $pix_per_bp,
	    'y'         => $h/4,
            #'absolutey' => 1,
            #'absolutex' => 1,
            'font'      => 'Tiny',
            'colour'    => 'black',
            'height'    => $h/4,
            'width'     => 4,
            'text'      => 'A',
            }));

    $key->push(new Sanger::Graphics::Glyph::Text({
	    'x'         =>  -6 / $pix_per_bp,
	    'y'         => $h/2,
            #'absolutey' => 1,
            #'absolutex' => 1,
            'font'      => 'Tiny',
            'colour'    => 'black',
            'height'    => $h/4,
            'width'     => 4,
            'text'      => 'C',
            }));

    $key->push(new Sanger::Graphics::Glyph::Text({
	    'x'         =>  -6 / $pix_per_bp,
	    'y'         => $h*0.75,
            #'absolutey' => 1,
            #'absolutex' => 1,
            'font'      => 'Tiny',
            'colour'    => 'black',
            'height'    => $h/4,
            'width'     => 4,
            'text'      => 'G',
            }));

    $self->push($key);

## No features show "empty track line" if option set....  ##
    $self->errorTrack( "No ".$self->my_label." in this region" )
        if( $Config->get('_settings','opt_empty_tracks')==1 && $flag );
}

1;

