package Bio::EnsEMBL::GlyphSet::glovar_haplotype;
use strict;
use vars qw(@ISA);
use Digest::MD5 qw(md5_hex);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "Glovar Haplotype"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_ExternalLiteFeatures('GlovarHaplotype');
}

sub colour {
    my ($self, $id, $f) = @_;
    ## create a reproducable random colour from the population
    ## (possible improvement: exclude very light and very dark colours)
    my $hex = substr(md5_hex($f->{'_population'}), 0, 6);
    return $self->{'config'}->colourmap->add_hex($hex);
}

sub href { 
    my ($self, $id) = @_;
    return $self->ID_URL( 'GLOVAR_HAPLOTYPE', $id );
}

sub zmenu {
    my ($self, $id, $f_arr) = @_;
    ## get first object of the Haplotype group
    my $f = $f_arr->[0][2];
    return {
        'caption' => $f->hseqname,
        '01:ID: '.$id => '',
        '02:Population: '.$f->{'_population'} => '',
        '03:Length: '.$f->{'_block_length'} => '',
        '04:No. SNPs: '.$f->{'_num_snps'} => '',
        "06:Haplotype Report" => $self->href( $id ),
    };
}
1;
