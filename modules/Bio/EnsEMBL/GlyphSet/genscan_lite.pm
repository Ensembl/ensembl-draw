package Bio::EnsEMBL::GlyphSet::genscan_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
use Bio::EnsEMBL::Gene;

@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    return 'Genscans';
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
        'hi'               => $Config->get('genscan_lite','hi'),
        'super'            => $Config->get('genscan_lite','superhi'),
        'col'              => $Config->get('genscan_lite','col')
    };
}

sub genes {
  my $self = shift;

  my @transcripts = ();
  my @genes = ();

  #obtain genscan transcripts
  @transcripts = 
    $self->{'container'}->get_all_PredictionTranscripts('Genscan');

  #wrap each transcript in a gene object
  foreach my $transcript (@transcripts) {
    my $gene = new Bio::EnsEMBL::Gene();

    $gene->add_Transcript($transcript);
    
    push @genes, $gene;
  }

  return @genes;
}

sub colour {
    my ($self, $gene, $transcipt, $colours, %highlights) = @_;
    return ( $colours->{'col'}, undef );
}

sub href {
    my ($self, $gene, $transcript) = @_;
    return undef;
}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    return undef;

}

sub text_label {
    my ($self, $gene, $transcript) = @_;
    return undef;
}

sub legend {
    my ($self, $colours) = @_;
    return undef;
}

sub error_track_name { return 'Genscans'; }

1;

