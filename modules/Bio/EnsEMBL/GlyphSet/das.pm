package Bio::EnsEMBL::GlyphSet::das;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Composite;
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Intron;
use Sanger::Graphics::Bump;
use Bio::EnsEMBL::Glyph::Symbol::box;	# default symbol for features
use Data::Dumper;
use POSIX qw(floor);
use HTML::Entities;

sub init_label {
  my ($self) = @_;
  return if( defined $self->{'config'}->{'_no_label'} );

  my $params;
  foreach my $param (CGI::param()) {
    next if ($param eq 'add_das_source');
    if (defined(my $v = CGI::param($param))) {
	    if (ref($v) eq 'ARRAY') {
		foreach my $w (@$v) {
		    $params .= ";$param=$w";
		}
	    } else {
		$params .= ";$param=$v";
	    }
	}
    }

    my $script = $ENV{ENSEMBL_SCRIPT};
    my $species = $ENV{ENSEMBL_SPECIES};
    my $helplink = (defined($self->{'extras'}->{'helplink'})) ?  $self->{'extras'}->{'helplink'} :  "/$species/helpview?se=1;kw=$ENV{'ENSEMBL_SCRIPT'}#das";
    
    my $URL = "";
    if ($self->das_name =~ /^managed_extdas_(.*)$/){
	$URL = qq(javascript:X=window.open(\'/$species/dasconfview?_das_edit=$1;conf_script=$script$params\',\'dassources\',\'left=10,top=10,resizable,scrollbars=yes\');X.focus();void(0));
    } else {
	if ($self->{'extras'}{'homepage'}){
	    $URL = $self->{'extras'}{'homepage'};
	} else {
	    $URL = qq(javascript:X=window.open(\'$helplink\',\'helpview\',\'left=20,top=20,resizable,scrollbars=yes\');X.focus();void(0)) ;
	}
    }

    my $track_label = $self->{'extras'}->{'label'} || $self->{'extras'}->{'caption'} || $self->{'extras'}->{'name'};
    $track_label =~ s/^(managed_|managed_extdas)//;

  my( $fontname, $fontsize ) = $self->get_font_details( 'label' );
  my @res = $self->get_text_width( 0, $track_label, '', 'font'=>$fontname, 'ptsize' => $fontsize );
  $self->label( new Sanger::Graphics::Glyph::Text({
    'text'      => $track_label,
    'colour'    => 'contigblue2',
    'height'    => $res[3],
    'absolutey' => 1,
    'font'      => $fontname,
    'ptsize'    => $fontsize,
    'href'      => $URL,
	'zmenu'     => $self->das_name  =~/^managed_extdas/ ?
	        { 'caption' => 'Configure', '01:Advanced configuration...' => $URL } :
                { 'caption' => 'HELP',      '01:Track information...'      => $URL }
    }) );
}


# Render ungrouped features

sub RENDER_simple {

  my( $self, $configuration ) = @_;
  my $empty_flag = 1;

  # flag to indicate if not all features have been displayed 
  my $more_features = 0;
  my $label_height = 0;
  my $total_track_height = 0;

  foreach my $f( sort { 
    my $c=0;
    my $astyle = $self->get_featurestyle ($a, $configuration);
    my $bstyle = $self->get_featurestyle ($b, $configuration);
    $c = ($astyle->{'attrs'}{'zindex'}||0) <=> ($bstyle->{'attrs'}{'zindex'}||0) if exists(${$astyle}{'attrs'}{'zindex'}) or exists(${$bstyle}{'attrs'}{'zindex'});
    $c==0 ? $a->das_start() <=> $b->das_start()  : $c;
  } @{$configuration->{'features'}} ){



    # Handle DAS errors first
    if($f->das_type_id() eq '__ERROR__') {
      $self->errorTrack(
        'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->das_id.')'
      );
      return -1 ;   # indicates no features drawn because of DAS error
    }
    
    $empty_flag &&= 0; # We have a feature (its on one of the strands!)

    # Skip features that aren't on the current strand, if we're doing both
    # strands
    next if $configuration->{'strand'} eq 'b' && ( $f->strand() !=1 && $configuration->{'STRAND'}==1 || $f->strand() ==1 && $configuration->{'STRAND'}==-1);

    my $ID    = $f->das_id;
    my $label = $f->das_feature_label || $ID;
    my @res = $self->get_text_width( 0, $ID, '', 'font'=>$self->{'fontname_i'}, 'ptsize' => $self->{'fontsize_i'} );
    my $label_length = $configuration->{'labelling'} * $res[2]/$self->{'pix_per_bp'};
    my $row = 0; # bumping row

    # keep within the window we're drawing
    my $START = $f->das_start() < 1 ? 1 : $f->das_start();
    my $END   = $f->das_end()   > $configuration->{'length'}  ? $configuration->{'length'} : $f->das_end();

    # bump if required
    if( $configuration->{'depth'} > 0 ) {
      $row = $self->bump( $START, $END, $label_length, $configuration->{'depth'} );
      if( $row < 0 ) { ## SKIP IF BUMPED...
	  $more_features ++;
	  next;
      }
    } 

    my ($href, $zmenu ) = $self->zmenu( $f );
    my $Composite = new Sanger::Graphics::Glyph::Composite({
      'y'         => 0,
      'x'         => $START-1,
      'absolutey' => 1,
      'zmenu'     => $zmenu,
    });
    $Composite->{'href'} = $href if $href;

    my $style = $self->get_featurestyle ($f, $configuration);
    my $styledata = $style->{'attrs'};  # style attributes for this feature
    my $glyph_height = $styledata->{'height'};
    my $colour = $styledata->{'colour'};
    my $row_height = $configuration->{'h'};
    my $glyph_symbol = $style->{'glyph'};

    # Draw label first, so we can get the label_height to use in poly offsets
    $label_height =$self->feature_label( $Composite, 
					    $label, 
					    $colour, 
					    $glyph_height,
					    $row_height,
					    $START, 
					    $END );

    my $y_offset = - $configuration->{'tstrand'}*($row_height+2+$label_height) * $row;
    
    # Special case for viewing summary non-positional features (i.e. gene
    # DAS features on contigview) Just display a gene-wide line with a link
    # to geneview where all annotations can be viewed

    if( ( "@{[$f->das_type_id()]}" ) =~ /(summary)/i ) { ## INFO Box
	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

	# override to draw this as a span
	my $oldglyph = $style->{'glyph'};
	$style->{'glyph'} = 'box';
   
	# Change zmenu to summary menu
	my $smenu = $self->smenu($f);
	$Composite->{zmenu} = $smenu;

	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
	$Composite->push($symbol->draw);
	# put the style back to how it was
	$style->{'glyph'} = $oldglyph;
  } 
  else {
    # make clickable box to anchor zmenu
    $Composite->push( new Sanger::Graphics::Glyph::Space({
    	'x'         => $START-1,
    	'y'         => 0,
	'width'     => $END-$START+1,
	'height'    => $glyph_height,
	'absolutey' => 1
    }) );

    my $style = $self->get_featurestyle($f, $configuration);
    my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

    # Draw feature symbol
    my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
    $self->push($symbol->draw);

  }
    $total_track_height = $y_offset if ($total_track_height < $y_offset);
    # Offset label coords by which row we're on
    $Composite->y($Composite->y() + $y_offset);

    $self->push( $Composite );
  } # END loop over features

  $self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' ) if $empty_flag;

    if($more_features) {
    
    # There are more features to display : show the note
      my $yx =   2 * ($configuration->{'h'} + $label_height) + $total_track_height;



      my $ID = 'There are more '.$self->{'extras'}->{'label'}.' features in this region. Increase source depth to view them all ';
      $self->errorTrack($ID, undef, $yx);
    }    

  return $empty_flag ? 0 : 1 ;

}   # END RENDER_simple


sub RENDER_grouped {
  my( $self, $configuration ) = @_; 
  my %grouped;

  my $old_end = -1e9;
  my $empty_flag = 1;
  my $label_height = 0;
  my $total_track_height = 0;

  ## Loop over features and hash into groups
  foreach my $f (@{$configuration->{'features'}}){
    # Handle DAS errors first
    if($f->das_type_id() eq '__ERROR__') {
      $self->errorTrack( 'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->das_id.')' );
      return -1; # indicates no features drawn because of DAS error
    }

    # Skip features that aren't on the current strand, if we're doing both
    # strands
    next if $configuration->{'strand'} eq 'b' && ( $f->strand() !=1 && $configuration->{'STRAND'}==1 || $f->strand() ==1 && $configuration->{'STRAND'}==-1);

    # build a hash of features, keyed by id if ungrouped, or G:group_id if
    # grouped

    if ($f->das_groups) {
	foreach my $group ($f->das_groups) {
	    my $key  = $group->{'group_label'} || $group->{'group_id'};
	    push @{$grouped{$key}}, $f;
	}
    } else {
	my $key = $f->das_id;
	next unless $key;
	push @{$grouped{$key}}, $f;
    }

    $empty_flag &&= 0; # We have at least one feature
  } # end group hashing

  if($empty_flag) {
    $self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' );
    return 0;	# indicates no features drawn, because no features there
  }

  # Flag to indicate if not all features got displayed due to bumping
  my $more_features = 0;

  # Loop over groups
  foreach my $group (values %grouped) {
    my $f = $group->[0];

    # Sort features in a group
    my @feature_group = sort { $a->das_start <=> $b->das_start } @$group;

    # Get start and end of group
    my $start = $feature_group[0]->das_start;
    my $end   = $feature_group[-1]->das_end;
    for my $ftmp (@feature_group){$end = $ftmp->das_end if $ftmp->das_end > $end} #in case of overlapping features
    
    # constrain to image window
    my $START = $start < 1 ? 1 : $start;
    my $END   = $end > $configuration->{'length'} ? $configuration->{'length'} : $end;

    # Compute the length of the label...
    my $ID    = $f->das_group_id || $f->das_feature_label || $f->das_feature_id;
    my $label = $f->das_group_label || $ID;
    $f->{grouped_by} = $label;
    # append number of features in group

    my $num_in_group = scalar @feature_group;
    if ($num_in_group > 1){
	$label .= "[$num_in_group]";
    }
    
    my @res = $self->get_text_width( 0, $ID, '', 'font'=>$self->{'fontname_i'}, 'ptsize' => $self->{'fontsize_i'} );
    my $label_length = $configuration->{'labelling'} * $res[2]/$self->{'pix_per_bp'};
    my $row = $configuration->{'depth'} > 0 ? $self->bump( $START, $end, $label_length, $configuration->{'depth'} ) : 0;

    if( $row < 0 ) { ## SKIP IF BUMPED...
	$more_features ++;
	next;
    }
    
    my $groupsize = scalar @feature_group;
    
    my( $href, $zmenu ) = $f->das_group_id ? $self->gmenu( $f, $groupsize ) : $self->zmenu( $f);


#    warn (Data::Dumper::Dumper($zmenu));

    my $Composite = new Sanger::Graphics::Glyph::Composite({
      'y'            => 0,
      'x'            => $START-1,
      'absolutey'    => 1,
      'zmenu'        => $zmenu,
    });
    $Composite->push( new Sanger::Graphics::Glyph::Space({
	'x'         => $START-1,
	'y'         => 0,
	'width'     => $END-$START+1,
	'height'    => $configuration->{'h'},
	'absolutey' => 1
    }) );

    $Composite->{'href'} = $href if $href;

    # fetch group style

    my $groupstyle = $self->get_groupstyle ($f, $configuration);
    my $group_height = $groupstyle->{'attrs'}{'height'};
    my $colour = $groupstyle->{'attrs'}{'colour'};
    my $row_height = $configuration->{'h'};

    # store a couple of style attributes that we might change.  We'll want to
    # change these back later (remember styles are references to the original
    # style data - change them, and they change for all features that use that
    # style). 
    my $orig_groupstyle_glyph = $groupstyle->{'glyph'};
    my $orig_groupstyle_line = $groupstyle->{'attrs'}{'style'};

    # Draw label
    $label_height =$self->feature_label( $Composite, 
					    $label, 
					    $colour, 
					    $row_height,
					    $row_height,
					    $START, 
					    $END 
					   );

    my $y_offset = - $configuration->{'tstrand'}*($row_height+2+$label_height) * $row;
    
    if( ( "@{[$f->das_group_type]} @{[$f->das_type_id()]}" ) =~ /(summary)/i) { 

	# Special case for viewing summary non-positional features (i.e. gene
	# DAS features on contigview) Just display a gene-wide line with a link
	# to geneview where all annotations can be viewed
#	my $f = shift @feature_group;
	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

	# override glyph to draw this as a span
	my $oldglyph = $style->{'glyph'};
	$style->{'glyph'} = 'box';
   
	# Change zmenu to summary menu
	my $smenu = $self->smenu($f);
	$Composite->{zmenu} = $smenu;

	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
#	$self->push($symbol->draw);
	$Composite->push($symbol->draw);

	# put the style back to how it was
	$style->{'glyph'} = $oldglyph;
	$self->push($Composite);
	next;
    } 

    if ( ( "@{[$f->das_group_type]} @{[$f->das_type_id()]}" ) =~ /(CDS|translation|transcript|exon)/i ) { 
	# Special case for displaying transcripts in a transcript style
	# without having group stylesheets, or provide intron features

	$groupstyle->{'glyph'} = 'line';
	$groupstyle->{'attrs'}{'style'} = 'intron';
	
    } 
    ## GENERAL GROUPED FEATURE!
    # first feature of group
    my $f = shift @feature_group;
    my $style = $self->get_featurestyle($f, $configuration);
    my $fdata = $self->get_featuredata($f, $configuration, $y_offset);
    my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
    my @tmpsymbolstack=();
    push(@tmpsymbolstack, $symbol);

    my $from = $symbol->feature->{'end'};

    # For each feature in the group, draw
    # - the grouping line between the previous feature and this one
    # - the feature itself
    foreach my $f (@feature_group) {

	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
	my $to = $symbol->feature->{'start'};

	#$self->push($symbol->draw);
	push(@tmpsymbolstack, $symbol);
	if ((($to - $from) * $self->{pix_per_bp}) > 1){ # i.e. if the gap is > 1pix
	    my $groupsymbol = $self->get_groupsymbol($groupstyle, $from, $to, $configuration, $y_offset);
	    push(@tmpsymbolstack, $groupsymbol);
	}

	# update 'from' for next time around
	$from = $symbol->feature->{'end'} unless $from > $symbol->feature->{'end'};

    }
    

    $total_track_height = $y_offset if ($total_track_height < $y_offset);

    #now take symols from the temporary stack to draw in order of their zindex....
    @tmpsymbolstack = sort{ 
      my $c=0;
      $c = ($a->style->{'zindex'}||0) <=> ($b->style->{'zindex'}||0) if exists(${$a->style}{'zindex'}) or exists(${$b->style}{'zindex'});
      $c==0 ? $a->feature->{'start'} <=> $b->feature->{'start'}  : $c;
    } map {$_} @tmpsymbolstack;
    while (my $s=shift @tmpsymbolstack){$self->push($s->draw);}

    # Offset y coords by which row we're on
    $Composite->y($Composite->y() + $y_offset);
 
    $self->push($Composite);

    # put back original properties of the style, so it can be re-used:
    $groupstyle->{'glyph'} = $orig_groupstyle_glyph;
    $groupstyle->{'attrs'}{'style'} = $orig_groupstyle_line ;
}


    if($more_features) {
    # There are more features to display : show the note
      my $yx =   2 * ($configuration->{'h'} + $label_height) + $total_track_height;

      my $ID = 'There are more '.$self->{'extras'}->{'label'}.' features in this region. Increase source depth to view them all ';
      $self->errorTrack($ID, undef, $yx);
    }    

  return 1; ## We have rendered at least one feature....
}   # END RENDER_grouped

sub to_bin {
  my( $self, $BP, $bin_length, $no_of_bins ) = @_;
  my $bin = floor( $BP / $bin_length );
  my $offset = $BP - $bin_length * $bin;
  if( $bin < 0 ) {
    ($bin,$offset) = (0,0);
  } elsif( $bin >= $no_of_bins ) {
    ($bin,$offset) = ($no_of_bins-1,$bin_length);
  }
  return ($bin,$offset);
}

sub RENDER_density {
  my( $self, $configuration ) = @_;
  my $empty_flag = 1;
  my $no_of_bins = floor( $configuration->{'length'} * $self->{'pix_per_bp'} / 2);
  my $bin_length = $configuration->{'length'} / $no_of_bins;
  my $bins = [ map {0} 1..$no_of_bins ];
## First of all compute the bin values....
## If it is either average coverage or average count we need to compute bin totals first...
## It is trickier for the bases covered - which I'll look at later...
  foreach my $f( @{$configuration->{'features'}} ){
    if($f->das_type_id() eq '__ERROR__') {
      $self->errorTrack(
        'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->das_id.')'
      );
      return -1 ;
    }
    my( $bin_start, $offset_start ) = $self->to_bin( $f->das_start -1, $bin_length, $no_of_bins );
    my( $bin_end,   $offset_end   ) = $self->to_bin( $f->das_end,      $bin_length, $no_of_bins );
    if( 0 ) { ## average coverage....
      $bins->[$bin_end]   += $offset_end;
      $bins->[$bin_start] -= $offset_start;
      if( $bin_end > $bin_start ) {
        foreach ( $bin_start .. ($bin_end-1) ) {
          $bins->[$_]     += $bin_length;
        }
      }
    } elsif( 1 ) { ## average count
      my $flen = $f->das_end - $f->das_start + 1;
      $bins->[$bin_end]   += $offset_end / $flen;
      $bins->[$bin_start] -= $offset_start / $flen;
      if( $bin_end > $bin_start ) {
        foreach ( $bin_start .. ($bin_end-1) ) {
          $bins->[$_]     += $bin_length / $flen;
        }
      }
    }
    $empty_flag = 0;
  }
  if($empty_flag) {
    $self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' );
    return 0; ## A " 0 " return indicates no features drawn....
  }
## Now we have our bins we need to render the image...
  my $coloursteps  = 10;
  my $rmax  = $coloursteps;
  my @range = ( $configuration->{'colour'} );

  my $display_method = 'scale';
  # my $display_method = 'bars';
  if( $display_method eq 'scale' ) {
    @range = $self->{'config'}->colourmap->build_linear_gradient($coloursteps, 'white', $configuration->{'colour'} );
    $rmax = @range;
  }
  my $max = $bins->[0];
  my $min = $bins->[0];
  foreach( @$bins ) {
    $max = $_ if $max < $_;
    $min = $_ if $min > $_;
  }
  my $divisor = $max - $min;
  my $start = 0;
  foreach( @$bins ) {
    my $F = $divisor ? ($_-$min)/$divisor : 1;
    my $colour_number = $display_method eq 'scale' ? floor( ($rmax-1) * $F ) : 0;
    my $height        = floor( $configuration->{'h'} * ($display_method eq 'bars' ? $F  : 1)  );
    $self->push( new Sanger::Graphics::Glyph::Rect({
      'x'         => $start,
      'y'         => $configuration->{'h'}-$height,
      'width'     => $bin_length,
      'height'    => $height,
      'colour'    => $range[ $colour_number ],
      'absolutey' => 1,
      'zmenu'     => { 'caption' => $_ }
    }) );
    $start+=$bin_length;
  }
  return 1;
}

sub bump{
  my ($self, $start, $end, $length, $dep ) = @_;
  my $bump_start = int($start * $self->{'pix_per_bp'} );
  $bump_start --;
  $bump_start = 0 if ($bump_start < 0);
    
  $end = $start + $length if $end < $start + $length;
  my $bump_end = int( $end * $self->{'pix_per_bp'} );
    $bump_end = $self->{'bitmap_length'} if ($bump_end > $self->{'bitmap_length'});
  my $row = &Sanger::Graphics::Bump::bump_row(
    $bump_start,    $bump_end,   $self->{'bitmap_length'}, $self->{'bitmap'}, $dep 
  );
  return $row > $dep ? -1 : $row;
}


# Zmenu for Grouped features
sub gmenu{
  my( $self, $f, $groupsize ) = @_;

  my $zmenu = {
  };

  my $id;
  my $ids = 10;
#      warn(Data::Dumper::Dumper($f));
  foreach my $group ($f->das_groups) {


      my $txt = $group->{'group_label'} || $group->{'group_id'};

      next if ($txt !~ $f->{'grouped_by'});
      $id = $txt if (! $id);
      my $dlabel = sprintf("%02d:GROUP : %s", $ids++, $txt);
      $zmenu->{$dlabel} = '';

      if ($groupsize) {
	  $dlabel = sprintf("%02d:&nbsp;&nbsp;%d features in group", $ids++, $groupsize);
	  $zmenu->{$dlabel} = '';
      }

      if ($group->{'group_id'}) {
	  $dlabel = sprintf("%02d:&nbsp;&nbsp;ID : %s", $ids++, $group->{'group_id'});
	  $zmenu->{$dlabel} = '';
      }
      if ($group->{'group_type'}) {
	  $dlabel = sprintf("%02d:&nbsp;&nbsp;TYPE : %s", $ids++, $group->{'group_type'});
	  $zmenu->{$dlabel} = '';
      }

      foreach my $dlink (@{$group->{'link'}}, @{$f->{navigation_links}} ) {
	  my $txt = $dlink->{'txt'} || $dlink->{'href'};
	  my $dlabel = sprintf("%02d:&nbsp;&nbsp;DAS LINK: %s", $ids++, $txt);
	  $zmenu->{$dlabel} = $dlink->{'href'};
      }
      
      if (my $note = $group->{'note'}) {
	  my $note_txt = '';

	  if (ref $note eq 'ARRAY') {
	      foreach my $n (@$note) {
		  $note_txt .= (decode_entities($n) . '<br/>');
	      }
	  } else {
	      $note_txt = decode_entities($note);

	  }
	  $zmenu->{"$ids:NOTES: $note_txt"} = '';
      }

      $ids ++;
  }

  if ($id) {
      $zmenu->{'caption'} = $id;
  } else {
      $zmenu->{'caption'} = $f->das_feature_label || $f->das_feature_id;
      $zmenu->{"20: No group info"} = '';
  }


  my $href;
  if($self->{'extras'}->{'linkURL'}){
      $href = $zmenu->{"80:".$self->{'link_text'}} = $self->{'config'}{'exturl'}->get_url( $self->{'extras'}->{'linkURL'}, $id );
  } elsif (my $url = $self->{'extras'}->{'linkurl'}){
      $url =~ s/###(\w+)###/CGI->escape( $id )/ge;
      $href = $zmenu->{"80:".$self->{'link_text'}} = $url;
  } 
 
  return( $href, $zmenu );
}


sub zmenu {
  my( $self, $f ) = @_;
  my $id = $f->das_feature_id || $f->das_feature_label;

  my $zmenu = {
    'caption'         => $f->das_feature_label || $f->das_feature_id,
  };

  # Leave 10 to hold the number of features in the group
  my $type = $f->das_type || $f->das_type_id;
  $zmenu->{"20:TYPE: ". $type           } = '' if $type && uc($type) ne 'NULL';
  my $method = $f->das_method || $f->das_method_id;
  $zmenu->{"25:METHOD: ". $method       } = '' if $method && uc($method) ne 'NULL';
  $zmenu->{"30:SCORE: ". $f->das_score  } = '' if (defined($f->das_score));
  $zmenu->{"35:CATEGORY: ". $f->das_type_category } = '' if $f->das_type_category && uc($f->das_type_category) ne 'NULL';

  my $ids = 40;
  foreach my $group ($f->das_groups) {
      my $txt = $group->{'group_label'} || $group->{'group_id'};
      my $dlabel = sprintf("%02d:GROUP : %s", $ids++, $txt);
      $zmenu->{$dlabel} = '';
  }
  
  if (defined($f->das_start) && defined($f->das_end)) {
      my $strand = ($f->das_strand > 0) ? 'Forward' : 'Reverse';
      $zmenu->{"50:FEATURE LOCATION:"} = '';
      $zmenu->{"51:   - Start: ".$f->das_segment->start} = '';
      $zmenu->{"52:   - End: ".$f->das_segment->end} = '';
      $zmenu->{"53:   - Strand: $strand"} = '';
  }

  if (defined($f->das_target_id)) {
      $zmenu->{"55:TARGET:".$f->das_target_id} = '';
      $zmenu->{"56:   - Start: ".$f->das_target_start} = '';
      $zmenu->{"57:   - End: ".$f->das_target_stop} = '';
  }

  $ids = 60;
  foreach my $dlink ($f->das_links) {
      my $txt = $dlink->{'txt'} || $dlink->{'href'};
      my $dlabel = sprintf("%02d:DAS LINK: %s", $ids++, $txt);
      $zmenu->{$dlabel} = $dlink->{'href'};
  }

  if (my $note = $f->das_note()) {
      my $note_txt = '';

      if (ref $note eq 'ARRAY') {
	  foreach my $n (@$note) {
	      $note_txt .= (decode_entities($n) . '<br/>');
	  }
      } else {
	  $note_txt = decode_entities($note);

      }
      $zmenu->{"70:NOTES: $note_txt"} = '';
  }

  my $href = undef;

  if($self->{'extras'}->{'fasta'}) {
    foreach my $string ( @{$self->{'extras'}->{'fasta'}}) {
    my ($type, $db ) = split /_/, $string, 2;
      $zmenu->{ "80:$type sequence" } = $self->{'config'}{'exturl'}->get_url( 'FASTAVIEW', { 'FASTADB' => $string, 'ID' => $id } );
      $href = $zmenu->{ "20:$type sequence" } unless defined($href);
    }
  }

  if($id && uc($id) ne 'NULL') {
    $zmenu->{"01:ID: $id"} = '';
    if($self->{'extras'}->{'linkURL'}){
      $href = $zmenu->{"85:".$self->{'link_text'}} = $self->{'config'}{'exturl'}->get_url( $self->{'extras'}->{'linkURL'}, $id );
    } elsif(my $url = $self->{'extras'}->{'linkurl'}){
	$url =~ s/###(\w+)###/CGI->escape( $id )/ge;
	$href = $zmenu->{"85:".$self->{'link_text'}} = $url;
    } 
  } 
  return( $href, $zmenu );
}


## feature_label 
## creates and pushes the label 
## and returns the height of the label created
sub feature_label {
  my( $self, $composite, $text, $feature_colour, $glyph_height, $row_height, $start, $end ) = @_;

  # glyphs are vertically centred in the row, and we need to draw the labels
  # relative to this.

  if( uc($self->{'extras'}->{'labelflag'}) eq 'O' ) { # draw On feature
    my @res = $self->get_text_width( 0, $text, '', 'font'=>$self->{'fontname_i'}, 'ptsize' => $self->{'fontsize_i'} );
    return unless $res[2]/$self->{'pix_per_bp'} < ($end-$start);

    my $y_offset = ($row_height - $self->{'textheight_i'})/2;
    my $tglyph = new Sanger::Graphics::Glyph::Text({
      'x'          => ( $end + $start - 1)/2,
      'y'          => $y_offset,
      'width'      => 0,
      'height'     => $self->{'textheight_i'},
      'font'       => $self->{'fontname_i'},
      'ptsize'     => $self->{'fontsize_i'},
      'colour'     => $self->{'config'}->colourmap->contrast($feature_colour),
      'text'       => $text,
      'absolutey'  => 1,
    });
    $composite->push($tglyph);
    return 0;
  } 
  elsif( uc($self->{'extras'}->{'labelflag'}) eq 'U') {	# draw Under feature
    my @res = $self->get_text_width( 0, $text, '', 'font'=>$self->{'fontname_o'}, 'ptsize' => $self->{'fontsize_o'} );
    my $y_offset = ($row_height + $glyph_height)/2;
    $y_offset += 2; # give a couple of pixels gap under the glyph
#warn "$text ............. $start .............. $res[2] / $self->{'pix_per_bp'}" ;
    my $tglyph = new Sanger::Graphics::Glyph::Text({
      'x'          => $start -1,
      'y'          => $y_offset,
      'width'      => $res[2]/$self->{'pix_per_bp'},
      'height'     => $self->{'textheight_o'},
      'font'       => $self->{'fontname_o'},
      'ptsize'     => $self->{'fontsize_o'},
      'halign'     => 'left',
      'colour'     => $feature_colour,
      'text'       => $text,
      'absolutey'  => 1,
    });
#warn $composite->width,'-',$composite->height;
    $composite->push($tglyph);
#warn $composite->width,'-',$composite->height;
#warn "......... $self->{'textheight_o'} + 4";
    return $self->{'textheight_o'} + 4;
  } else {
    return 0;
  }
}

sub das_name     { return $_[0]->{'extras'}->{'name'}; }
sub managed_name { return $_[0]->{'extras'}->{'name'}; }

sub _init {
  my ($self) = @_;
  ( my $das_name        = (my $das_config_key = $self->das_name() ) ) =~ s/managed_(extdas_)?//g;

  $das_config_key =~ s/^managed_das/das/;
  my $Config = $self->{'config'};
  my $Extra  = $self->{'extras'};
  my $strand = $Config->get($das_config_key, 'str') || $Extra->{'strand'};

  my $strand = $Config->get($das_config_key, 'str') || $Extra->{'strand'};

# If strand is 'r' or 'f' then we display everything on one strand (either
# at the top or at the bottom!
  return if( $strand eq 'r' && $self->strand() != -1 || $strand eq 'f' && $self->strand() != 1 );
  my $h;
  my $container_length =  $self->{'container'}->length() + 1;
 
 
  $self->{'bitmap'} = [];    
  my $configuration = {
    'strand'   => $strand,
    'tstrand'  => $self->strand,
    'STRAND'   => $self->strand(),
    'cmap'     => $Config->colourmap(),
    'depth'    => $Config->get($das_config_key, 'dep') || $Extra->{'depth'} || 4,
    'use_style'=> uc( $Config->get($das_config_key, 'stylesheet') || $Extra->{'stylesheet'} ) eq 'Y',
    'labelling'=> ($Config->get($das_config_key, 'lflag') || $Extra->{'labelflag'}) =~ /^n$/i ? 0 : 1,
    'length'   => $container_length
  };

  my $dsn = $Extra->{'dsn'};
  my $url = defined($Extra->{'url'}) ? $Extra->{'url'}."/$dsn" :  $Extra->{'protocol'}.'://'. $Extra->{'domain'} ."/$dsn";

  my $srcname = $Extra->{'label'} || $das_name;
  $srcname =~ s/^(managed_|mananged_extdas)//;
  my $dastype = $Extra->{'type'} || 'ensembl_location';
  my @das_features = ();

  $configuration->{colour} = $Config->get($das_config_key, 'col') || $Extra->{color} || $Extra->{col} || 'contigblue1';
  $configuration->{depth} =  defined($Extra->{depth}) ? $Extra->{depth} : defined($Config->get($das_config_key, 'dep')) ?  $Config->get($das_config_key, 'dep') : 4;

  $configuration->{use_style} = $Extra->{stylesheet} ? uc($Extra->{stylesheet}) eq 'Y' : uc($Config->get($das_config_key, 'stylesheet')) eq 'Y';
  $configuration->{'labelling'} =($Config->get($das_config_key, 'lflag') || $Extra->{'labelflag'}) =~ /^n$/i ? 0 : 1,
  $configuration->{length} = $container_length;

  my( $fontname_i, $fontsize_i ) = $self->get_font_details( 'innertext' );
  my @res_i = $self->get_text_width( 0, 'X', '', 'font'=>$fontname_i, 'ptsize' => $fontsize_i );

  my( $fontname_o, $fontsize_o ) = $self->get_font_details( 'innertext' );
  my @res_o = $self->get_text_width( 0, 'X', '', 'font'=>$fontname_o, 'ptsize' => $fontsize_o );

  $self->{'pix_per_bp'}    = $Config->transform->{'scalex'};
  $self->{'bitmap_length'} = int(($configuration->{'length'}+1) * $self->{'pix_per_bp'});
  ($self->{'fontname_i'},$self->{'fontsize_i'}, $self->{'textwidth_i'},$self->{'textheight_i'}) = ($fontname_i, $fontsize_i,$res_i[2],$res_i[3]);
  ($self->{'fontname_o'},$self->{'fontsize_o'}, $self->{'textwidth_o'},$self->{'textheight_o'}) = ($fontname_o, $fontsize_o,$res_o[2],$res_o[3]);
  $self->{'textwidth_i'}     *= (1 + 1/($container_length||1) );
  $self->{'textwidth_o'}     *= (1 + 1/($container_length||1) );
  $configuration->{'h'} = $self->{'textheight_i'};

  my $styles;

  if ($dastype !~ /^ensembl_location/) {
      my $ga =  $self->{'container'}->adaptor->db->get_GeneAdaptor();
      my $genes = $ga->fetch_all_by_Slice( $self->{'container'});
      my $name = $das_name || $url;

      foreach my $gene (@$genes) {
         next if ($gene->strand != $self->strand);
	 my ($features, $style) = $gene->get_all_DAS_Features->{$name}; # First element is aref to features, second - style

         my $fcount = 0;
         my %fhash = ();

         foreach my $f (grep { $_->das_type_id() !~ /^(contig|component|karyotype)$/i &&  $_->das_type_id() !~ /^(contig|component|karyotype):/i } (@{$features || []})) {
             if ($f->das_end) {
		
		 my @coords;
		 foreach my $transcript (@{$gene->get_all_Transcripts()}) {
		     @coords = grep { $_->isa('Bio::EnsEMBL::Mapper::Coordinate') } $transcript->pep2genomic($f->start, $f->end, $f->strand);
		 }

		 if (@coords) {
		     my $c = $coords[0];
		     my $end = ($c->end > $configuration->{'length'}) ? $configuration->{'length'} : $c->end; 
		     my $start = ($c->start < $end) ? $c->start : $end;
		     $f->das_orientation or $f->das_orientation($gene->strand);
		     $f->das_start($start);
		     $f->das_end($end);
		 }

		 push(@das_features, $f);
             } else {
                if (exists $fhash{$f->das_segment->ref}) {
                    $fhash{$f->das_segment->ref}->{count} ++;
                } else {
                    $fhash{$f->das_segment->ref}->{count} = 1;
                    $fhash{$f->das_segment->ref}->{feature} = $f;
                }
             }
         }
         
         foreach my $key (keys %fhash) {

             my $ft = $fhash{$key}->{feature}; 
             if ((my $count = $fhash{$key}->{count}) > 1) {
                $ft->{das_feature_label} = "$key/$count";

                $ft->das_note("Found $count annotations for $key");
		my $link = {
		    'href' => "/$ENV{ENSEMBL_SPECIES}/geneview?db=core;gene=$key;:DASselect_${srcname}=0;DASselect_${srcname}=1#$srcname",
		    'txt' => 'View annotations in geneview'
		    };
		$ft->das_link([$link]);
             }
             $ft->das_type_id('summary');
             $ft->das_type('summary');
             $ft->das_start($gene->start);
             $ft->das_end($gene->end);
             $ft->das_strand($gene->strand);

             push(@das_features, $ft);
         }

      }
  } else {
      my( $features, $das_styles ) = @{$self->{'container'}->get_all_DASFeatures($dastype)->{$dsn}||[]};


      $styles = $das_styles;
      @das_features = grep {
	  $_->das_type_id() !~ /^(contig|component|karyotype)$/i && 
	      $_->das_type_id() !~ /^(contig|component|karyotype):/i &&
	      $_->das_start <= $configuration->{'length'} &&
	      $_->das_end > 0
	  } @{ $features || [] };
  }
  
  $configuration->{'features'} = \@das_features;

  # hash styles by type
  my %styles;
  if( $styles && @$styles && $configuration->{'use_style'} ) {
    my $styleheight = 0;
    foreach(@$styles) {
      $styles{$_->{'category'}}{$_->{'type'}} = $_ unless $_->{'zoom'};
    
      # Set row height ($configuration->{'h'}) from stylesheet
      # Currently, this uses the greatest height present in the stylesheet
      # but should really use the greatest height in the current featureset
      
      if (exists $_->{'attrs'} && exists $_->{'attrs'}{'height'}){
	my $tmpheight = $_->{'attrs'}{'height'};
	$tmpheight += abs $_->{'attrs'}{'yoffset'} if $_->{'attrs'}{'yoffset'} ;
	$styleheight = $tmpheight if $tmpheight > $styleheight;
      }
    } 
    $configuration->{'h'} = $styleheight if $styleheight;
    $configuration->{'styles'} = \%styles;
  } else {
    $configuration->{'use_style'} = 0;
  }

  $self->{'link_text'}    = $Extra->{'linktext'} || 'Additional info';


  $self->{helplink} = $Config->get($das_config_key, 'helplink') || $Extra->{'group'};
  my $renderer = $Config->get($das_config_key, 'renderer');
	       
  my $group = uc($Config->get($das_config_key, 'group') || $Extra->{'group'} || 'N');


  my $score = uc($Config->get($das_config_key, 'score') || $Extra->{'score'} || 'N');

  if ($score eq 'H') {
      $renderer = "RENDER_histogram_simple";
      $configuration->{use_score} = $score;
      my $fg_merge = uc($Config->get($das_config_key, 'fg_merge') || $Extra->{'fg_merge'} || 'A');
      $configuration->{'fg_merge'} = $fg_merge;

  } elsif ($score eq 'S') {
      $renderer = "RENDER_signalmap";
      $configuration->{use_score} = $score;
      my $fg_merge = uc($Config->get($das_config_key, 'fg_merge') || $Extra->{'fg_merge'} || 'A');
      $configuration->{'fg_merge'} = $fg_merge;
  } else {
      $renderer = $renderer ? "RENDER_$renderer" : ($group eq 'N' ? 'RENDER_simple' : 'RENDER_grouped');  
  }
  $renderer =~ s/RENDER_RENDER/RENDER/;
  return $self->$renderer( $configuration );
}

# Summary Menu for genedas-style summary features
sub smenu {
  my( $self, $f ) = @_;
  my $note = $f->das_note();
  my $zmenu = {
    'caption'         => $self->{'extras'}->{'label'},
  };
  $zmenu->{"02:TYPE: ". $f->das_type_id()           } = '' if $f->das_type_id() && uc($f->das_type_id()) ne 'NULL';

  my $ids = 3;

  foreach my $dlink ($f->das_links) {
      my $txt = $dlink->{txt} || '';
      my $href = $dlink->{href} || '';
      my $dlabel = sprintf("%02d: %s", $ids++, $txt);
      $zmenu->{$dlabel} = $href;
  }

#  $zmenu->{"03:".$f->das_link_label()     } = $f->das_link() if $f->das_link() && uc($f->das_link()) ne 'NULL';

  if($note && uc($note) ne 'NULL') {
    $zmenu->{"01:INFO: $note"} = '';
  } 
  return( $zmenu );
}


sub get_groupstyle {
    my ($self, $f, $configuration) = @_;
    my $group = $f->das_group_type || $f->das_type_id;

    my $style;
    if($configuration->{'use_style'}) {
	$style = $configuration->{'styles'}{'group'}{$group};
	$style ||= $configuration->{'styles'}{'group'}{'default'};

	$style->{'type'} ||= 'default';
	unless ($style){
	    # OK, now we hack about a bit.
	    # Try to use the colours/height of the feature passed in
	    my $tempstyle = $self->get_featurestyle($f, $configuration);
	    if ($tempstyle){
		my $colour = $tempstyle->{'attrs'}{'fgcolor'};
		my $height = $tempstyle->{'attrs'}{'height'};

		$style = {};
		$style->{'attrs'}{'colour'} = $colour;
		$style->{'attrs'}{'height'} = $height;
	    }
	}
    }
    $style ||= {};
    $style->{'attrs'} ||= {};
    
    # Set some defaults
    my $colour = $style->{'attrs'}{'fgcolor'} || $configuration->{'colour'};
    
    $style->{'glyph'} ||= 'line';
    $style->{'attrs'}{'height'} ||= $configuration->{'h'};
    $style->{'attrs'}{'colour'} ||= $colour;

    return $style;
}


sub get_featurestyle {
    my ($self, $f, $configuration) = @_;
    my $style;
    if($configuration->{'use_style'}) {
	my $fcategory = $f->das_type_category || 'default';
	my $ftype = $f->das_type_id || 'default';
	$style = $configuration->{'styles'}{$fcategory}{$ftype};

#	$style = $configuration->{'styles'}{$f->das_type_category}{$f->das_type_id};
#	$style ||= $configuration->{'styles'}{$f->das_type_category}{'default'};
#	$style ||= $configuration->{'styles'}{'default'}{'default'};
    }
    $style ||= {};
    $style->{'attrs'} ||= {};

    # Set some defaults
    my $colour = $style->{'attrs'}{'fgcolor'} || $configuration->{'colour'};
    $style->{'attrs'}{'height'} ||= $configuration->{'h'};
    $style->{'attrs'}{'colour'} ||= $colour;

    return $style;
}


sub get_featuredata {
    my ($self, $f, $configuration, $y_offset) = @_;
  
    # keep within the window we're drawing
    my $START = $f->das_start() < 1 ? 1 : $f->das_start();
    my $END   = $f->das_end()   > $configuration->{'length'}  ? $configuration->{'length'} : $f->das_end();
    my $row_height = $configuration->{'h'};

    # truncation flags
    my $trunc_start = ($START ne $f->das_start()) ? 1 : 0;
    my $trunc_end   = ($END ne $f->das_end())	    ? 1 : 0;
    my $orientation = $f->das_orientation;

    my $featuredata = {
		    'row_height'    => $row_height, 
		    'start'	    => $START, 
		    'end'	    => $END , 
		    'pix_per_bp'    => $self->{'pix_per_bp'}, 
		    'y_offset'	    => $y_offset,
		    'trunc_start'   => $trunc_start,
		    'trunc_end'	    => $trunc_end,
		    'orientation'   => $orientation,
		    };
		    
    return $featuredata;
}

sub get_symbol {
    my ($self, $style, $featuredata, $y_offset) = @_;
    my $styleattrs = $style->{'attrs'};
    my $glyph_symbol = $style->{'glyph'} || 'box';
    $y_offset -= $styleattrs->{'yoffset'}||0;

    # Load the glyph symbol module that we need to draw this style
    $glyph_symbol = 'Bio::EnsEMBL::Glyph::Symbol::'.$glyph_symbol;
    unless ($self->dynamic_use($glyph_symbol)){
	$glyph_symbol = 'Bio::EnsEMBL::Glyph::Symbol::box';
    }
    
    # vertically centre symbol in centre of row
    my $row_height = $featuredata->{'row_height'};
    my $glyph_height = $style->{'attrs'}{'height'};
    $y_offset = $style->{'attrs'}{'y_offset'} || ($y_offset + ($row_height - $glyph_height)/2);
    $featuredata->{'y_offset'} = $y_offset;

    return $glyph_symbol->new($featuredata, $styleattrs);  
}


sub get_groupsymbol{
    my ($self, $style, $from, $to, $configuration, $y_offset) = @_;

    my $styleattrs = $style->{'attrs'}; 

    # keep within the window we're drawing
    my $START = $from < 1 ? 1 : $from;
    my $END   = $to > $configuration->{'length'}  ? $configuration->{'length'} : $to;
    my $row_height = $configuration->{'h'};

    # truncation flags
    my $trunc_start = $START ne $from	? 1 : 0;
    my $trunc_end   = $END ne $to	? 1 : 0;
    my $orientation = $configuration->{'STRAND'};

    # vertically centre symbol in centre of row
    my $glyph_height = $styleattrs->{'height'};
    $y_offset = $y_offset + ($row_height - $glyph_height)/2;

    my $featuredata = {
		    'row_height'    => $row_height, 
		    'start'	    => $START, 
		    'end'	    => $END , 
		    'pix_per_bp'    => $self->{'pix_per_bp'}, 
		    'y_offset'	    => $y_offset,
		    'trunc_start'   => $trunc_start,
		    'trunc_end'	    => $trunc_end,
		    'orientation'   => $orientation,
		    };
		   
    my $glyph_symbol = $style->{'glyph'} || 'line';

    # Load the glyph symbol module that we need to draw this style
    $glyph_symbol = 'Bio::EnsEMBL::Glyph::Symbol::'.$glyph_symbol;
    unless ($self->dynamic_use($glyph_symbol)){
	$glyph_symbol = 'Bio::EnsEMBL::Glyph::Symbol::box';
    }

    return $glyph_symbol->new($featuredata, $styleattrs);  
}

# Function will display DAS features with variable height depending on SCORE attribute
sub RENDER_histogram_simple {
    my( $self, $configuration ) = @_;

# Display histogram only on a reverse strand
    return if ($configuration->{'STRAND'} == 1);

    my $empty_flag = 1;

# Should come from a stylesheet in future

    my @features = sort { $a->das_start() <=> $b->das_start() } @{$configuration->{'features'}};


    my ($min_score, $max_score) = (sort {$a <=> $b} (map { $_->score } @features))[0,-1];

    my $row_height = 30;
    my $pix_per_score = ($max_score - $min_score) / $row_height;
    my $bp_per_pix = 1 / $self->{pix_per_bp};

    $configuration->{h} = $row_height;

    # flag to indicate if not all features have been displayed 
    my $more_features = 0;
    my ($gScore, $gWidth, $fCount, $gStart, $mScore) = (0, 0, 0, 0, $min_score);
    for (my $i = 0; $i< @features; $i++) { 
	my $f = $features[$i];

	# Handle DAS errors first
	if($f->das_type_id() eq '__ERROR__') {
	    $self->errorTrack(
			      'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->das_id.')'
			      );
	    return -1 ;   # indicates no features drawn because of DAS error
	}
    
	$empty_flag &&= 0; # We have a feature (its on one of the strands!)

	# Skip features that aren't on the current strand, if we're doing both
	# strands
	my $row = 0; # bumping row

	# keep within the window we're drawing
	my $START = $f->das_start() < 1 ? 1 : $f->das_start();
	my $END   = $f->das_end()   > $configuration->{'length'}  ? $configuration->{'length'} : $f->das_end();

	my $width = ($END - $START +1);

	my $score = $f->das_score;
	$score = $max_score if ($score > $max_score);
	$score = $min_score if ($score < $min_score);
	
# Here we "group" features if they are too small and located very close to each other .. 

	$gWidth += $width;
	$gScore += $score;
	$mScore = $score if ($score > $mScore);

	$fCount ++;
	$gStart = $START if ($fCount == 1);

# If feature is smaller than 1px and next feature is close than 1px then we merge features .. 
# 1px value depend on the zoom .. 
	if ($gWidth < $bp_per_pix) { 
	    my $nf = $features[$i+1];
	    if ($nf) {
		my $distance = $nf->das_start() - $END;
		next if ($distance < $bp_per_pix);
	    }
	}



	my $height;

	if ($configuration->{'fg_merge'} eq 'A') {
	    $height = ($score / $fCount - $min_score) / $pix_per_score;
	} elsif ($configuration->{'fg_merge'} eq 'M') {
	    $height = ($mScore - $min_score) / $pix_per_score;
	    if ($height < 0) {
		warn("ERROR: !! $mScore * $min_score * $pix_per_score");
	    }
	}
#	$height = ($score / $fCount - $min_score) / $pix_per_score;
	my ($href, $zmenu );
	my $Composite = new Sanger::Graphics::Glyph::Composite({
	    'y'         => 0,
	    'x'         => $START-1,
	    'absolutey' => 1,
	});

	if ($fCount > 1) {
	    $zmenu = {
		'caption'         => $self->{'extras'}->{'label'},
	    };

	    $zmenu->{"03:$fCount features merged"} = '';
	    $zmenu->{"05:Average SCORE: ".($gScore/$fCount)} = '';
	    $zmenu->{"08:Max SCORE: $mScore"} = '';
	    $zmenu->{"10:START: $gStart"} = '';
	    $zmenu->{"20:END: $END"} = '';
	} else {
	    ($href, $zmenu ) = $self->zmenu( $f );
	    $Composite->{'href'} = $href if $href;
	}

	$Composite->{'zmenu'} = $zmenu;
	my $style = $self->get_featurestyle ($f, $configuration);
	my $styledata = $style->{'attrs'};  # style attributes for this feature
	my $glyph_height = $styledata->{'height'};
	my $colour = $styledata->{'colour'};
	my $glyph_symbol = $style->{'glyph'};
	
	my $y_offset = - $configuration->{'tstrand'}*($row_height+2) * $row;
	
	# Special case for viewing summary non-positional features (i.e. gene
	# DAS features on contigview) Just display a gene-wide line with a link
	# to geneview where all annotations can be viewed
	
	# make clickable box to anchor zmenu
	$Composite->push( new Sanger::Graphics::Glyph::Space({
	    'x'         => $gStart - 1,
	    'y'         => 0,
	    'width'     => $gWidth,
	    'height'    => $glyph_height,
	    'absolutey' => 1
	    }) );

	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

	my $sm = new Sanger::Graphics::Glyph::Rect({
	    'x'          => $gStart - 1,
	    'y'          => $row_height - $height, 
	    'width'      => $gWidth,
	    'height'     => $height,
	    'colour'     => $colour,
	    'absolutey' => 1,
	});

    # Draw feature symbol

	$self->push($sm);
	# Offset label coords by which row we're on
	$Composite->y($Composite->y() + $y_offset);

	$self->push( $Composite );

	$gWidth = $gScore = $fCount = 0;
	$mScore = $min_score;
    } # END loop over features

    $self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' ) if $empty_flag;
    return $empty_flag ? 0 : 1 ;

}   # END RENDER_simple


sub RENDER_signalmap {
    my( $self, $configuration ) = @_;

# Display histogram only on a reverse strand
    return if ($configuration->{'STRAND'} == 1);

    my @features = sort { $a->das_score <=> $b->das_score  } @{$configuration->{'features'}};

    
    if (@features) {
	my $f = $features[0];
	if($f->das_type_id() eq '__ERROR__') {
	    $self->errorTrack(
			      'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->das_id.')'
			      );
	    return -1 ;   # indicates no features drawn because of DAS error
	}
    } else {
	$self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' );
	return 0;
    }
	
    my ($min_score, $max_score) = ($features[0]->das_score || 0, $features[-1]->das_score || 0);

    my @positive_features = grep { $_->das_score >= 0 } @features;
    my @negative_features = grep { $_->das_score < 0 } reverse @features;

    my $row_height = 30;
    my $pix_per_score = (abs($max_score) >  abs($min_score) ? abs($max_score) : abs($min_score)) / $row_height;
    my $bp_per_pix = 1 / $self->{pix_per_bp};

    $configuration->{h} = $row_height;

    # flag to indicate if not all features have been displayed 
    my $more_features = 0;
    my ($gScore, $gWidth, $fCount, $gStart, $mScore) = (0, 0, 0, 0, $min_score);

# Draw the axis

    $self->push( new Sanger::Graphics::Glyph::Line({
	'x'         => 0,
        'y'         => $row_height + 1,
	'width'     => $configuration->{'length'},
	'height'    => 0,
	'absolutey' => 1,
	'colour'    => 'red',
	'dotted'    => 1,
    }));

    $self->push( new Sanger::Graphics::Glyph::Line({
	'x'         => 0,
        'y'         => 0,
	'width'     => 0,
	'height'    => $row_height * 2 + 1,
	'absolutey' => 1,
	'absolutex' => 1,
	'colour'    => 'red',
	'dotted'    => 1,
    }));

#    return 1;
    foreach my $f (@negative_features, @positive_features) {
#	warn(join('*', 'F', $f->start, $f->end, $f->das_score, $f->das_type_category));
	my $START = $f->das_start() < 1 ? 1 : $f->das_start();
	my $END   = $f->das_end()   > $configuration->{'length'}  ? $configuration->{'length'} : $f->das_end();

	my $width = ($END - $START +1);
	my $score = $f->das_score || 0;

	my $Composite = new Sanger::Graphics::Glyph::Composite({
	    'y'         => 0,
	    'x'         => $START-1,
	    'absolutey' => 1,
	});

	my $height = abs($score) / $pix_per_score;
	my $y_offset = 	($score > 0) ?  $row_height - $height : $row_height+2;
	$y_offset-- if (! $score);

	my ($href, $zmenu ) = $self->zmenu( $f );

	$Composite->{'href'} = $href if $href;
	$Composite->{'zmenu'} = $zmenu;

	# make clickable box to anchor zmenu
	$Composite->push( new Sanger::Graphics::Glyph::Space({
	    'x'         => $START - 1,
	    'y'         => ($score ? (($score > 0) ? 0 : ($row_height + 2)) : ($row_height + 1)),
	    'width'     => $width,
	    'height'    => $score ? $row_height : 1,
	    'absolutey' => 1
	    }) );


	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);
	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);

	$symbol->{'style'}->{'height'} = $height;
	$symbol->{'feature'}->{'orientation'} = 1;
	$symbol->{'feature'}->{'row_height'} = $row_height * 2 + 1;
	$symbol->{'feature'}->{'y_offset'}  = $y_offset;

#	warn(Data::Dumper::Dumper($symbol));# if (! $f->das_score);

	$Composite->push($symbol->draw);

	$self->push( $Composite );
    } # END loop over features



    $self->push( new Sanger::Graphics::Glyph::Text({
	'text'      => $max_score,
      'height'     => $self->{'textheight_i'},
      'font'       => $self->{'fontname_i'},
      'ptsize'     => $self->{'fontsize_i'},
      'halign' => 'left',
	'colour'    => 'red',
	'y' => 1,
	'x' => 3,
	'absolutey' => 1,
	'absolutex' => 1,
    }) );


    if ($min_score < 0) {
	$self->push( new Sanger::Graphics::Glyph::Text({
	    'text'      => $min_score,
      'height'     => $self->{'textheight_i'},
      'font'       => $self->{'fontname_i'},
      'ptsize'     => $self->{'fontsize_i'},
      'halign' => 'left',
	    'colour'    => 'red',
	    'y' => abs($min_score) / $pix_per_score + $row_height + 2,
	    'x' => 3,
	    'absolutey' => 1,
	    'absolutex' => 1,
	}) );
    }

	return 1;

}   # END RENDER_signalmap


1;
