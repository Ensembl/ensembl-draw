package Bio::EnsEMBL::GlyphSet::drerio_estclust;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "EST cluster"; }

sub features {
    my ($self) = @_;
    return (
      $self->{'container'}->get_all_SimilarityFeatures( "ESTclusters", 80, $self->glob_bp),
      $self->{'container'}->get_all_SimilarityFeatures( "ESTassemblies", 80, $self->glob_bp)
    );
}

sub href {
    my ( $self, $id ) = @_;
    if($id =~ /^WZ/) {
        return $self->{'config'}->{'ext_url'}->get_url('WZ_HOME',$id);
    } else {
        return $self->{'config'}->{'ext_url'}->get_url('IMCB_HOME',$id);
    }
}

sub zmenu {
    my ($self, $id ) = @_;
    if($id =~ /^WZ/) {
        return { 'caption' => "WZ cluster: $id", "WZ Home" => $self->href( $id ) };
    } else {
        return { 'caption' => "IMCB cluster: $id", "IMCB Home" => $self->href( $id ) };
    }
}
1;
