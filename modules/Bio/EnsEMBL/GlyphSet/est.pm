package Bio::EnsEMBL::GlyphSet::est;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "ESTs"; }

sub features {
    my ($self) = @_;
    return map { ($_->strand() == $self->strand) && ($_->source_tag() eq 'est') ? $_ : () } $self->{'container'}->get_all_ExternalFeatures($self->glob_bp)

}
sub zmenu {
    my ($self, $id ) = @_;
    my $estid = $id;
    $estid =~s/(.*?)\.\d+/$1/;
    #marie - uses local bioperl db to serve up protein homology
    my $biodb = 'fugu_ests'; #specify db name here - corresponds to bioperl_db, biodatabases table
    my $format = 'fasta';
    return { 'caption' => "EST $id",
	       # marie changed to use our local bioperl-db to fetch details
               # "$id"     => "http://www.sanger.ac.uk/srs6bin/cgi-bin/wgetz?-e+[DBEST-ALLTEXT:$estid]" }
                "$id"     => "/perl/bioperldbview?id=$estid&biodb=$biodb&format=$format", }
}
;
