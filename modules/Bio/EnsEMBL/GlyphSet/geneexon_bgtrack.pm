package Bio::EnsEMBL::GlyphSet::geneexon_bgtrack;
use strict;
use vars qw(@ISA);
use EnsWeb;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end eprof_dump);

use Sanger::Graphics::Glyph::Space;
use Bio::EnsEMBL::GlyphSet;
  
@Bio::EnsEMBL::GlyphSet::geneexon_bgtrack::ISA = qw(Bio::EnsEMBL::GlyphSet);
sub _init {
  my ($self) = @_;

  my $Config        = $self->{'config'};
  my $container     = exists $self->{'container'}{'ref'} ? $self->{'container'}{'ref'} : $self->{'container'};
  my $target_gene   = $Config->{'geneid'} || $Config->{'geneid2'};
    
  my $h             = 1;
    
  my @bitmap        = undef;
  my $colour        = $Config->get('geneexon_bgtrack','col' );

  my $fontname      = "Tiny";    
  my $pix_per_bp    = $Config->transform->{'scalex'};
  my $bitmap_length = $Config->image_width(); #int($Config->container_width() * $pix_per_bp);

  my $strand  = $self->strand();
  my $length  = $container->length;
    
  my %exons = ();
  if( $Config->{'fakeslice'} ) {
    foreach my $transcript ( @{$Config->{'transcripts'}}  ) { 
      foreach my $exon ( @{$transcript->{'exons'}} ) {
        my $tag = "@{[$exon->[2]->start]}:@{[$exon->[2]->end]}";
        $exons{"$exon->[0]:$exon->[1]:$tag"}++; 
      }
    }
  } else {
    my $features =  $self->{'container'}->get_all_Genes(lc(EnsWeb::species_defs->AUTHORITY));
    foreach my $gene ( @$features ) { 
      next if $target_gene && ($gene->stable_id() ne $target_gene);
      foreach my $transcript (@{$gene->get_all_Transcripts()}) {
        foreach my $exon (@{$transcript->get_all_Exons()}) {
          my $tag = "@{[$exon->start]}:@{[$exon->end]}";
          $exons{ "$tag:$tag" }++; 
        }
      }
    } 
  }
  my $tag = $Config->get( 'geneexon_bgtrack', 'tag' );
  $tag ++ if $strand == -1;
  my $start = $container->chr_start();
  my @exons = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } map { [ split /:/, $_ ] } keys %exons;
  my $T = $strand == 1 ? 1 : 0;
  foreach my $EXON ( @exons ) {
    my( $S,$E,$S2,$E2 ) = @$EXON;
    next if $E<1;
    next if $S>$length;
    my $tag_root = "@{[$S2+$start]}:@{[$E2+$start]}";
    $S = 1 if $S < 1;
    $E = $length if $E > $length;
    my $tglyph = new Sanger::Graphics::Glyph::Space({
      'x' => $S-1,
      'y' => 0,
      'height' => 0,
      'width'  => $E-$S+1,
      'colour' => $colour,
    });
    $self->join_tag( $tglyph, "X:$tag_root-0", 1-$T,0, $colour, 'fill', -99 );
    $self->join_tag( $tglyph, "X:$tag_root-0", $T,0, $colour, 'fill', -99  );
    $self->join_tag( $tglyph, "X:$tag_root=$tag", 1-$T,0, $colour, 'fill', -99 );
    $self->join_tag( $tglyph, "X:$tag_root=$tag", $T,0, $colour, 'fill', -99 );
    $self->push( $tglyph );
  }
}
1;
