package Bio::EnsEMBL::GlyphSet::annot_gv_transcript_lite;
###############################################################################
#   annot_gv_transcript_lite
#   GlyphSet for the Sanger Annotators website, based on Ensembl
#   This GlyphSet is a modified copy of annot_gv_transcript_lite.pm, and is
#   used in the Annotation site GeneView.
###############################################################################
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    my $self = shift;
    return $self->{'config'}->{'_draw_single_Transcript'} || 'Annot. trans.';
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
        'unknown'   => $Config->get('annot_gv_transcript_lite','unknown'),
        'known'     => $Config->get('annot_gv_transcript_lite','known'),
        'pseudo'    => $Config->get('annot_gv_transcript_lite','pseudo'),
        'ext'       => $Config->get('annot_gv_transcript_lite','ext'),
        'hi'        => $Config->get('annot_gv_transcript_lite','hi'),
	'superhi'   => $Config->get('annot_gv_transcript_lite','superhi'),
	'HUMACE-Novel_CDS'	=> $Config->get('annot_gv_transcript_lite','sanger_Novel_CDS'),
	'HUMACE-Putative'	=> $Config->get('annot_gv_transcript_lite','sanger_Putative'),
	'HUMACE-Known'          => $Config->get('annot_gv_transcript_lite','sanger_Known'),
	'HUMACE-Novel_Transcript'=> $Config->get('annot_gv_transcript_lite','sanger_Novel_Transcript'),
	'HUMACE-Pseudogene'      => $Config->get('annot_gv_transcript_lite','sanger_Pseudogene'),
    };
}

sub features {
    my $self = shift;
    return $self->{'container'}->get_all_VirtualTranscripts_startend_lite( 'core' );
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
    my ($self, $vt) = @_;
    return $self->{'config'}->{'_href_only'} eq '#tid' ?
        "#$vt->{'stable_id'}" :
        qq(/$ENV{'ENSEMBL_SPECIES'}/geneview?gene=$vt->{'gene'});

}

sub zmenu {
    my ($self, $vt) = @_;
    my $vtid = $vt->{'stable_id'};
    my $id   = $vt->{'synonym'} eq '' ? $vtid : $vt->{'synonym'};
    my $zmenu = {
        'caption'                       => $id,
        "00:Transcr:$vtid"              => "",
        "01:(Gene:$vt->{'gene'})"       => "",
        '03:Transcript information'     => "/$ENV{'ENSEMBL_SPECIES'}/geneview?gene=$vt->{'gene'}",
        '04:Protein information'        => "/$ENV{'ENSEMBL_SPECIES'}/protview?peptide=".$vt->{'translation'},
        '05:Supporting evidence'        => "/$ENV{'ENSEMBL_SPECIES'}/transview?transcript=$vtid",
        '07:Protein sequence (FASTA)'   => "/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=peptide&id=".$vt->{'translation'},
        '08:cDNA sequence'              => "/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=cdna&id=$vtid",
    };
    my $DB = EnsWeb::species_defs->databases;
    $zmenu->{'06:Expression information'}
      = "/$ENV{'ENSEMBL_SPECIES'}/sageview?alias=$vt->{'gene'}" if $DB->{'ENSEMBL_EXPRESSION'};
    return $zmenu;
}

sub text_label {
    my ($self, $vt) = @_;
    return $vt->{'stable_id'};
}

sub legend {
    my ($self, $colours) = @_;
    return ('genes', 900, 
        [
            'Sanger curated known genes'    => $colours->{'HUMACE-Known'},
            'Sanger curated novel CDS'      => $colours->{'HUMACE-Novel_CDS'},
            'Sanger curated putative'       => $colours->{'HUMACE-Putative'},
            'Sanger curated novel Trans'    => $colours->{'HUMACE-Novel_Transcript'},
             'Sanger curated pseudogenes'    => $colours->{'HUMACE-Pseudogene'}
	]
    );
}

sub error_track_name { return 'Sanger Annotated transcripts'; }

1;
