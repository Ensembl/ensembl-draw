package Bio::EnsEMBL::GlyphSet::annot_sts;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "STS"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_SimilarityFeatures_by_analysis_id(67);
}

sub href {
    my ($self, $id ) = @_;
    $id=~s/^([^\.]+)\..*/$1/;
    return $self->{'config'}->{'ext_url'}->get_url('EMBL',$id);
}
sub zmenu {
    my ($self, $id ) = @_;
    return { 'caption' => "STS $id", "EMBL: $id" => $self->href( $id ) };
}
1;
