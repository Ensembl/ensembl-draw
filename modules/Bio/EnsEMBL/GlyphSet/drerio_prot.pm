package Bio::EnsEMBL::GlyphSet::drerio_prot;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "D.rerio Proteins"; }

sub features {
    my ($self) = @_;

    return $self->{'container'}->get_all_ProteinAlignFeatures('drerio_prot',80);
}

sub href {
    my ( $self, $id ) = @_;
    return $self->{'config'}->{'ext_url'}->get_url( 'EMBL', $id );
}

sub zmenu {
    my ($self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return { 'caption' => "$id", "Protein homology" => $self->href( $id ) };
}
1;
