package Bio::EnsEMBL::GlyphSet::vertrna;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "mRNAs"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_SimilarityFeatures_above_score("embl_vertrna",80,$self->glob_bp);
}

sub href {
    my ($self, $id ) = @_;
    return $self->{'config'}->{'ext_url'}->get_url('EMBL',$id);
}
sub zmenu {
    my ($self, $id ) = @_;
    return { 'caption' => "$id", "EMBL: $id" => $self->href( $id ) };
}
1;
