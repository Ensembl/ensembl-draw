package Bio::EnsEMBL::GlyphSet::drerio_cdna;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "Zebrafish cDNAs"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_DnaAlignFeatures('zfish_cDNA', 80);
}

sub colour {
   my( $self, $id ) = @_;
   return $self->{'colours'}->{
     $id =~/(NM_\d+)/ ? 'refseq' : ( /(RO|ZX|PX|ZA|PL)\d{5}[A-Z]\d{2}/ ? 'riken' : 'col' )
   }
}
sub href {
    my ($self, $id ) = @_;
    if ($id =~ /^(NM_\d+)/){
      return $self->ID_URL('REFSEQ', $1);
    }
    if( $id =~ /(RO|ZX|PX|ZA|PL)\d{5}[A-Z]\d{2}/ ) {
      return $self->ID_URL('RIKEN', $id);
    }
    $id =~ s/\.\d+$//;
    return $self->ID_URL('EMBL',$id);
}
sub zmenu {
  my ($self, $id ) = @_;
  if ($id =~ /^(NM_\d+)/){
    return { 'caption' => "$id", "REFSEQ: $id" => $self->href($id) };
  }
  if( $id =~ /(RO|ZX|PX|ZA|PL)\d{5}[A-Z]\d{2}/ ) {
    return { 'caption' => "$id", "RIKEN: $id" => $self->href($id) };
  }
  return { 'caption' => "$id", "EMBL: $id" => $self->href($id) };
}
1;
