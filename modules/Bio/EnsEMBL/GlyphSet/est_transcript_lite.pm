package Bio::EnsEMBL::GlyphSet::est_transcript_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    return 'EST trans.';
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
        'genomewise'=> $Config->get('est_transcript_lite','genomewise'),
        'hi'        => $Config->get('est_transcript_lite','hi'),
        'superhi'   => $Config->get('est_transcript_lite','superhi')
    };
}

sub colour {
    my ($self, $gene, $transcript, $colours, %highlights) = @_;
    
    my $highlight = undef;
    my $colour = $colours->{$transcript->type()};

    if(exists $highlights{$transcript->stable_id()}) {
      $highlight = $colours->{'superhi'};
    } elsif(exists $highlights{$transcript->external_name}) {
      $highlight = $colours->{'superhi'};
    } elsif(exists $highlights{$gene->stable_id()}) {
      $highlight = $colours->{'hi'};
    }

    return ($colour, $highlight); 
    
}

sub href {
  my ($self, $gene, $transcript) = @_;

  if( $self->{'config'}->{'_href_only'} eq '#tid' ) {
    return "#" . $transcript->stable_id();
  }

  my $gid = $gene->stable_id();

  return qq(/$ENV{'ENSEMBL_SPECIES'}/geneview?db=estgene&gene=$gid);
}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    my $id ;  
    my $tid = $transcript->stable_id();
    my $pid = $transcript->translation->stable_id(),
    my $gid = $gene->stable_id();
   
    my $zmenu = {
        'caption'              	=> "EST Gene",
	"01:Gene:$gid"          => "/$ENV{'ENSEMBL_SPECIES'}/geneview?gene=$gid&db=estgene",
        "02:Transcr:$tid"    	=> "/$ENV{'ENSEMBL_SPECIES'}/transview?transcript=$tid&db=estgene",                	
        '04:Export cDNA'        => "/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=cDNA&id=$tid"
    };

    if ($transcript->external_name()){
    	$id = $transcript->external_name();
	$zmenu->{"00:$id"}= '';
    }   

    if($pid) {
    $zmenu->{"03:Peptide:$pid"}=
    	qq(/$ENV{'ENSEMBL_SPECIES'}/protview?peptide=$pid&db=estgene);
    $zmenu->{'05:Export Peptide'}=
    	qq(/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=peptide&id=$pid);	
    }
    
    return $zmenu;
  }

sub text_label {
    my ($self, $gene, $transcript) = @_;
    my $tid = $transcript->stable_id();
    my $id  = ($transcript->external_name() eq '') ? 
      $tid : $transcript->external_name();

    if( $self->{'config'}->{'_both_names_'} eq 'yes') {
        return $tid.(($transcript->external_name() eq '') ? '' : " ($id)" );
    }

    return $self->{'config'}->{'_transcript_names_'} eq 'yes' ? $id : "";    
  }


sub features {
  my ($self) = @_;

  return $self->{'container'}->get_all_Genes('estgene');
}

sub legend {
    my ($self, $colours) = @_;
    return ('est_genes', 1000, 
        [
            'EST genes' => $colours->{'genomewise'},
        ]
    );
}

sub error_track_name { return 'EST transcripts'; }

1;
