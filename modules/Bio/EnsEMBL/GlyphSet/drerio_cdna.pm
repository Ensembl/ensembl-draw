package Bio::EnsEMBL::GlyphSet::drerio_cdna;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "cDNAs"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_SimilarityFeatures("drerio_cdna",80);
}

sub href {
    my ($self, $id ) = @_;
    if($id =~ /^N[MP]/) {
        return $self->{'config'}->{'ext_url'}->get_url('REFSEQ',$id);
    } else {
        return $self->{'config'}->{'ext_url'}->get_url('EMBL',$id);
    }
}
sub zmenu {
    my ($self, $id ) = @_;
    if($id =~ /^N[MP]/) {
        return { 'caption' => "$id", "REFSEQ: $id" => $self->href( $id ) };
    } else {
        return { 'caption' => "$id", "EMBL: $id" => $self->href( $id ) };
    }
}
1;
