package Bio::EnsEMBL::GlyphSet::sanger_transcript_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    my $self = shift;
    return $self->{'config'}->{'_draw_single_Transcript'} || 'Sanger trans.';
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
        'hi'               => $Config->get('sanger_transcript_lite','hi'),
        'super'            => $Config->get('sanger_transcript_lite','superhi'),
        'HUMACE-Novel_CDS'        => $Config->get('sanger_transcript_lite','sanger_Novel_CDS'),
        'HUMACE-Putative'         => $Config->get('sanger_transcript_lite','sanger_Putative'),
        'HUMACE-Known'            => $Config->get('sanger_transcript_lite','sanger_Known'),
        'HUMACE-Novel_Transcript' => $Config->get('sanger_transcript_lite','sanger_Novel_Transcript'),
        'HUMACE-Pseudogene'       => $Config->get('sanger_transcript_lite','sanger_Pseudogene'),
    };
}

sub transcript_type {
  my $self = shift;

  return 'sanger';
}

sub colour {
    my ($self, $vt, $colours, %highlights) = @_;
    return ( 
        $colours->{$vt->{'type'}}, 
        exists $highlights{$vt->{'stable_id'}} ? $colours->{'superhi'} : (
         exists $highlights{$vt->{'synonym'}}  ? $colours->{'superhi'} : (
          exists $highlights{$vt->{'gene'}}    ? $colours->{'hi'} : undef ))
    );
}

sub href {
    my ($self, $gene, $transcript) = @_;
    return $self->{'config'}->{'_href_only'} eq '#tid' ?
       "#$transcript->stable_id()" :
       qq(/$ENV{'ENSEMBL_SPECIES'}/geneview?db=sanger&gene=$gene->stable_id());
}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    my $type = $transcript->type();
    $type =~ s/HUMACE-//g;
    my $zmenu = {
        'caption'                  => "Sanger Gene",
        "01:$transcript->stable_id()"    => '',
        "02:Gene: $gene->stable_id()"   => $self->href( $gene, $transcript ),
        "04:Sanger curated ($type)"   => ''
    };

    my $translation_id = $transcript->translation_id();

    if($translation_id ne '') {
      $zmenu->{"03:Protien"} = 
	qq(/$ENV{'ENSEMBL_SPECIES'}/protview?db=sanger&peptide=$translation_id);
    }
    
    return $zmenu;
}

sub text_label {
    my ($self, $gene, $transcript) = @_;
    return $transcript->stable_id();
}

sub legend {
    my ($self, $colours) = @_;
    return ('sanger_genes', 1000,
            [
                'Sanger curated known genes'    => $colours->{'HUMACE-Known'},
                'Sanger curated novel CDS'      => $colours->{'HUMACE-Novel_CDS'},
                'Sanger curated putative'       => $colours->{'HUMACE-Putative'},
                'Sanger curated novel Trans'    => $colours->{'HUMACE-Novel_Transcript'},
                'Sanger curated pseudogenes'    => $colours->{'HUMACE-Pseudogene'}
            ]
    );
}

sub error_track_name { return 'Sanger transcripts'; }

1;
