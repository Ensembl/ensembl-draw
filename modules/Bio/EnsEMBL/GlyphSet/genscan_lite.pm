package Bio::EnsEMBL::GlyphSet::genscan_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript);

sub my_label {
    return 'Genscans';
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
sub trascript_type {
  my $self = shift;

  return 'genscan';
}

sub colour {
    my ($self, $vt, $colours, %highlights) = @_;
    return ( $colours->{'col'}, undef );
}

sub href {
    my ($self, $gene, $transcript) = @_;
    return undef;
}

sub zmenu {
    my ($self, $gene, $transcript) = @_;
    return undef;

}

sub text_label {
    my ($self, $gene, $transcript) = @_;
    return undef;
}

sub legend {
    my ($self, $colours) = @_;
    return undef;
}

sub error_track_name { return 'Genscans'; }

1;

