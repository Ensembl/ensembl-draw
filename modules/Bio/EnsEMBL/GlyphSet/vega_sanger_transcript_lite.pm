package Bio::EnsEMBL::GlyphSet::vega_sanger_transcript_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_transcript_vega;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript_vega);

sub my_label {
    return 'Dunham Group trans.';
}

sub logic_name {
return 'sanger';
}

sub zmenu_caption {
return 'Dunham Gene';
}

1;
