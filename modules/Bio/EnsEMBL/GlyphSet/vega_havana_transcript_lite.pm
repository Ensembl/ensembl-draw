package Bio::EnsEMBL::GlyphSet::vega_havana_transcript_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript_vega;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript_vega);

sub my_label {
    return 'Havana trans.';
}

sub logic_name {
return 'havana';

}

sub zmenu_caption {
return 'Havana Gene';
}


sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
	    'unknown'   => $Config->get('_colours','unknown'),
	    'xref'      => $Config->get('_colours','xref'),
	    'pred'      => $Config->get('_colours','pred'),
	   # 'known'     => $Config->get('_colours','known'),
	    'hi'        => $Config->get('_colours','hi'),
	    'superhi'   => $Config->get('_colours','superhi'),
	    'Novel_CDS'        => $Config->get('_colours','Novel_CDS'), 
	    'Putative'         => $Config->get('_colours','Putative'), 
	    'Known'            => $Config->get('_colours','Known'),  
	    'Novel_Transcript' => $Config->get('_colours','Novel_Transcript'), 
	    'Pseudogene'       => $Config->get('_colours','Pseudogene')
    };
}

# $Config->get('_colours','Known'),

sub features {
  my ($self) = @_;
  return $self->{'container'}->get_all_Genes($self->logic_name());
}


sub colour {
    my ($self, $gene, $transcript, $colours, %highlights) = @_;

  #  my $genecol = $colours->{ $transcript->is_known() ? lc( $transcript->external_status ) : 'unknown'};

my $genecol = $colours->{$gene->type()};

    if(exists $highlights{$transcript->stable_id()}) {
      return ($genecol, $colours->{'superhi'});
    } 

elsif(exists $highlights{$transcript->external_name()}) {
      return ($genecol, $colours->{'superhi'});
    } 

elsif(exists $highlights{$gene->stable_id()}) {
      return ($genecol, $colours->{'hi'});
    }
      
    return ($genecol, undef);
}

sub href {
    my ($self, $gene, $transcript ) = @_;

    my $gid = $gene->stable_id();
    my $tid = $transcript->stable_id();

   return $self->{'config'}->{'_href_only'} eq '#tid' ?
        "#$tid" : 
        qq(/$ENV{'ENSEMBL_SPECIES'}/geneview?gene=$gid);
}


sub zmenu {
    my ($self, $gene, $transcript) = @_;

   my $tid = $transcript->stable_id();
    my $pid = $transcript->translation->stable_id(),
    my $gid = $gene->stable_id();
    my $id   = $transcript->external_name() eq '' ? $tid : ( $transcript->external_db.": ".$transcript->external_name() );
  

 


my $zmenu = {
'caption'  =>$self->zmenu_caption(),
"00:$id" => "",
"01:Gene:$gid" => "/$ENV{'ENSEMBL_SPECIES'}/geneview?gene=$gid",
"02:Transcr:$tid" => "/$ENV{'ENSEMBL_SPECIES'}/transview?transcript=$tid",          
"04:Export cDNA" => "/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=cdna&id=$tid",
 };
    

    if($pid) {
    $zmenu->{"03:Peptide:$pid"}=
    	qq(/$ENV{'ENSEMBL_SPECIES'}/protview?peptide=$pid);
    $zmenu->{'05:Export Peptide'}=
    	qq(/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=peptide&id=$pid);	
    }
    
    my $DB = EnsWeb::species_defs->databases;

   if($DB->{'ENSEMBL_EXPRESSION'}) {
     $zmenu->{'06:Expression information'} = 
	"/$ENV{'ENSEMBL_SPECIES'}/sageview?alias=$gid";
    }

    return $zmenu;
}





sub text_label {
  my ($self, $gene, $transcript) = @_;
  my $id = $transcript->stable_id();
  my $external_id  = $transcript->external_name(); 
  if( $self->{'config'}->{'_both_names_'} eq 'yes') {
    $id .=  ' $external_id' ;
  }
  return $id;
}

sub legend {
    my ($self, $colours) = @_;


    return ('genes', 1000,
            [
                'Curated known genes'    => $colours->{'Known'},
                'Curated novel CDS'      => $colours->{'Novel_CDS'},
                'Curated putative'       => $colours->{'Putative'},
                'Curated novel Trans'    => $colours->{'Novel_Transcript'},
                'Curated pseudogenes'    => $colours->{'Pseudogene'}
            ]
    );

}

sub error_track_name { return '$self->zmenu_caption() transcripts'; }

1;
