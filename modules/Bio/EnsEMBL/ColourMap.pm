package Bio::EnsEMBL::ColourMap;
use strict;
use Sanger::Graphics::ColourMap;
use vars qw(@ISA);
@ISA = qw(Sanger::Graphics::ColourMap);

sub new {
  my $class = shift;
  my $species_defs = shift;
  my $self = $class->SUPER::new( @_ );

  my %new_colourmap = qw(
    BACKGROUND1 background0
    BACKGROUND3 background3
    BACKGROUND4 background2
    BACKGROUND5 background1
    CONTIGBLUE1 contigblue1
    CONTIGBLUE2 contigblue2
    HIGHLIGHT1  highlight1
    HIGHLIGHT2  highlight2
  );
  while(my($k,$v) = each %{$species_defs->ENSEMBL_STYLE||{}} ) {
    my $k2 = $new_colourmap{ $k };
    $self->{$k2} = $v if $k2;
  }

  $self->{'colour_sets'} = {};
  my %core = (
    '_KNOWN'     => [ 'rust', 'known' ],
    '_KNOWNXREF' => [ 'rust', 'known' ],
    '_XREF'      => [ 'black','novel' ],
    '_ORTH'      => [ 'green3', 'ortholog' ],
    '_PREDXREF'  => [ 'red3',   'prediction'  ],
    '_PRED'      => [ 'red3',   'prediction'  ],
    '_BACCOM'    => [ 'red',    'bacterial contaminent' ],
    '_'          => [ 'black',  'novel' ],
    '_PSEUDO'    => [ 'grey50', 'pseudogene' ],
  );
  $self->colourSet( 'cow_protein',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    'cow_protein' => [ 'blue', 'Cow protein' ]
  );
  $self->colourSet( 'ensembl_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    map { $_ => [ $core{$_}[0], "EnsEMBL predicted genes (@{[$core{$_}[1]]})" ] } keys %core
  );
  $self->colourSet( 'sgd_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    map { $_ => [ $core{$_}[0], "SGD predicted genes (@{[$core{$_}[1]]})" ] } keys %core
  );
  $self->colourSet( 'bee_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    map { $_ => [ $core{$_}[0], "Bee predicted genes (@{[$core{$_}[1]]})" ] } keys %core
  );
  $self->colourSet( 'bee_pre_gene',
    'Homology_high'   => [ 'sienna4', 'Homology high' ],
    'Homology_medium' => [ 'sienna3', 'Homology medium' ],
    'Homology_low'    => [ 'sienna2', 'Homology low' ],
    'BeeProtein'      => [ 'blue', 'Aligned Bee Protein' ]
  );
  $self->colourSet( 'genoscope_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    '_GSTEN' => [ 'black', 'Genoscope predicted genes' ],
    '_HOX' => [ 'rust', 'Genoscope annotated genes' ],
    '_CYT' => [ 'rust', 'Genoscope annoateed genes' ],
  );
  $self->colourSet( 'wormbase_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    map { $_ => [ $core{$_}[0], "Wormbase predicted genes (@{[$core{$_}[1]]})" ] } keys %core
  );
  $self->colourSet( 'flybase_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    map { $_ => [ $core{$_}[0], "Flybase predicted genes (@{[$core{$_}[1]]})" ] } keys %core
  );
  $self->colourSet( 'vega_gene',
    'hi'                               => 'highlight1',
    'superhi'                          => 'highlight2',
    'protein_coding_KNOWN'             => [ 'dodgerblue4', 'Known Protein coding'],
    'processed_transcript_KNOWN'       => [ 'dodgerblue4', 'Known Processed transcript'],
    'protein_coding_in_progress_KNOWN' => [ 'lightskyblue4', 'Known Protein coding (in progress)'],
    'protein_coding_NOVEL'             => [ 'blue', 'Novel Protein coding' ],
    'protein_coding_in_progress_NOVEL' => [ 'cornflowerblue', 'Novel Protein coding (in progress)'],
    'protein_coding_PREDICTED'         => [ 'steelblue4', 'Predicted Protein coding'] ,
    'processed_transcript_NOVEL'       => [ 'skyblue3', 'Novel Processed transcript' ],
    'processed_transcript_PUTATIVE'    => [ 'lightslateblue', 'Putative Processed transcript' ],
    'total_pseudogene_'                => [ 'grey70', 'Total Pseudogenes' ],
    'pseudogene_'                      => [ 'grey70', 'Pseudogene' ],
    'processed_pseudogene_'            => [ 'grey38', 'Processed pseudogene' ],
    'unprocessed_pseudogene_'          => [ 'grey27', 'Unprocessed pseudogene' ],
    'Ig_segment_KNOWN'                 => [ 'midnightblue', 'Known Ig segment' ],
    'Ig_segment_NOVEL'                 => [ 'navy', 'Ig segment' ],
    'total_Ig_segment_'                => [ 'midnightblue', 'Ig segment' ],
    'Ig_pseudogene_segment_'           => [ 'mediumpurple4', 'Ig pseudogene' ],
  );
  $self->colourSet( 'rna_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    'rna-pseudo' => [ 'plum3', 'RNA Pseudogene' ] ,
    'rna-real'   => [ 'plum4', 'RNA gene' ]
  );
  $self->colourSet( 'est_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    'EST_Genebuilder'  => [ 'purple1', 'EST gene' ],
    'genomewise' => [ 'purple1', 'EST gene' ],
    'est_genebuilder' => [ 'purple1', 'EST gene' ],
    'estgene'    => [ 'purple1', 'EST gene' ],
    'est_gene'    => [ 'purple1', 'EST gene' ],
    'protein_coding' => [ 'purple1', 'EST gene' ],
    'est_seqc' => [ 'purple1', "3' EST (Kyoto)" ],
    'est_seqn' => [ 'purple1', "5' EST (Kyoto)" ] ,
    'est_seqs' => [ 'purple1', "full insert cDNA clone" ],
    'dbest_ncbi' => [ 'purple1', "3/5' EST (dbEST)" ]
  );
  $self->colourSet( 'ciona_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    'jgi_v1'              => [ 'blue', 'JGI v1 models' ],
    'kyotograil_2004'     => [ 'dodgerblue4', 'Kyotograil 2004' ],
    'kyotograil_2005'     => [ 'dodgerblue4', 'Kyotograil 2005' ],
  );
  $self->colourSet( 'prot_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    'cdna_all'      => [ 'orchid2', 'Aligned cDNA' ],
    'TGE_gw'        => [ 'orchid4', 'Aligned protein' ],
    'tge_gw'        => [ 'orchid4', 'Aligned protein' ],
    'targettedgenewise' => [ 'orchid4', 'Aligned protein' ],
    'protein_coding'  => [ 'orchid4', 'Aligned protein' ], 
    'xtrop_cdna'      => [ 'orchid2', 'Aligned cDNA' ],
    'xtrop_cDNA'      => [ 'orchid2', 'Aligned cDNA' ],
    '_col'            => [ 'orchid4', 'Aligned protein' ], 
  );
  $self->colourSet( 'refseq_gene',
    'hi'         => 'highlight1',
    'superhi'    => 'highlight2',
    '_refseq' => [ 'blue', 'Aligned RefSeq' ],
  );
  $self->colourSet( 'all_genes', map { $self->colourSet($_) } keys %{$self->{'colour_sets'}} );
    
  $self->colourSet( 'protein',
    'default'    => 'gold',
    'refseq'     => 'orange',
  );
  $self->colourSet( 'cdna',
    'default'    => 'chartreuse3',
    'refseq'     => 'mediumspringgreen',
    'riken'      => 'olivedrab4',
    'genoscope'  => 'green',
    'genoscope_ecotig'  => 'blue',
    'WZ'         => 'chartreuse3',
    'EMBL'       => 'mediumspringgreen',
    'IMCB_HOME'  => 'olivedrab4',
  );
  $self->colourSet( 'mrna',
    'default'    => 'red',
  );
  $self->colourSet( 'est',
    'default'    => 'purple1',
    'genoscope'  => 'purple3',
    'WZ'         => 'purple1',
    'IMCB_HOME'  => 'purple3'
  );
  $self->colourSet( 'glovar_sts',
    'col'               => 'grey',
    'Unknown'           => 'grey',
    'PCR_pass'          => 'green',
    'Failed'            => 'red',
    'Sequence_pass'     => 'green',
    'HW_pass'           => 'green',
    'Multiple_product'  => 'red',
  );
  $self->colourSet( 'snp',
    '_coding'      => 'red',
    '_utr'         => 'orange',
    '_intron'      => 'contigblue2',
    '_local'       => 'contigblue1',
    '_'            => 'gray50',
    'label_coding' => 'white',
    'label_utr'    => 'black',
    'label_intron' => 'white',
    'label_local'  => 'white',
    'label_'       => 'white',
  );

  $self->{'colour_sets'}{'synteny'} = [qw(
    red3 green4 cyan4 blue3 chocolate3 brown
    chartreuse4 grey25 deeppink4 slateblue3
    olivedrab4 gold4 blueviolet seagreen4 violetred3
  )];

  # Allowed values are: 'INTRONIC','UPSTREAM','DOWNSTREAM',
  #             'SYNONYMOUS_CODING','NON_SYNONYMOUS_CODING','FRAMESHIFT_CODING',
  #             '5PRIME_UTR','3PRIME_UTR','INTERGENIC'
  $self->colourSet( 'variation',
		    'INTRONIC'                  => 'contigblue2',
		    'UPSTREAM'                  => 'lightsteelblue2',  
		    'DOWNSTREAM'                => 'lightsteelblue2',
		    '5PRIME_UTR'                => 'lightpink2',
		    '3PRIME_UTR'                => 'lightpink2',
		    'UTR'                       => 'lightpink2',
		    'NON_SYNONYMOUS_CODING'     => 'red',
		    'FRAMESHIFT_CODING'         => 'orange',
		    'SYNONYMOUS_CODING'         => 'chartreuse3',
                    'STOP_GAINED'               => 'magenta',
                    'STOP_LOST'                 => 'magenta',
		    'INTERGENIC'                => 'gray50',
		    '_'                         => 'gray50',
		    'labelINTRONIC'             => 'white',
		    'labelUPSTREAM'             => 'black',
		    'labelDOWNSTREAM'           => 'black',
		    'label5PRIME_UTR'           => 'white',
		    'label3PRIME_UTR'           => 'white',
		    'labelUTR'                  => 'white',
		    'labelNON_SYNONYMOUS_CODING'=> 'white',
		    'labelFRAMESHIFT_CODING'    => 'white',
		    'labelSYNONYMOUS_CODING'    => 'white',
                    'labelSTOP_GAINED'          => 'white',
                    'labelSTOP_LOST'            => 'white',
		    'labelINTERGENIC'           => 'white',
		    'label_'                    => 'white',
		  );

  $self->colourSet( 'bee_pre_gene',
    'Homology_high'   => [ 'sienna4', 'Homology high' ],
    'Homology_medium' => [ 'sienna3', 'Homology medium' ],
    'Homology_low'    => [ 'sienna2', 'Homology low' ],
    'BeeProtein'      => [ 'blue', 'Aligned Bee Protein' ]
  );

  $self->colourSet( 'marker',
		    ''               => 'magenta',
		    'est'            => 'magenta',
		    'microsatellite' => 'plum4',
		  );

  $self->colourSet( 'alignment',
		    'INTRONIC'                  => 'limegreen',
		    'UPSTREAM'                  => 'mediumspringgreen',  
		    'DOWNSTREAM'                => 'mediumspringgreen',
		    '5PRIME_UTR'                => 'darkorchid1',
		    '3PRIME_UTR'                => 'darkorchid1',
		    'UTR'                       => 'darkorchid1',
		    'NON_SYNONYMOUS_CODING'     => 'red',
		    'FRAMESHIFT_CODING'         => 'orange',
		    'SYNONYMOUS_CODING'         => 'chartreuse3',
                    'STOP_GAINED'               => 'magenta',
                    'STOP_LOST'                 => 'magenta',
		    'INTERGENIC'                => 'gray50',
		    '_'                         => 'gray50',
		    );


  return $self;
}

sub colourSet {
  my $self = shift;
  my $name = shift;
  if(@_) {
    $self->{'colour_sets'}{$name} = {@_};
  }
  return %{$self->{'colour_sets'}{$name}||{}};
}
1;
