package Bio::EnsEMBL::GlyphSet::cpg_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple_hash;
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple_hash);

sub my_label { return "CpG islands"; }

sub my_helplink { return "markers"; }

sub features {
    my ($self) = @_;
    return 
      @{$self->{'container'}->get_all_SimpleFeatures_above_score('CpG', 25)};
}

sub zmenu {
  my ($self, $f ) = @_;
  
  my $score = $f->score();
  my $len = $f->length();

  return {
        'caption' => 'CPG data island',
        "01:Score: $score" => '',
        "02:bp: $len" => ''
    };
}
1;
