package Bio::EnsEMBL::GlyphSet::swall_high_sens;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "Swall high sens."; }

sub features {
    my ($self) = @_;

    return $self->{'container'}->get_all_ProteinAlignFeatures('swall_high_sens',80);
}

sub href {
    my ( $self, $id ) = @_;
    return $self->ID_URL( 'SRS_PROTEIN', $id );
}

sub zmenu {
    my ($self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return { 'caption' => "$id", "Protein homology" => $self->href( $id ) };
}
1;
