package Bio::EnsEMBL::GlyphSet::fgenesh_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    return 'Fgenesh';
}

sub colours {
    my $self = shift;
    my $Config = $self->{'config'};
    return {
        'hi'               => $Config->get('fgenesh_lite','hi'),
        'super'            => $Config->get('fgenesh_lite','superhi'),
        'col'              => $Config->get('fgenesh_lite','col')
    };
}

sub features {
    my $self = shift;
    return $self->{'container'}->get_all_VirtualFgenesh_startend_lite();
}

sub colour {
    my ($self, $vt, $colours, %highlights) = @_;
    return ( $colours->{'col'}, undef );
}

sub href {
    my ($self, $vt) = @_;
    return undef;
}

sub zmenu {
    my ($self, $vt) = @_;
    return undef;

}

sub text_label {
    my ($self, $vt) = @_;
    return undef;
}

sub legend {
    my ($self, $colours) = @_;
    return undef;
}

sub error_track_name { return 'Fgenesh'; }

1;

