package Bio::EnsEMBL::GlyphSet_feature2;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Composite;
use Bump;

@ISA = qw(Bio::EnsEMBL::GlyphSet);

sub init_label {
    my ($self) = @_;
    my ($type)         = reverse split '::', ref($self) ;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
        'text'      => $self->my_label(),
        'font'      => 'Small',
        'absolutey' => 1,
    });
    $self->bumped( $self->{'config'}->get($type, 'dep')==0 ? 'no' : 'yes' );
    $self->label($label);
}

sub my_label {
    my ($self) = @_;
    return 'Missing label';
}

sub features {
    my ($self) = @_;
    return ();
} 

sub zmenu {
    my ($self, $id ) = @_;

    return {
        'caption' => "Unknown",
        "$id"     => "You must write your own zmenu call"
    };
}

sub href {
    my ($self, $id ) = @_;

    return undef;
}

sub _init {
    my ($self) = @_;
    my $type = $self->check();
    return unless defined $type;

    my $VirtualContig  = $self->{'container'};
    my $Config         = $self->{'config'};
    my $strand         = $self->strand();
    my $strand_flag    = $Config->get($type, 'str');
    return if( $strand_flag eq 'r' && $strand != -1 ||
               $strand_flag eq 'f' && $strand != 1 );

    my $h              = 8;
    my %highlights;
    @highlights{$self->highlights()} = ();
    my $LEN = $VirtualContig->length;
    my @bitmap         = undef;
    my $pix_per_bp     = $Config->transform()->{'scalex'};
    my $bitmap_length  = int($LEN * $pix_per_bp);
    my $feature_colour = $Config->get($type, 'col');
    my $hi_colour      = $Config->get($type, 'hi');
    my %id             = ();
    my $small_contig   = 0;
    my $dep            = $Config->get($type, 'dep');

    foreach my $f ( $self->features ){
        next if( $strand_flag eq 'b' && $strand != $f->strand );
        next if( $f->start < $f->end && ($f->start < 1 || $f->end   > $LEN) );
        next if( $f->start > $f->end && ($f->end   < 1 || $f->start > $LEN) );
        $id{$f->id()} = [] unless $id{$f->id()};
        push @{$id{$f->id()}}, $f;
    }

## No features show "empty track line" if option set....
$self->errorTrack( "No ".$self->my_label." in this region" )
        unless( $Config->get('_settings','opt_empty_tracks')==0 || %id );

## Now go through each feature in turn, drawing them
    my @glyphs;
    foreach my $i (keys %id){
        print STDERR "XXX: $i\n\n";
        my $has_origin = undef;
    

        my $start   = 100000000;
        my $end   = 0;

        my $Composite = new Bio::EnsEMBL::Glyph::Composite({});
        
        foreach my $f (@{$id{$i}}){
            my $START = $f->start();
            my $END   = $f->end();
            ($START,$END) = ($END, $START) if $END<$START;
            unless (defined $has_origin){
                $Composite->x($f->start());
                $Composite->y(0);
                $has_origin = 1;
            }
	    $start = $f->hstart() if $f->hstart < $start;
	    $end   = $f->hend() if $f->hend >$end;
            print STDERR "F: ",$f->id," - ",$f->start()," - ",$f->end(),"\n";
            my $glyph = new Bio::EnsEMBL::Glyph::Rect({
                'x'          => $START,
                'y'          => 0,
                'width'      => $END-$START+1,
                'height'     => $h,
                'colour'     => $feature_colour,
                'absolutey'  => 1,
                '_feature'   => $f, 
            });
            $Composite->push($glyph);
        }
    
	$start =int(( $start + $end) /2);
        my $ZZ = "contig=$i&fpos_start=$start&fpos_end=$start&fpos_context=50000";
	$Composite->zmenu( $self->zmenu( $i, $ZZ ) );
	$Composite->href( $self->href( $i, $ZZ ) );
        if ($dep > 0){ # we bump
            my $bump_start = int($Composite->x() * $pix_per_bp);
            $bump_start    = 0 if $bump_start < 0;
            
            my $bump_end = $bump_start + ($Composite->width() * $pix_per_bp);
            $bump_end    = $bitmap_length if $bump_end > $bitmap_length;
            my $row = &Bump::bump_row(
                $bump_start,    $bump_end,    $bitmap_length,    \@bitmap
            );

            next if $row > $dep;
            $Composite->y( $Composite->y() - 1.5 * $row * $h * $strand );
        
            # if we are bumped && on a large contig then draw frames around features....
            $Composite->bordercolour($feature_colour) unless ($small_contig);
        }
        $self->push( $Composite );
        if(exists $highlights{$i}) {
            my $glyph = new Bio::EnsEMBL::Glyph::Rect({
                'x'         => $Composite->x() - 1/$pix_per_bp,
                'y'         => $Composite->y() - 1,
                'width'     => $Composite->width() + 2/$pix_per_bp,
                'height'    => $h + 2,
                'colour'    => $hi_colour,
                'absolutey' => 1,
            });
            $self->unshift( $glyph );
        }
    }
}

1;
