package Bio::EnsEMBL::GlyphSet::trna;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "tRNAs"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_SimilarityFeatures_above_score(
        "tRNA", 25, $self->glob_bp()
    );
}

sub href {
    my ($self, $id ) = @_;
    return undef;
}

sub zmenu {
    my ($self, $id ) = @_;
    return undef;
}
1;
