package Bio::EnsEMBL::GlyphSet::generic_vega_transcript_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet::vega_transcript_lite;
@ISA = qw(Bio::EnsEMBL::GlyphSet::vega_transcript_lite);

my %legend_map = (
    'Known'                 => 'Known gene',
    'Novel_CDS'             => 'Novel CDS',
    'Putative'              => 'Putative',
    'Novel_Transcript'      => 'Novel transcript',
    'Pseudogene'            => 'Pseudogene',
    'Processed_pseudogene'  => 'Processed pseudogene',
    'Unprocessed_pseudogene'=> 'Unprocessed pseudogene',
    'Predicted_Gene'        => 'Predicted gene',
    'Ig_Segment'            => 'Immunoglobulin segment',
    'Ig_Pseudogene_Segment' => 'Immunoglobulin pseudogene',
    'Transposon'	    => 'Transposon',
    'Polymorphic'           => 'Polymorphic',
);
    
sub features {
    my ($self) = @_;
    my $author = $self->my_config('author');

    if ($author) {
        # if author is defined in UserConfig, fetch only transcripts by this
        # author
        # check data availability first
        my $chr = $self->{'container'}->seq_region_name;
        my $avail = (split(/ /, $self->my_config('available')))[1]
                    . "." . $self->{'container'}->seq_region_name;
        return ([]) unless(EnsWeb::species_defs->get_config(
                    EnsWeb::species_defs->name, 'DB_FEATURES')->{uc($avail)});
        
        my $db = $self->{'container'}->adaptor->db->get_db_adaptor('vega');
        return $db->get_GeneAdaptor->fetch_all_by_Slice_and_author($self->{'container'}, $author, 'otter');
    } else {
        # else fetch all otter transcripts
        return $self->{'container'}->get_all_Genes('otter');
    }
}

sub my_label {
    my $self = shift;
    return $self->my_config('label');
}

sub colours {
    my $self = shift;
    return $self->{'config'}->get($self->check, 'colours');
}

sub href {
    my ($self, $gene, $transcript, %highlights) = @_;
    my $gid = $gene->stable_id();
    my $tid = $transcript->stable_id();
    my $script_name = $ENV{'ENSEMBL_SCRIPT'} eq 'genesnpview' ? 'genesnpview' : 'geneview';
    return ( $self->{'config'}->get($self->check, '_href_only') eq '#tid' && exists $highlights{$gene->stable_id()} ) ?
        "#$tid" : 
        qq(/@{[$self->{container}{_config_file_name_}]}/geneview?gene=$gid&db=core);
}

sub gene_href {
    my ($self, $gene, %highlights) = @_;
    my $gid = $gene->stable_id();
    return ($self->{'config'}->get($self->check,'_href_only') eq '#gid' && exists $highlights{$gene->stable_id()} ) ?
        "#$gid" :
        qq(/@{[$self->{container}{_config_file_name_}]}/geneview?db=core&gene=$gid);
}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    my $tid = $transcript->stable_id();
    my $translation = $transcript->translation;
    my $pid = $translation->stable_id() if $translation;
    my $gid = $gene->stable_id();
    my $id   = $transcript->external_name() eq '' ? $tid : ( $transcript->external_db.": ".$transcript->external_name() );
    my $type = $transcript->type() || $gene->type();
    $type =~ s/HUMACE-//g;
    $type = $legend_map{$type} || $type;

    my $zmenu = {
        'caption' 	    => $self->my_config('zmenu_caption'),
        "00:$id"	    => "",
        '01:Type: ' . $type => "",
	"02:Gene:$gid"      => "/@{[$self->{container}{_config_file_name_}]}/geneview?gene=$gid&db=core",
        "03:Transcr:$tid"   => "/@{[$self->{container}{_config_file_name_}]}/transview?transcript=$tid&db=core",                	
        "04:Exon:$tid"	    => "/@{[$self->{container}{_config_file_name_}]}/exonview?transcript=$tid&db=core",
        '05:Supporting evidence'    => "/@{[$self->{container}{_config_file_name_}]}/exonview?transcript=$tid&db=core#evidence",

        '08:Export cDNA'  => "/@{[$self->{container}{_config_file_name_}]}/exportview?tab=fasta&type=feature&ftype=cdna&id=$tid",
    };

    if ($pid) {
        $zmenu->{"06:Peptide:$pid"} =  "/@{[$self->{container}{_config_file_name_}]}/protview?peptide=$pid";
        $zmenu->{'09:Export Peptide'}	= "/@{[$self->{container}{_config_file_name_}]}/exportview?tab=fasta&type=feature&ftype=peptide&id=$pid";
    }

    return $zmenu;
}

sub gene_zmenu {
    my ($self, $gene) = @_;
    my $gid = $gene->stable_id();
    my $id   = $gene->external_name() eq '' ? $gid : $gene->external_name();
    my $type = $gene->type();
    $type =~ s/HUMACE-//g;
    $type = $legend_map{$type} || $type;
    my $zmenu = {
        'caption' 	    => $self->my_config('zmenu_caption'),
        "00:$id"	    => "",
        '01:Type: ' . $type => "",
        "02:Gene:$gid"          => qq(/@{[$self->{container}{_config_file_name_}]}/geneview?gene=$gid&db=core),
    };
    return $zmenu;
}

sub text_label {
    my ($self, $gene, $transcript) = @_;
    my $id = $transcript->external_name() || $transcript->stable_id();
    my $Config = $self->{config};
    my $short_labels = $Config->get('_settings','opt_shortlabels');
    unless( $short_labels ){
        my $type = $legend_map{$gene->type} || $gene->type;
        $id .= " \n$type ";
    }
    return $id;
}

sub gene_text_label {
    my ($self, $gene) = @_;
    my $id = $gene->external_name() || $gene->stable_id();
    my $Config = $self->{config};
    my $short_labels = $Config->get('_settings','opt_shortlabels');
    unless( $short_labels ){
        my $type = $legend_map{$gene->type} || $gene->type;
        $id .= " \n$type ";
    }
    return $id;
}

sub legend {
    my ($self, $colours) = @_;
    my @legend = ('genes', 1000, []);
    foreach my $gene_type (sort keys %{ EnsWeb::species_defs->VEGA_GENE_TYPES || {}} ) {
        push(@{@legend[2]}, "$legend_map{$gene_type}" => $colours->{$gene_type} );
    }
    return @legend;
}

sub error_track_name { return 'Vega transcripts'; }

1;


