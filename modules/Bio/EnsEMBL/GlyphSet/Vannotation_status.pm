package Bio::EnsEMBL::GlyphSet::Vannotation_status;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);

sub _init {
    my $self = shift;

    ## get NoAnnotation features from db
    my $chr = $self->{'container'}->{'chr'};
    my $slice_adapt   = $self->{'container'}->{'sa'};  
    my $chr_slice = $slice_adapt->fetch_by_region('chromosome', $chr);
	my $bp_per_pixel = ($chr_slice->length)/450;

    my @features;
    push @features,
        @{ $chr_slice->get_all_MiscFeatures('NoAnnotation') },
        @{ $chr_slice->get_all_MiscFeatures('CORFAnnotation') };


    ## get configuration
    my $tag_pos = $self->{'config'}->get($self->check, 'tag_pos');
    my %colour = (
        'NoAnnotation'      => 'gray75',
#        'CORFAnnotation'    => 'gray90',
        'CORFAnnotation'    => 'white',
    );

    ## draw the glyphs
    foreach my $f (@features) {
        my ($ms) = @{ $f->get_all_MiscSets('NoAnnotation') };
        ($ms) = @{ $f->get_all_MiscSets('CORFAnnotation') } unless $ms;


        #set length of feature to the equivalent of 1 pixel if it's less than 1 pixel
	    	my $f_length = $f->end - $f->start;
		    my $width = ($f_length > $bp_per_pixel) ? $f_length : $bp_per_pixel;

        my $glyph = new Sanger::Graphics::Glyph::Rect({
            'x'      => $f->start,
            'y'      => 0,
            'width'  => $width,
            'height' => 1,
            'colour' => $colour{$ms->code},
        });
        $self->push($glyph);

        ## tagging
        $self->join_tag($glyph, $f->end."-".$f->start, $tag_pos, $tag_pos, $colour{$ms->code}, 'fill', -10);
        $self->join_tag($glyph, $f->end."-".$f->start, 1-$tag_pos, $tag_pos, $colour{$ms->code}, 'fill', -10);
    }
}

1;
