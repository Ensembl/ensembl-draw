package Bio::EnsEMBL::GlyphSet::vega_gene_label_lite_genoscope;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
use Bio::EnsEMBL::GlyphSet_gene;
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Bump;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);

use Bio::EnsEMBL::GlyphSet_transcript_label_vega;
@ISA = qw(Bio::EnsEMBL::GlyphSet_transcript_label_vega);


sub features {

my @features = @{$vc->get_all_Genes('genoscope', )};


return \@features;

}

1;
