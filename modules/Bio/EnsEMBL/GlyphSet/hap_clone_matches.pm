package Bio::EnsEMBL::GlyphSet::hap_clone_matches;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

#this is used just for drawing the haplotype scaffolds on 'chromosome';
#generic_clone.pm is used for overview

sub my_label { return "Haplotype Scaffolds"; }

sub features {
  my ($self) = @_;
  return $self->{'container'}->get_all_MiscFeatures( 'hclone' );
}

sub colour {
  my ($self, $f ) = @_;
  return $self->my_config( 'colour' ), $self->my_config( 'label' );
}

1;
