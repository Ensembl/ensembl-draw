package Bio::EnsEMBL::GlyphSet::eponine_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple_hash;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple_hash);

sub my_label { return "Eponine"; }

sub my_description { return "Eponine transcription<br />&nbsp;start sites"; }

sub my_helplink { return "markers"; }

sub features {
    my ($self) = @_;

    return $self->{'container'}->get_all_SimpleFeatures_above_score('Eponine', 
								    .8);
}

sub href {
    my ($self, $f ) = @_;
    return undef;
}

sub zmenu {
    my ($self, $f ) = @_;
    
    my $score = $f->score();
    my $start = $f->start() + $self->{'container'}->chr_start() - 1;
    my $end = $f->end() + $self->{'container'}->chr_start() - 1;

    return {
        'caption'                                     => 'eponine',
        "01:Score: $score"                            => '',
        "02:bp: $start-$end"                          => ''
    };
}
1;
