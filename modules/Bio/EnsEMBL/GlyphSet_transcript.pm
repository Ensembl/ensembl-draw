package Bio::EnsEMBL::GlyphSet_transcript;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Intron;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Composite;
use Bio::EnsEMBL::Glyph::Line;
use Bump;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $HELP_LINK = $self->check();
    my $label = new Bio::EnsEMBL::Glyph::Text({
        'text'      => $self->my_label(),
        'font'      => 'Small',
        'absolutey' => 1,
        'href'      => qq[javascript:X=window.open(\'/$ENV{'ENSEMBL_SPECIES'}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#$HELP_LINK\',\'helpview\',\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\');X.focus();void(0)],

        'zmenu'     => {
            'caption'                     => 'HELP',
            "01:Track information..."     =>
qq[javascript:X=window.open(\\\'/$ENV{'ENSEMBL_SPECIES'}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#$HELP_LINK\\\',\\\'helpview\\\',\\\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\\\');X.focus();void(0)]
        }
    });
    $self->label($label);
#    $self->bumped( $self->{'config'}->get($HELP_LINK, 'dep')==0 ? 'no' : 'yes' );
}

sub my_label {
    my $self = shift;
    return 'Missing label';
}


sub colours {  
  # Implemented by subclass 
  return {}; 
}

sub text_label {
  # Implemented by subclass
  return undef;
}

#
# Returns the type of transcript this is as a string
#
sub features {  
  my $self = shift;

  $self->warn("GlyphSet_transcript->features is deprecated");
  return []; 
}

sub transcript_type {
  my $self = shift;

 # Implemented by subclass 
 $self->throw("transcript_type not implemented by subclass of Glyphset_transcript\n");
}
  
sub _init {
    my ($self) = @_;

    my $type = $self->check();
    return unless defined $type;

    my $Config        = $self->{'config'};
    my $container     = $self->{'container'};
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
    my $bitmap_length = int($Config->container_width() * $pix_per_bp);
 
    # Get all the genes on this slice
    my @genes = 
      $container->get_Genes_by_type($self->transcript_type()); 
    my $strand  = $self->strand();

    my $transcript_drawn = 0;
    
    foreach my $gene (@genes) {
      # For alternate splicing diagram only draw transcripts in gene
      next if $target_gene && ($gene->stable_id() ne $target_gene);

      foreach my $transcript ($gene->get_all_Transcripts()) {
	print STDERR "DRAWING TRANSCRIPT: $transcript->stable_id()\n";

	my @exons = $transcript->get_all_Exons();
	# Skip if no exons for this transcript
	next if (@exons == 0);
	# If stranded diagram skip if on wrong strand
	next if (@exons[0]->strand() != $strand);
	# For exon_structure diagram only given transcript
	next if $target && ($transcript->stable_id() ne $target);

        $transcript_drawn=1;        
        my $Composite = new 
	  Bio::EnsEMBL::Glyph::Composite({'y'=>$y,'height'=>$h});
        
        $Composite->{'href'}  = $self->href( $gene, $transcript );
	
	unless( $Config->{'_href_only'} ) {
	  $Composite->{'zmenu'} = $self->zmenu( $gene, $transcript );
	} 
	
	my($colour, $hilight) = 
	  $self->colour( $gene, $transcript, $colours, %highlights );

	#Calculate start and end of transcript region in slice coords
	my $transcript_start = $transcript->start_exon()->start();
	my $transcript_end = $transcript->end_exon()->end();

        #my $end = $transcript_start - 1;
        #my $start = 0;
        my $coding_start = $transcript->coding_start() || $transcript_start;
        my $coding_end   = $transcript->coding_end()   || $transcript_end;

        for(my $i = 0; $i < @exons; $i++) {
	  my $exon = @exons[$i];
	  my $next_exon = ($i+1 < @exons) ? @exons[$i+1] : undef;
	    
	  #First draw the exon
	  # We are finished if this exon starts outside the slice
	  last if $exon->start() > $container->length();

	  my($box_start, $box_end);

	  # only draw this exon if is inside the slice
	  if($exon->end() > 0) {
	    #calculate exon region within boundaries of slice
	    $box_start = $exon->start();
	    if($box_start < 1) {
	      $box_start = 1;
	    }
	    $box_end = $exon->end();
	    if($box_end > $container->length()) {
	      $box_end = $container->length();
	    }
	  
	    if($box_start < $coding_start || $box_end > $coding_end ) {
	      # The start of the transcript is before the start of the coding
	      # region OR the end of the transcript is after the end of the
	      # coding regions.  Non coding portions of exons, are drawn as
	      # non-filled rectangles

	      #Draw a non-filled rectangle around the entire exon
	      my $rect = new Bio::EnsEMBL::Glyph::Rect({
                        'x'         => $box_start,
                        'y'         => $y,
                        'width'     => $box_end-$box_start,
                        'height'    => $h,
                        'bordercolour' => $colour,
                        'absolutey' => 1,
		       });
	      $Composite->push($rect);

	      #Calculate the start and end of the "filled" coding region
	      my $filled_start = $box_start;
	      if($filled_start < $coding_start) {
		$filled_start = $coding_start;
	      }
	      my $filled_end = $box_end;
	      if($filled_end > $coding_end) {
		$filled_end = $coding_end;
	      }

	      #Draw a filled rectangle in the coding region of the exon
	      $rect = new Bio::EnsEMBL::Glyph::Rect({
                        'x'         => $filled_start,
                        'y'         => $y,
                        'width'     => $filled_end - $filled_start,
                        'height'    => $h,
                        'colour'    => $colour,
                        'absolutey' => 1,
                    });
	      $Composite->push($rect);
	    } else {
	      #This entire exon is coding, draw it as a filled rectangle
	      my $rect = new Bio::EnsEMBL::Glyph::Rect({
                        'x'         => $box_start,
                        'y'         => $y,
                        'width'     => $box_end-$box_start,
                        'height'    => $h,
                        'colour'    => $colour,
                        'absolutey' => 1,
                    });
	      $Composite->push($rect);
	    }
	  }
	  
	  #we are finished if this exon is the last exon in the translation
	  last if($exon->dbID() == 
		      $transcript->translation()->last_exon()->dbID());
	  
	  #we are finished if there is no other exon defined
	  last unless defined $next_exon;

	  #calculate the start and end of this intron
	  my $intron_start = $exon->end();
	  my $intron_end = $next_exon->start();

	  #grab the next exon if this intron is before the slice
	  next if($intron_end < 0);
	  
	  #we are done if this intron is after the slice
	  last if($intron_start > $container->length());
	  
	  #calculate intron region within slice boundaries
	  $box_start = $intron_start;
	  if($box_start < 1) {
	    $box_start = 1;
	  }
	  $box_end = $intron_end;
	  if($intron_end > $container->length()) {
	    $box_end = $container->length();
	  }

	  my $intron;

          if( $box_start == $intron_start && $box_end == $intron_end ) { 
	    # draw an wholly in slice intron
	    $intron = new Bio::EnsEMBL::Glyph::Intron({
                    'x'         => $box_start,
                    'y'         => $y,
                    'width'     => $box_end-$box_start,
                    'height'    => $h,
                    'colour'    => $colour,
                    'absolutey' => 1,
                    'strand'    => $strand,
                });
	  } else { 
	      # else draw a "not in slice" intron
	      intron = new Bio::EnsEMBL::Glyph::Line({
                     'x'         => $box_start,
                     'y'         => $y+int($h/2),
                     'width'     => $box_end-$box_start,
                     'height'    => 0,
                     'absolutey' => 1,
                     'colour'    => $colour,
                     'dotted'    => 1,
                 });
	    }
	  $Composite->push($intron);
        }
                
        my $bump_height = 1.5 * $h;
        if( $Config->{'_add_labels'} ) {
	  if(my $text_label = $self->text_label($gene, $transcript) ) {
	    my($font_w_bp, $font_h_bp) = $Config->texthelper->px2bp($fontname);
	    my $width_of_label = $font_w_bp * 1.15 * (length($text_label) + 1);
	    my $tglyph = new Bio::EnsEMBL::Glyph::Text({
                    'x'         => $Composite->x(),
                    'y'         => $y+$h+2,
                    'height'    => $font_h_bp,
                    'width'     => $width_of_label,
                    'font'      => $fontname,
                    'colour'    => $colour,
                    'text'      => $text_label,
                    'absolutey' => 1,
                });
	    $Composite->push($tglyph);
	    $bump_height = 1.7 * $h + $font_h_bp;
	  }
        }
 
        ########## bump it baby, yeah! bump-nology!
        my $bump_start = int($Composite->x * $pix_per_bp);
        $bump_start = 0 if ($bump_start < 0);
    
        my $bump_end = $bump_start + int($Composite->width * $pix_per_bp)+1;
        if ($bump_end > $bitmap_length) { $bump_end = $bitmap_length };
    
        my $row = &Bump::bump_row(
            $bump_start,
            $bump_end,
            $bitmap_length,
            \@bitmap
        );
    
        ########## shift the composite container by however much we're bumped
        $Composite->y($Composite->y() - $strand * $bump_height * $row);
        $Composite->colour($hilight) if(defined $hilight && !defined $target);
        $self->push($Composite);
        
        if($target) {        
	  if($transcript->strand() == 1) {
	    my $clip1 = new Bio::EnsEMBL::Glyph::Line({
                   'x'         => 1,
                   'y'         => -4,
                   'width'     => $container->length(),
                   'height'    => 0,
                   'absolutey' => 1,
                   'colour'    => $colour
                });
	    $self->push($clip1);
	    $clip1 = new Bio::EnsEMBL::Glyph::Poly({
                	'points' => [$container->length() - 4/$pix_per_bp,-2,
                                     $container->length()                ,-4,
                                     $container->length() - 4/$pix_per_bp,-6],
			'colour'    => $colour,
                	'absolutey' => 1,
                });
	    $self->push($clip1);
	  } else {
	    my $clip1 = new Bio::EnsEMBL::Glyph::Line({
                   'x'         => 1,
                   'y'         => $h+4,
                   'width'     => $container->length(),
                   'height'    => 0,
                   'absolutey' => 1,
                   'colour'    => $colour
                });
	    $self->push($clip1);
	    $clip1 = new Bio::EnsEMBL::Glyph::Poly({
                    'points'    => [1+4/$pix_per_bp,$h+6,
                                    1,              $h+4,
                                    1+4/$pix_per_bp,$h+2],
		    'colour'    => $colour,
                    'absolutey' => 1,
                });
	    $self->push($clip1);
	  }
        }
      }
      
      if($transcript_drawn) {
        my ($key, $priority, $legend) = $self->legend( $colours );
        $Config->{'legend_features'}->{$key} = {
            'priority' => $priority,
            'legend'   => $legend
	} if defined($key);
      } elsif( $Config->get('_settings','opt_empty_tracks')!=0) {
        $self->errorTrack( "No ".$self->error_track_name()." in this region" );
      }
    }
  }

1;
