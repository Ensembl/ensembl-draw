package Bio::EnsEMBL::GlyphSet::glovar_trace;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "Glovar Traces"; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_ExternalLiteFeatures('GlovarTrace');
}

sub href { 
    my ($self, $f) = @_;
    return $self->ID_URL( 'TRACE', $f->id );
}

sub zmenu {
    my ($self, $f) = @_;
    return {
        'caption' => $f->name,
        '01:Chr start: '.$f->seq_start => '',
        '02:Chr end: '.$f->seq_end => '',
        '03:Read start: '.$f->read_start => '',
        '04:Read end: '.$f->read_end => '',
        '05:Trace Details' => $self->ID_URL( 'TRACE', $f->id ),
    };
}
1;
