package Bio::EnsEMBL::GlyphSet::genscan_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    return 'Genscan';
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
        'hi'               => $Config->get('genscan_lite','hi'),
        'super'            => $Config->get('genscan_lite','superhi'),
        'col'              => $Config->get('genscan_lite','col')
    };
}

sub features {
    my $self = shift;
    return $self->{'container'}->get_all_VirtualGenscans_startend_lite();
}

sub colour {
    my ($self, $vt, $colours, %highlights) = @_;
    return ( $colours->{'col'}, undef );
}

sub href {
    my ($self, $vt) = @_;
    my $id = $vt->{'genscan'};
    return undef if $id =~ /^\d/;
   return $self->{'config'}->{'ext_url'}->get_url( 'FASTAVIEW', { 'FASTADB' => 'Peptide_ens_genscan830', 'ID' => $id } );
}

sub zmenu {
    my ($self, $vt) = @_;
    my $id = $vt->{'genscan'};
    return undef if $id =~ /^\d/;
    return {
	'caption' => $id,
        '01:Peptide sequence' => $self->href( $vt ),
        '02:cDNA sequence'    => $self->{'config'}->{'ext_url'}->get_url( 'FASTAVIEW', { 'FASTADB' => 'cDNA_ens_genscan830', 'ID' => $id } ),
    }; 
}

sub text_label {
    return undef;
    my ($self, $vt) = @_;
    return $vt->{'genscan'};
}

sub legend {
    return undef;
    my ($self, $colours) = @_;
}

sub error_track_name { return 'Genscans'; }

1;

