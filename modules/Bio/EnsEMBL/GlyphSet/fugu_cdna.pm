package Bio::EnsEMBL::GlyphSet::fugu_cdna;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "cDNA"; }

sub features {
    my ($self) = @_;

    return $self->{'container'}->get_all_SimilarityFeatures_by_strand("fugu_cdna",80,$self->glob_bp,$self->strand());
}

sub zmenu {
    my ($self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    #tania
    my ($newid) = 
              ($id =~ /^\w+(?:\:|\|[\w\.]+\|)([\w\.]+)/ );
    
    return {
        'caption' => "$id",
	    "Protein homology" =>
            (
                    #tania - it's never going to srs, just ncbi.. for now.. 
		    #quick and dirty,prob should use the Fugu_R.def.pm 
		    # $id=~/^NP/ ?
		    #"http://www.sanger.ac.uk/srs6bin/cgi-bin/wgetz?-e+[REFSEQPROTEIN-ID:$id]" :
		    #                    "http://www.ebi.ac.uk/cgi-bin/swissfetch?$id"
		    "http://www.ncbi.nlm.nih.gov/entrez/viewer.cgi?cmd=Retrieve&db=Protein&list_uids=$newid&dopt=Brief"
            )
    };
}
1;
