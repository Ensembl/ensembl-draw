package Bio::EnsEMBL::GlyphSet::supercontigs;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "FPC Contigs"; }

sub features {
    my ($self) = @_;
    my $container_length = $self->{'container'}->length();
    return $self->{'container'}->get_all_MapFrags( 'superctgs' );
}

sub href {
    my ($self, $f ) = @_;
    return "/$ENV{'ENSEMBL_SPECIES'}/$ENV{'ENSEMBL_SCRIPT'}?mapfrag=".$f->name
}

sub colour {
    my ($self, $f ) = @_;
    $self->{'_colour_flag'} = $self->{'_colour_flag'}==1 ? 2 : 1;
    return 
        $self->{'colours'}{"col$self->{'_colour_flag'}"},
        $self->{'colours'}{"lab$self->{'_colour_flag'}"};
}

sub image_label {
    my ($self, $f ) = @_;
    return ($f->name,'overlaid');
}

sub zmenu {
    my ($self, $f ) = @_;
    my $zmenu = { 
        'caption' => "Clone: ".$f->name,
        '01:bp: '.$f->seq_start."-".$f->seq_end => '',
        '02:length: '.$f->length.' bps' => '',
        '03:Centre on superctg' => $self->href($f),
    };
    return $zmenu;
}

1;
