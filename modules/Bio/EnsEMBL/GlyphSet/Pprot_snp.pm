package Bio::EnsEMBL::GlyphSet::Pprot_snp;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Poly;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Bump;

sub init_label {
    my ($self) = @_;
	return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Sanger::Graphics::Glyph::Text({
        'text'      => 'SNPs',
        'font'      => 'Small',
        'absolutey' => 1,
		
    });
    $self->label($label);
}

sub bump{
	my ($config ,$container, $glyph, $array) = @_;
	if ($config->get('Pprot_snp', 'dep') > 0){ # we bump
            my $pix_per_bp    = $config->transform->{'scalex'};
			my $bump_start = int($glyph->x()   * $pix_per_bp);
			my $bitmap_length = int($container->length() * $pix_per_bp);
            $bump_start = 0 if ($bump_start < 0);
	    
            my $bump_end = $bump_start + $glyph->width() + 3;
            if ($bump_end > $bitmap_length){$bump_end = $bitmap_length};
            my $row = & Sanger::Graphics::Bump::bump_row(
				      $bump_start,
				      $bump_end,
				      $bitmap_length,
					  $array,
				      );
            $glyph->y($glyph->y() + (1.5 * $row * 6)) unless ($glyph->isa("Sanger::Graphics::Glyph::Poly"));
			
			$glyph->y_transform(1.5 * $row * 6) if ($glyph->isa("Sanger::Graphics::Glyph::Poly"));
					
        }
}


sub _init {
    my ($self) = @_;
    my $protein    = $self->{'container'};
    my $Config     = $self->{'config'};
	my $snps		= $protein->{'image_snps'};  
    my $x		   = 0;
	my $y          = 0;
    my $h          = 4;
	my $w      	   = 4;
    my $key        = "Prot SNP";    
	my $last_indel;
	my @bump_array;
	my $pix_per_bp    = $Config->transform->{'scalex'};
	
    if ($snps) {	
	foreach my $int (@$snps) {
	  $x++;
	  my $id     = $int->{'type'}; 

	  if ($int->{'type'} eq 'insert' && ($last_indel ne $int->{'indel'})){
	  my $triangle_end   =  $x - 3/$pix_per_bp;
      my $triangle_start =  $x + 3/$pix_per_bp;
	  my $triangle = new Sanger::Graphics::Glyph::Poly({
					'points'    => [ $triangle_start, $h,
                                     $x, $h-4,
                                     $triangle_end, $h  ],
                    'colour'    => $Config->get('Pprot_snp', $int->{'type'}),
                    'absolutey' => 1,
					'absolutewidth' => 1,
					'zmenu' => {
						'caption' => "Insert Information",
						"00:SNP ID: ".$int->{'snp_id'} => "/@{[$self->{container}{_config_file_name_}]}/snpview?snp=".$int->{'snp_id'}."&source=".$int->{'snp_source'},
						"01:Insert: ". $int->{'allele'} => "",
						"02:Start: $x" => "",
						'03:End: '.($x + 1)  => "",
						'04:Insert Length: '. length($int->{'allele'}) => "", },
                });
		bump($Config, $protein, $triangle, \@bump_array);
	   $self->push($triangle) if(defined $triangle);	   
	  }
	  
	  elsif ($int->{'type'} eq 'delete' && ($last_indel ne $int->{'indel'})){
	  my $triangle_end   =  $x - 3/$pix_per_bp;
      my $triangle_start =  $x + 3/$pix_per_bp;
	  my $triangle = new Sanger::Graphics::Glyph::Poly({
                    'x'        => $x,
					'width'    => $w,
					'points'    => [ $triangle_start, $h-4,
                                     $x, $h,
                                     $triangle_end, $h-4  ],
                    'colour'    => $Config->get('Pprot_snp', $int->{'type'}),
                    'absolutey' => 1,
					'absolutewidth' => 1,
					'zmenu' => {
						'caption' => "Deletion Information",
						"00:SNP ID: ".$int->{'snp_id'} => "/@{[$self->{container}{_config_file_name_}]}/snpview?snp=".$int->{'snp_id'}."&source=".$int->{'snp_source'},
						"01:Deletion: ". $int->{'allele'} => "",
						"02:Start: $x" => "",
						'03:End: '. ($x + length($int->{'allele'})) => "",
						'04:Delete Length: '. length($int->{'allele'})  => "", },
                });
	  bump($Config, $protein, $triangle, \@bump_array);	  
	  $self->push($triangle) if(defined $triangle);	  
	  }
	  
	  elsif ($int->{'type'} eq 'snp' || $int->{'type'} eq 'syn'){  
	    my $type = $int->{'type'} eq 'snp' ? 'Non-synonymous' : 'Synonymous' ;
		my $snp  = '';
		my $alt_codon = '';
		if ($int->{'type'} eq 'snp'){
			$snp = "Alternative Residues: ". $int->{'pep_snp'}  ;
			$alt_codon = "Codon: ";
			for my $letter ( 0..2 ){
				$alt_codon .= $int->{'ambigcode'}[$letter]  ? '['.$int->{'ambigcode'}[$letter].']' : $int->{'nt'}[$letter];   
			}
		}else{
			$snp = "Codon: ";
			for my $letter ( 0..2 ){
				$snp .= $int->{'ambigcode'}[$letter]  ? '['.$int->{'ambigcode'}[$letter].']' : $int->{'nt'}[$letter];   
			}
		}
		my $rect = new Sanger::Graphics::Glyph::Rect({
		'x'        => $x-($w/2),
		'width'    => $w,
		'height'   => $h,
		'colour'   => $Config->get('Pprot_snp', $int->{'type'}),
		'absolutey' => 1,
		'absolutewidth' => 1,
		'zmenu' => {
			'caption' => "SNP Information",
			"00:SNP ID: ".$int->{'snp_id'} => "/@{[$self->{container}{_config_file_name_}]}/snpview?snp=".$int->{'snp_id'}."&source=".$int->{'snp_source'},
			"01:SNP Type: $type"   => "",
			"02:Residue: $x" => "",
			"03:$snp" => "", 
			"05:Alleles: ".$int->{'allele'} => "", },
	    });
		
		if ($alt_codon){$rect->zmenu->{"04:$alt_codon"} = '';}
		
		bump($Config, $protein, $rect, \@bump_array);				
	    $self->push($rect) if(defined $rect);
	}else{
		next;
	}
	$last_indel =  $int->{'indel'};
	}
  }
   
}
1;




















