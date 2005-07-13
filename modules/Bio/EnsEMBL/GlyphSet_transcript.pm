package Bio::EnsEMBL::GlyphSet_transcript;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Intron;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Composite;
use Sanger::Graphics::Glyph::Line;
use  Sanger::Graphics::Bump;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);
use Time::HiRes;

sub init_label {
  my ($self) = @_;
  return if( defined $self->{'config'}->{'_no_label'} );
  my $HELP_LINK = $self->check();
  my $label = new Sanger::Graphics::Glyph::Text({
    'text'      => $self->my_label(),
    'font'      => 'Small',
    'absolutey' => 1,
    'href'      => qq[javascript:X=hw('@{[$self->{container}{_config_file_name_}]}','$ENV{'ENSEMBL_SCRIPT'}','$HELP_LINK')],
    'zmenu'     => {
      'caption'                     => 'HELP',
      "01:Track information..."     => qq[javascript:X=hw(\'@{[$self->{container}{_config_file_name_}]}\',\'$ENV{'ENSEMBL_SCRIPT'}\',\'$HELP_LINK\')]
    }
  });
  $self->label($label);
  $self->bumped( $self->{'config'}->get($HELP_LINK, 'compact') ? 'no' : 'yes' );
}
#'
sub my_label { return 'Missing label'; }
sub colours { return {}; } 
sub text_label { return undef; } 
sub gene_text_label { return undef; } 
sub transcript_type { return undef; } 
sub features { return []; }
sub href { return undef; }
sub gene_href { return undef; }
sub zmenu { return undef; }
sub gene_zmenu { return undef; }
sub colour { return 'red'; }
sub gene_colour { my $self = shift; return $self->colour(); } 

 
sub _init {
  my ($self) = @_;
  my $type   = $self->check();
  my $Config = $self->{'config'};
  my $strand_flag = $Config->get($type,'str');

## If forced onto one strand....
  return if ( $strand_flag eq 'f' and $self->{'container'}{'strand'} != 1 ) ||
            ( $strand_flag eq 'r' and $self->{'container'}{'strand'} == 1 );
  if( $Config->get( $type, 'compact' ) ) {
    $self->compact_init();
  } else {
    $self->expanded_init();
  }
} 

sub compact_init {
  my ($self) = @_;
  my $type = $self->check();
  return unless defined $type;

  my $Config        = $self->{'config'};
  my $strand_flag   = $Config->get($type,'str');
  my $container     = exists $self->{'container'}{'ref'} ? $self->{'container'}{'ref'} : $self->{'container'};

  my $y             = 0;
  my $h             = 8;

  my %highlights;
  @highlights{$self->highlights} = ();    # build hashkeys of highlight list

  my @bitmap        = undef;
  my $colours       = $self->colours();

  my $fontname      = "Tiny";
  my $pix_per_bp    = $Config->transform->{'scalex'};
  my $_w            = $Config->texthelper->width($fontname) / $pix_per_bp;
  my $_h            = $Config->texthelper->height($fontname);
  my $bitmap_length = $Config->image_width(); #int($Config->container_width() * $pix_per_bp);

  my $strand        = $self->strand();
  my $length        = $container->length;
  my $transcript_drawn = 0;

  my $gene_drawn = 0;
 
  my $compara = $Config->{'compara'};
  my $link    = $compara ? $Config->get('_settings','opt_join_transcript') : 0;
  my $join_col = 'blue';
  my $join_z   = -10;
  foreach my $gene ( @{$self->features()} ) { # For alternate splicing diagram only draw transcripts in gene
    my $gene_strand = $gene->strand;
    my $gene_stable_id = $gene->stable_id;
    next if $gene_strand != $strand and $strand_flag eq 'b';
    $gene_drawn = 1;
## Get all the exons which overlap the region for this gene....
    my @exons = map { $_->start > $length || $_->end < 1 ? () : $_ } map { @{$_->get_all_Exons()} } @{$gene->get_all_Transcripts()};
    next unless @exons;

    my $Composite = new Sanger::Graphics::Glyph::Composite({'y'=>$y,'height'=>$h});
       $Composite->{'href'} = $self->gene_href( $gene, %highlights );
       $Composite->{'zmenu'} = $self->gene_zmenu( $gene ) unless $Config->{'_href_only'};
    my($colour, $hilight) = $self->gene_colour( $gene, $colours, %highlights );

    $colour ||= 'black';
    my $Composite2 = new Sanger::Graphics::Glyph::Composite({'y'=>$y,'height'=>$h});
    foreach my $exon (@exons) {
      my $s = $exon->start;
      my $e = $exon->end;
      $s = 1 if $s < 0;
      $e = $length if $e>$length;
      $transcript_drawn = 1;
      $Composite2->push(new Sanger::Graphics::Glyph::Rect({
        'x' => $s-1, 'y' => $y, 'width' => $e-$s+1,
        'height' => $h, 'colour'=>$colour, 'absolutey' => 1
      }));
    }
    my $start = $gene->start < 1 ? 1 : $gene->start;;
    my $end   = $gene->end   > $length ? $length : $gene->end;
    $Composite2->push(new Sanger::Graphics::Glyph::Rect({
      'x' => $start, 'width' => $end-$start+1,
      'height' => 0, 'y' => int($y+$h/2), 'colour' => $colour, 'absolutey' =>1,
    }));
    # Calculate and draw the coding region of the exon
    # only draw the coding region if there is such a region
    if($self->can('join')) {
      my @tags;
         @tags = $self->join( $gene->stable_id ) if $gene && $gene->can( 'stable_id' );
      foreach (@tags) {
        $self->join_tag( $Composite2, $_, 0, $self->strand==-1 ? 0 : 1, 'grey60' );
        $self->join_tag( $Composite2, $_, 1, $self->strand==-1 ? 0 : 1, 'grey60' );
      }
    }
    if( $link && ( $compara eq 'primary' || $compara eq 'secondary' )) {
      if( $gene_stable_id ) {
        if( $Config->{'previous_species'} ) {
          foreach my $msid ( $self->get_homologous_gene_ids( $gene_stable_id, $Config->{'previous_species'} ) ) {
            $self->join_tag( $Composite2, $Config->{'slice_id'}."#$gene_stable_id#$msid", 0.5, 0.5 , $join_col, 'line', $join_z ) 
          } 
        }
        if( $Config->{'next_species'} ) {
          foreach my $msid ( $self->get_homologous_gene_ids( $gene_stable_id, $Config->{'next_species'} ) ) {
            $self->join_tag( $Composite2, ($Config->{'slice_id'}+1)."#$msid#$gene_stable_id", 0.5, 0.5 , $join_col, 'line', $join_z ) 
          } 
        }
      }
    }

    $Composite->push($Composite2);
    my $bump_height = $h + 2;
    if( $Config->{'_add_labels'} ) {
      if(my $text_label = $self->gene_text_label($gene) ) {
        my @lines = split "\n", $text_label;
        $lines[0] = "<- $lines[0]" if $gene_strand < 1;
        $lines[0] = $lines[0].' ->' if $gene_strand >= 1;
        for( my $i=0; $i<@lines; $i++ ){
          my $line = $lines[$i];
          $Composite->push( new Sanger::Graphics::Glyph::Text({
            'x'         => $Composite->x(),
            'y'         => $y + $h + ($i*$_h) + 2,
            'height'    => $_h,
            'width'     => $_w * length(" $line "),
            'font'      => $fontname,
            'colour'    => $colour,
            'text'      => $line,
            'absolutey' => 1,
          }));
          $bump_height += $_h;
        }
      }
    }

  ########## bump it baby, yeah! bump-nology!
    my $bump_start = int($Composite->x * $pix_per_bp);
       $bump_start = 0 if ($bump_start < 0);
    my $bump_end = $bump_start + int($Composite->width * $pix_per_bp)+1;
       $bump_end = $bitmap_length if $bump_end > $bitmap_length;
    my $row = & Sanger::Graphics::Bump::bump_row( $bump_start, $bump_end, $bitmap_length, \@bitmap);
      ########## shift the composite container by however much we're bumped
    $Composite->y($Composite->y() - $strand * $bump_height * $row);
    $Composite->colour($hilight) if defined $hilight;
    $self->push($Composite);
  }

  if($transcript_drawn) {
    my ($key, $priority, $legend) = $self->legend( $colours );
    # define which legend_features should be displayed
    # this is being used by GlyphSet::gene_legend
    $Config->{'legend_features'}->{$key} = {
      'priority' => $priority,
      'legend'   => $legend
    } if defined($key);
  } elsif( $Config->get('_settings','opt_empty_tracks')!=0) {
    $self->errorTrack( "No ".$self->error_track_name()." in this region" );
  }
}

sub get_homologous_gene_ids {
  my( $self, $gene_id, $species ) = @_;
  my $compara_db = $self->{'container'}->adaptor->db->get_db_adaptor('compara');
  my $ma = $compara_db->get_MemberAdaptor;
  my $qy_member = $ma->fetch_by_source_stable_id("ENSEMBLGENE",$gene_id);
  return () unless (defined $qy_member);
  my $ha = $compara_db->get_HomologyAdaptor;
  my @homologues;
  foreach my $homology (@{$ha->fetch_by_Member_paired_species($qy_member, $species)}){
    foreach my $member_attribute (@{$homology->get_all_Member_Attribute}) {
      my ($member, $attribute) = @{$member_attribute};
      next if ($member->stable_id eq $qy_member->stable_id);
      push @homologues, $member->stable_id;
    }
  }
  return @homologues;
}

sub get_homologous_peptide_ids_from_gene {
  my( $self, $gene_id, $species ) = @_;
  my $compara_db = $self->{'container'}->adaptor->db->get_db_adaptor('compara');
  my $ma = $compara_db->get_MemberAdaptor;
  my $qy_member = $ma->fetch_by_source_stable_id("ENSEMBLGENE",$gene_id);
  return () unless (defined $qy_member);
  my $ha = $compara_db->get_HomologyAdaptor;
  my @homologues;
  my $STABLE_ID = undef;
  my $peptide_id = undef;
  foreach my $homology (@{$ha->fetch_by_Member_paired_species($qy_member, $species)}){
    foreach my $member_attribute (@{$homology->get_all_Member_Attribute}) {
      my ($member, $attribute) = @{$member_attribute};
      if( $member->stable_id eq $qy_member->stable_id ) {
        unless( $STABLE_ID) {
          my $T = $ma->fetch_by_dbID( $peptide_id = $attribute->peptide_member_id );
          $STABLE_ID = $T->stable_id;
        }
      } else {
        push @homologues, $attribute->peptide_member_id;
      }
    }
  }
  return ( $STABLE_ID, $peptide_id, \@homologues );
}

sub get_homologous_peptide_ids {
  my( $self, $gene_id, $species ) = @_;
  my $compara_db = $self->{'container'}->adaptor->db->get_db_adaptor('compara');

  my $peptide_sql = qq(select m.stable_id
  from homology_member as hm, member as m, source as s, genome_db as gd,
       homology_member as ohm, member as om, genome_db as ogd
 where m.member_id = hm.peptide_member_id and hm.homology_id = ohm.homology_id and
       ohm.peptide_member_id = om.member_id and
       om.source_id = s.source_id and m.source_id = s.source_id and s.source_name = 'ENSEMBLPEP' and
       m.genome_db_id = gd.genome_db_id  and gd.name = ? and
       om.genome_db_id = ogd.genome_db_id  and ogd.name = ? and
        om.stable_id = ?);

  ( my $current_species = $self->{'container'}{_config_file_name_} ) =~ s/_/ /g;
  ( my $other_species   = $species )                                 =~ s/_/ /g;
  my $results = $compara_db->prepare( $peptide_sql );
     $results->execute( $other_species, $current_species, $gene_id );

  return map {@$_} @{$results->fetchall_arrayref};
}

sub expanded_init {
  my ($self) = @_;
  my $type = $self->check();
  return unless defined $type;

  my $Config        = $self->{'config'};
  my $strand_flag   = $Config->{'str'};
  my $container     = exists $self->{'container'}{'ref'} ? $self->{'container'}{'ref'} : $self->{'container'};
  my $target        = $Config->{'_draw_single_Transcript'};
  my $target_gene   = $Config->{'geneid'};
    
  my $y             = 0;
  my $h             = $target ? 30 : 8;   #Single transcript mode - set height to 30 - width to 8!
    
  my %highlights;
  @highlights{$self->highlights} = ();    # build hashkeys of highlight list

  my @bitmap        = undef;
  my $colours       = $self->colours();

  my $fontname      = "Tiny";    
  my $pix_per_bp    = $Config->transform->{'scalex'};
  my $bitmap_length = $Config->image_width(); #int($Config->container_width() * $pix_per_bp);

  my $strand  = $self->strand();
  my $length  = $container->length;
  my $transcript_drawn = 0;
    
  my $_w            = $Config->texthelper->width($fontname) / $pix_per_bp;
  my $_h            = $Config->texthelper->height($fontname);

  my $compara = $Config->{'compara'};
  my $link    = $compara ? $Config->get('_settings','opt_join_transcript') : 0;
  
  foreach my $gene ( @{$self->features()} ) { # For alternate splicing diagram only draw transcripts in gene
    my $gene_strand = $gene->strand;
    my $gene_stable_id = $gene->can('stable_id') ? $gene->stable_id() : undef;
    next if $gene_strand != $strand and $strand_flag eq 'b'; # skip features on wrong strand....
    next if $target_gene && $gene_stable_id ne $target_gene;
    my %TAGS = (); my @GENE_TAGS;
	my $tsid;
    if( $link && ( $compara eq 'primary' || $compara eq 'secondary' ) && $link ) {
      if( $gene_stable_id ) {
        my $alt_alleles = $gene->get_all_alt_alleles();

		#vega stuff to link alt-alleles on longest transcript
		my $alltrans = $gene->get_all_Transcripts;
		my @s_alltrans = sort {$a->length <=> $b->length} @{$alltrans};
		my $long_trans = pop @s_alltrans;
		$tsid = $long_trans->stable_id;
		my @long_trans;
		foreach my $gene (@{$alt_alleles}) {
			my $vtranscripts = $gene->get_all_Transcripts;
			my @sorted_trans = sort {$a->length <=> $b->length} @{$vtranscripts};
			push @long_trans,(pop @sorted_trans);
		}
			
        if( $Config->{'previous_species'} ) {
          my( $psid, $pid, $href ) = $self->get_homologous_peptide_ids_from_gene( $gene_stable_id, $Config->{'previous_species'} );
          push @{$TAGS{$psid}}, map { $Config->{'slice_id'}. "#$_#$pid" } @{$href};
		  push @GENE_TAGS, map { $Config->{'slice_id'}. "=@{[$_->stable_id]}=$tsid" } @long_trans;	
        }
        if( $Config->{'next_species'} ) {
          my( $psid, $pid, $href ) = $self->get_homologous_peptide_ids_from_gene( $gene_stable_id, $Config->{'next_species'} );
          push @{$TAGS{$psid}}, map { ($Config->{'slice_id'}+1). "#$pid#$_" } @{$href};
          push @GENE_TAGS, map { ($Config->{'slice_id'}+1). "=$tsid=@{[$_->stable_id]}" } @long_trans;
        }
      }
    }
    my $join_col1 = 'blue';
	my $join_col2 = 'chocolate1';
    my $join_z   = -10;

    foreach my $transcript (@{$gene->get_all_Transcripts()}) {
      next if $transcript->start > $length ||  $transcript->end < 1;
      my @exons = sort {$a->start <=> $b->start} grep { $_ } @{$transcript->get_all_Exons()};#sort exons on their start coordinate 

      #$self->datadump( $gene_stable_id, \%TAGS );
      # Skip if no exons for this transcript
      next if (@exons == 0);
      # If stranded diagram skip if on wrong strand
      next if (@exons[0]->strand() != $strand && $self->{'do_not_strand'}!=1 );
      # For exon_structure diagram only given transcript
      next if $target && ($transcript->stable_id() ne $target);

      $transcript_drawn=1;        
      my $Composite = new Sanger::Graphics::Glyph::Composite({'y'=>$y,'height'=>$h});
         $Composite->{'href'} = $self->href( $gene, $transcript, %highlights );
         $Composite->{'zmenu'} = $self->zmenu( $gene, $transcript ) unless $Config->{'_href_only'};
      my($colour, $hilight) = $self->colour( $gene, $transcript, $colours, %highlights );
      my $coding_start = defined ( $transcript->coding_region_start() ) ? $transcript->coding_region_start :  -1e6;
      my $coding_end   = defined ( $transcript->coding_region_end() )   ? $transcript->coding_region_end :    -1e6;
      my $Composite2 = new Sanger::Graphics::Glyph::Composite({'y'=>$y,'height'=>$h});
      if( $transcript->translation ) { 
        foreach( @{$TAGS{$transcript->translation->stable_id}||[]} ) { 
          $self->join_tag( $Composite2, $_, 0.5, 0.5 , $join_col1, 'line', $join_z ) ;
        }
      }
      foreach( @GENE_TAGS) {
		  if ($transcript->stable_id eq $tsid) {
			  $self->join_tag( $Composite2, $_, 0.5, 0.5 , $join_col2, 'line', $join_z ) ;
		  }
      }
      for(my $i = 0; $i < @exons; $i++) {
        my $exon = @exons[$i];
        next unless defined $exon; #Skip this exon if it is not defined (can happen w/ genscans) 
        my $next_exon = ($i < $#exons) ? @exons[$i+1] : undef; #First draw the exon
              # We are finished if this exon starts outside the slice
        last if $exon->start() > $length;
        my($box_start, $box_end);
            # only draw this exon if is inside the slice
        if($exon->end() > 0 ) { #calculate exon region within boundaries of slice
          $box_start = $exon->start();
          $box_start = 1 if $box_start < 1 ;
          $box_end = $exon->end();
          $box_end = $length if$box_end > $length;
          if($box_start < $coding_start || $box_end > $coding_end ) {
                      # The start of the transcript is before the start of the coding
                      # region OR the end of the transcript is after the end of the
                      # coding regions.  Non coding portions of exons, are drawn as
                      # non-filled rectangles
                      #Draw a non-filled rectangle around the entire exon
            $Composite2->push(new Sanger::Graphics::Glyph::Rect({
              'x'         => $box_start -1 ,
              'y'         => $y,
              'width'     => $box_end-$box_start +1,
              'height'    => $h,
              'bordercolour' => $colour,
              'absolutey' => 1,
             }));
           } 
           # Calculate and draw the coding region of the exon
           my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
           my $filled_end   = $box_end > $coding_end  ? $coding_end   : $box_end;
                  # only draw the coding region if there is such a region
           if( $filled_start <= $filled_end ) {
            #Draw a filled rectangle in the coding region of the exon
              $Composite2->push( new Sanger::Graphics::Glyph::Rect({
                'x' => $filled_start -1,
                'y'         => $y,
                'width'     => $filled_end - $filled_start + 1,
                'height'    => $h,
                'colour'    => $colour,
                'absolutey' => 1
              }));
          }
        } #we are finished if there is no other exon defined
        last unless defined $next_exon;

        my $intron_start = $exon->end() + 1;   #calculate the start and end of this intron
        my $intron_end = $next_exon->start()-1;
        next if($intron_end < 0);   #grab the next exon if this intron is before the slice
        last if($intron_start > $length);      #we are done if this intron is after the slice
          
        #calculate intron region within slice boundaries
        $box_start = $intron_start < 1 ? 1 : $intron_start;
        $box_end   = $intron_end > $length ? $length : $intron_end;
        my $intron;
        if( $box_start == $intron_start && $box_end == $intron_end ) {
          # draw an wholly in slice intron
          $Composite2->push(new Sanger::Graphics::Glyph::Intron({
            'x'         => $box_start -1,
            'y'         => $y,
            'width'     => $box_end-$box_start + 1,
            'height'    => $h,
            'colour'    => $colour,
            'absolutey' => 1,
            'strand'    => $strand,
          }));
        } else { 
            # else draw a "not in slice" intron
          $Composite2->push(new Sanger::Graphics::Glyph::Line({
            'x'         => $box_start -1 ,
            'y'         => $y+int($h/2),
            'width'     => $box_end-$box_start + 1,
            'height'    => 0,
            'absolutey' => 1,
            'colour'    => $colour,
            'dotted'    => 1,
          }));
        } # enf of intron-drawing IF
      }
      if($self->can('join')) {
        my @tags;
           @tags = $self->join( $gene->stable_id ) if $gene && $gene->can('stable_id');
        foreach (@tags) {
          $self->join_tag( $Composite2, $_, 0, $self->strand==-1 ? 0 : 1, 'grey60' );
          $self->join_tag( $Composite2, $_, 1, $self->strand==-1 ? 0 : 1, 'grey60' );
        }
      }
      $Composite->push($Composite2);
      my $bump_height = 1.5 * $h;
      if( $Config->{'_add_labels'} ) {
        if(my $text_label = $self->text_label($gene, $transcript) ) {
	  my @lines = split "\n", $text_label;
          my($font_w_bp, $font_h_bp) = $Config->texthelper->px2bp($fontname);
          my @lines = split "\n", $text_label;
          for( my $i=0; $i<@lines; $i++ ){
            my $line = $lines[$i];
            $Composite->push( new Sanger::Graphics::Glyph::Text({
              'x'         => $Composite->x(),
              'y'         => $y + $h + ($i*$_h) + 2,
              'height'    => $_h,
              'width'     => $_w * length(" $line "),
              'font'      => $fontname,
              'colour'    => $colour,
              'text'      => $line,
              'absolutey' => 1,
            }));
            $bump_height += $_h;
	  }
        }
      }

      ########## bump it baby, yeah! bump-nology!
      my $bump_start = int($Composite->x * $pix_per_bp);
         $bump_start = 0 if ($bump_start < 0);
      my $bump_end = $bump_start + int($Composite->width * $pix_per_bp)+1;
         $bump_end = $bitmap_length if $bump_end > $bitmap_length;
      my $row = & Sanger::Graphics::Bump::bump_row( $bump_start, $bump_end, $bitmap_length, \@bitmap);
      ########## shift the composite container by however much we're bumped
      $Composite->y($Composite->y() - $strand * $bump_height * $row);
      $Composite->colour($hilight) if(defined $hilight && !defined $target);
      $self->push($Composite);
        
      if($target) {     
        # check the strand of one of the transcript's exons
        my ($trans_exon) = @{$transcript->get_all_Exons};
        if($trans_exon->strand() == 1) {
          $self->push(new Sanger::Graphics::Glyph::Line({
            'x'         => 0,
            'y'         => -4,
            'width'     => $length,
            'height'    => 0,
            'absolutey' => 1,
            'colour'    => $colour
          }));
          $self->push( new Sanger::Graphics::Glyph::Poly({
            'points' => [
               $length - 4/$pix_per_bp,-2,
               $length                ,-4,
               $length - 4/$pix_per_bp,-6],
            'colour'    => $colour,
            'absolutey' => 1,
          }));
        } else {
          $self->push(new Sanger::Graphics::Glyph::Line({
            'x'         => 0,
            'y'         => $h+4,
            'width'     => $length,
            'height'    => 0,
            'absolutey' => 1,
            'colour'    => $colour
          }));
          $self->push(new Sanger::Graphics::Glyph::Poly({
            'points'    => [ 4/$pix_per_bp,$h+6,
                             0,              $h+4,
                             4/$pix_per_bp,$h+2],
            'colour'    => $colour,
            'absolutey' => 1,
          }));
        }
      }  
    }
  }
  if($transcript_drawn) {
    my ($key, $priority, $legend) = $self->legend( $colours );
    # define which legend_features should be displayed
    # this is being used by GlyphSet::gene_legend
    $Config->{'legend_features'}->{$key} = {
      'priority' => $priority,
      'legend'   => $legend
    } if defined($key);
  } elsif( $Config->get('_settings','opt_empty_tracks')!=0) {
    $self->errorTrack( "No ".$self->error_track_name()." in this region" );
  }
}
1;
