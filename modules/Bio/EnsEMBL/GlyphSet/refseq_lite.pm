package Bio::EnsEMBL::GlyphSet::refseq_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    my $self = shift;
    return "GeneWise (RefSeq)";
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return $Config->get('refseq_lite','colours');
}

sub transcript_type {
  my $self = shift;
  return 'refseq';
}

sub colour {
    my ($self, $gene, $transcript, $colours, %highlights) = @_;
    my $colour = $colours->{'_refseq'};
    my $highlight;
    if( exists $highlights{$gene->stable_id()} ){
        $highlight = $colours->{'hi'};
    }
    return ( $colour, $highlight );
}

sub href {
    my ($self, $gene, $transcript) = @_;
    ( my $id = $gene->stable_id ) =~ s/\.\d+$//;
    return $self->ID_URL( 'REFSEQPROTEIN', $id );
}

sub features {
  my ($self) = @_;
  return $self->{'container'}->get_all_Genes_by_type('refseq');
}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    my $pid  = $transcript->stable_id();
    return {
        'caption'  => "GeneWise (RefSeq)",
        $pid       => $self->href( $gene, $transcript )
    };
}

sub text_label {
    my ($self, $gene, $transcript) = @_;
    return $transcript->stable_id();
}

sub legend { return ;}

sub error_track_name { return 'GeneWise (RefSeq)'; }

1;
