package Bio::EnsEMBL::GlyphSet::drerio_bacs;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "BACs"; }

sub features {
  my ($self) = @_;
  return $self->{'container'}->get_all_DnaAlignFeatures('drerio_bacs', 80) || [];
}

sub href {
  my( $self, $f ) = @_;
  return $self->{'config'}->{'ext_url'}->get_url( 'TRACE' , $f->hseqname );
}

sub zmenu {
  my ($self, $f ) = @_;
  return { 
    'caption'   => "BAC: ".$f->hseqname,
    '01:View details' => $self->href( $f ),
    '02:Orient.: '.($f->strand==1 ? 'forward' : 'reverse') => '',
  };
}

sub image_label {
    my ($self, $f ) = @_;
    return ($f->hseqname,'overlaid');
}

1;

