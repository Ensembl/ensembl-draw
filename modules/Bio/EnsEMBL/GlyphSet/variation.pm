package Bio::EnsEMBL::GlyphSet::variation;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end eprof_dump); 
@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "Variations"; }

sub features {
  my ($self) = @_;
  
  my @vari_features = # @{ $self->{'container'}->get_all_VariationFeatures };
             map { $_->[1] } 
             sort { $a->[0] <=> $b->[0] }
             map { [ substr($_->consequence_type,0,2) * 1e9 + $_->start, $_ ] }
             grep { $_->map_weight < 4 } @{$self->{'container'}->get_all_VariationFeatures()};

  if(@vari_features) {
    $self->{'config'}->{'snp_legend_features'}->{'snps'} 
        = { 'priority' => 1000, 'legend' => [] };
  }

  return \@vari_features;
}

sub href {
  my ($self, $f ) = @_;
  my( $chr_start, $chr_end ) = $self->slice2sr( $f->start, $f->end );
  my $id = $f->variation_name;
  $id =~ s/^rs//;
  my $source = $f->variation->source;
  my $chr_name = $self->{'container'}->seq_region_name();  # call seq region on slice

  return "/@{[$self->{container}{_config_file_name_}]}/variationview?snp=$id&source=$source&chr=$chr_name&vc_start=$chr_start";
}

sub image_label {
  my ($self, $f) = @_;
  return $f->{'_ambiguity_code'} eq '-' ? undef : ($f->{'_ambiguity_code'},'overlaid');
}

sub tag {
  my ($self, $f) = @_;
   if($f->{'_range_type'} eq 'between' ) {
      my $consequence_type = substr($f->consequence_type(),3,6);
      return ( { 'style' => 'insertion', 'colour' => $self->{'colours'}{"_$consequence_type"} } );
   } else {
      return undef;
   }
}

# sub colour {
#   my ($self, $f) = @_;

#   my $consequence_type = substr($f->consequence_type(),3,6);
#   unless($self->{'config'}->{'snp_types'}{$consequence_type}) {
#     my %labels = (
# 	 '_coding' => 'Coding SNPs',
# 	 '_utr'    => 'UTR SNPs',
# 	 '_intron' => 'Intronic SNPs',
# 	 '_local'  => 'Flanking SNPs',
# 	 '_'       => 'Other SNPs' );
#     push @{ $self->{'config'}->{'snp_legend_features'}->{'snps'}->{'legend'}},
#            $labels{"_$consequence_type"} => $self->{'colours'}{"_$consequence_type"};
#     $self->{'config'}->{'snp_types'}{$consequence_type} = 1;
#   }

#   return $self->{'colours'}{"_$consequence_type"},$self->{'colours'}{"label_$consequence_type"}, $f->{'_range_type'} eq 'between' ? 'invisible' : '';
# }


sub zmenu {
  my ($self, $f ) = @_;
  my( $chr_start, $chr_end ) = $self->slice2sr( $f->start, $f->end );
  my $allele = $f->allele_string;
  my $pos =  $chr_start;

  if($f->{'range_type'} eq 'between' ) {
    warn "uses this?, glypsetvariation.pm";
    $pos = "between&nbsp;$chr_start&nbsp;&amp;&nbsp;$chr_end";
  }
  elsif($f->{'range_type'} ne 'exact' ) {
    $pos = "$chr_start&nbsp;-&nbsp;$chr_end";
  }

  my $variation = $f->variation;
  my $status = join ", ", @{$variation->get_all_validation_states};
  my %zmenu = ( 
 	       caption               => "SNP: " . ($f->variation_name),
 	       '01:SNP properties'   => $self->href( $f ),
 	       "02:bp: $pos"         => '',
 	       "03:status: ".($status || '-') => '',
 	       "07:ambiguity code: ".$f->{'_ambiguity_code'} => '',
 	       "08:alleles: ".$f->allele_string => '',
	      );

  foreach my $db (@{  $variation->get_all_synonym_sources }) {
    if( $db eq 'TSC-CSHL' || $db eq 'HGVBASE' || $db eq 'dbSNP' || $db eq 'WI' ) {
      $zmenu{"16:$db: ".$f->variation_name} =$self->ID_URL($db, $f->variation_name);
    }
  }

  my $consequence_type = $f->consequence_type;
  $zmenu{"57:Type: $consequence_type"} = "" unless $consequence_type eq '';  
  return \%zmenu;
}
1;
