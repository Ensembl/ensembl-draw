package Bio::EnsEMBL::GlyphSet::other_fish_ests;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "Other fish ESTs"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_DnaAlignFeatures("BLAST_OTHER_FISH_ESTS",1);
}

sub href {
    my ( $self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return $self->{'config'}->{'ext_url'}->get_url( 'OTHER_FISH_ESTS', $id );
}

sub zmenu {
    my ($self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return { 'caption' => "$id", "$id" => $self->href( $id ) };
}

1;
