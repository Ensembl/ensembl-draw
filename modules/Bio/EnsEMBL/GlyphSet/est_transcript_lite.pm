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
    my $Config = $self->{'config'}->get('est_transcript_lite','colours');
}

sub colour {
    my ($self, $gene, $transcript, $colours, %highlights) = @_;
    
    my $highlight = undef;
    my $colour = $colours->{$transcript->type()||$gene->type()};

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
  my ($self, $gene, $transcript, %highlights) = @_;
  my $gid = $gene->stable_id();
  my $tid = $transcript->stable_id();

  return ( $self->{'config'}->get('est_transcript_lite','_href_only') eq '#tid' && exists $highlights{$gene->stable_id()} ) ?
        "#$tid" : 
        qq(/@{[$self->{container}{_config_file_name_}]}/geneview?db=estgene&gene=$gid);

}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    my $id = '';

    my $tid = $transcript->stable_id();
    my $pid = $transcript->translation->stable_id(),
    my $gid = $gene->stable_id();
   
    my $zmenu = {
        'caption'              	=> "EST Gene",
	"01:Gene:$gid"          => "/@{[$self->{container}{_config_file_name_}]}/geneview?gene=$gid&db=estgene",
        "02:Transcr:$tid"    	=> "/@{[$self->{container}{_config_file_name_}]}/transview?transcript=$tid&db=estgene",                	
        '04:Export cDNA'        => "/@{[$self->{container}{_config_file_name_}]}/exportview?tab=fasta&type=feature&ftype=cDNA&id=$tid"
    };

    if ($transcript->external_name()){
    	$id = $transcript->external_name();
	$zmenu->{"00:$id"}= '';
    }   

    if($pid) {
    $zmenu->{"03:Peptide:$pid"}=
    	qq(/@{[$self->{container}{_config_file_name_}]}/protview?peptide=$pid&db=estgene);
    $zmenu->{'05:Export Peptide'}=
    	qq(/@{[$self->{container}{_config_file_name_}]}/exportview?tab=fasta&type=feature&ftype=peptide&id=$pid);	
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
  if( $self->{'config'}->{'fakecore'} ) {
    my $G = $self->{'container'}->get_all_Genes('genomewise');
       push @$G, @{$self->{'container'}->get_all_Genes('estgene')};
    return $G;
  } else {
    my $G = $self->{'container'}->get_all_Genes('genomewise','estgene');
       push @$G, @{$self->{'container'}->get_all_Genes('estgene','estgene')};
    return $G;
  }
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
