package Bio::EnsEMBL::GlyphSet::glovar_sts;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;

@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "Glovar STS"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_ExternalLiteFeatures('GlovarSTS');
}

sub colour {
    my ($self, $id, $f) = @_;
    return $self->{'colours'}->{$f->{'_pass'}}
}

sub href { 
    my ($self, $id) = @_;
    return $self->ID_URL( 'GLOVAR_STS', $id );
}

sub zmenu {
    my ($self, $id, $f_arr) = @_;
    ## get first object of the STS pair
    my $f = $f_arr->[0][2];
    return {
        'caption' => $f->hseqname,
        '01:ID: '.$id => '',
        '02:Test status: '.$f->{'_pass'} => '',
        "03:STS Report" => $self->href( $id ),
    };
}
1;
