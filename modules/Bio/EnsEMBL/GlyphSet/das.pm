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
use ExtURL;


sub init_label {
  my ($self) = @_;
  return if( defined $self->{'config'}->{'_no_label'} );
  my $params =  $ENV{QUERY_STRING};
  $params =~ s/\&$//;
  $params =~ s/\&/zzz/g;
  my $script = $ENV{ENSEMBL_SCRIPT};

  my $helplink = (defined($self->{'extras'}->{'helplink'})) ?  $self->{'extras'}->{'helplink'} :  qq(/@{[$self->{container}{_config_file_name_}]}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#das);

my $URL = "";
if ($self->das_name =~ /^managed_extdas_(.*)$/){
    $URL = qq(javascript:X=window.open(\'/@{[$self->{container}{_config_file_name_}]}/dasconfview?_das_edit=$1&conf_script=$script&conf_script_params=$params\',\'dassources\',\'height=500,width=500,left=50,screenX=50,top=50,screenY=50,resizable,scrollbars=yes\');X.focus();void(0));
}
else {
    if ($self->{'extras'}{'homepage'}){
	$URL = $self->{'extras'}{'homepage'};
    }
    else {
	$URL = qq(javascript:X=window.open(\'$helplink\',\'helpview\',\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\');X.focus();void(0)) ;
    }
}

  my $track_label = $self->{'extras'}->{'label'} || $self->{'extras'}->{'caption'} || $self->{'extras'}->{'name'};
  $track_label =~ s/^(managed_|managed_extdas)//;

  $self->label( new Sanger::Graphics::Glyph::Text({
    'text'      => $track_label,
    'font'      => 'Small',
    'colour'    => 'contigblue2',
    'absolutey' => 1,
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

  foreach my $f( sort { $a->das_start() <=> $b->das_start() } @{$configuration->{'features'}} ){

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
    my $label = $f->das_group_label || $f->das_feature_label || $ID;
    my $label_length = $configuration->{'labelling'} * $self->{'textwidth'} * length(" $ID ") * 1.1; # add 10% for scaling text
    my $row = 0; # bumping row

    # keep within the window we're drawing
    my $START = $f->das_start() < 1 ? 1 : $f->das_start();
    my $END   = $f->das_end()   > $configuration->{'length'}  ? $configuration->{'length'} : $f->das_end();

    # bump if required
    if( $configuration->{'depth'} > 0 ) {
      $row = $self->bump( $START, $END, $label_length, $configuration->{'depth'} );
      if( $row < 0 ) { ## SKIP IF BUMPED...
	  $more_features = 1;
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
    my $label_height =$self->feature_label( $Composite, 
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
	my $f     = shift @{$configuration->{'features'}};
	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

	# override to draw this as a span
	my $oldglyph = $style->{'glyph'};
	$style->{'glyph'} = 'span';
   
	# Change zmenu to summary menu
	my $smenu = $self->smenu($f);
	$Composite->{zmenu} = $smenu;

	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
	$self->push($symbol->draw);

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

    # Offset label coords by which row we're on
    $Composite->y($Composite->y() + $y_offset);

    $self->push( $Composite );
  } # END loop over features

  $self->errorTrack( 'No '.$self->{'extras'}->{'caption'}.' features in this region' ) if $empty_flag;

  if($more_features) {
    # There are more features to display : show the note
      my $yx = $configuration->{'depth'};
      my $ID = 'There are more '.$self->{'extras'}->{'label'}.' features in this region. Increase source depth to view them all ';
      $self->errorTrack($ID, undef, $configuration->{'tstrand'}*($configuration->{'h'}) * $yx);
  }    

  return $empty_flag ? 0 : 1 ;

}   # END RENDER_simple


sub RENDER_grouped {
  my( $self, $configuration ) = @_; 
  my %grouped;

  my $old_end = -1e9;
  my $empty_flag = 1;

  ## Loop over features and hash into groups
  foreach my $f(@{$configuration->{'features'}}){
    
    # Handle DAS errors first
    if($f->das_type_id() eq '__ERROR__') {
      $self->errorTrack( 'Error retrieving '.$self->{'extras'}->{'caption'}.' features ('.$f->id.')' );
      return -1; # indicates no features drawn because of DAS error
    }

    # Skip features that aren't on the current strand, if we're doing both
    # strands
    next if $configuration->{'strand'} eq 'b' && ( $f->strand() !=1 && $configuration->{'STRAND'}==1 || $f->strand() ==1 && $configuration->{'STRAND'}==-1);

    # build a hash of features, keyed by id if ungrouped, or G:group_id if
    # grouped
    my $fid = $f->das_id;
    next unless $fid;
    $fid  = "G:".$f->das_group_id if $f->das_group_id;
#    delete($f->{das_link});
    push @{$grouped{$fid}}, $f;

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
    
    # constrain to image window
    my $START = $start < 1 ? 1 : $start;
    my $END   = $end > $configuration->{'length'} ? $configuration->{'length'} : $end;

    # Compute the length of the label...
    my $ID    = $f->das_group_id || $f->das_id;
    my $label = $f->das_group_label || $f->das_feature_label || $ID;

    # append number of features in group

    my $num_in_group = scalar @feature_group;
    if ($num_in_group > 1){
	$label .= "[$num_in_group]";
    }
    
    my $label_length = $configuration->{'labelling'} * $self->{'textwidth'} * length(" $label ") * 1.1; # add 10% for scaling text
    my $row = $configuration->{'depth'} > 0 ? $self->bump( $START, $end, $label_length, $configuration->{'depth'} ) : 0;

    if( $row < 0 ) { ## SKIP IF BUMPED...
	$more_features = 1;
	next;
    }

# Very dirty hack to handle Next/Previous links between features when they are grouped
# If there is Next or Previous label amongst the feature links, 
# then get Previous link of the first feature in the group and Next link of the last feature in the group
    if ( "@{$f->{das_link_label}}" =~ /Next|Previous/) {
	my $fgroup = $feature_group[0];
	my $lgroup = $feature_group[-1];
	my @links = $fgroup->das_links;
	my (%FLinks, %LLinks);
	foreach ($fgroup->das_link_labels) {
	    $FLinks{$_} = shift(@links);
	}
	@links = $lgroup->das_links;
	foreach ($lgroup->das_link_labels) {
	    $LLinks{$_} = shift(@links);
	}
	delete($f->{das_link_label});
	delete($f->{das_link});
	if (my $plink = $FLinks{Previous}) {
	    push @{$f->{das_link_label}}, 'Previous';
	    push @{$f->{das_link}}, $plink;
	}
	if (my $nlink = $LLinks{Next}) {
	    push @{$f->{das_link_label}}, 'Next';
	    push @{$f->{das_link}}, $nlink;
	}
    }

    my $groupsize = scalar @feature_group;
    my( $href, $zmenu ) = $self->gmenu( $f, $groupsize );


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
    my $label_height =$self->feature_label( $Composite, 
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
	my $f = shift @feature_group;
	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);

	# override glyph to draw this as a span
	my $oldglyph = $style->{'glyph'};
	$style->{'glyph'} = 'span';
   
	# Change zmenu to summary menu
	my $smenu = $self->smenu($f);
	$Composite->{zmenu} = $smenu;

	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
	$self->push($symbol->draw);

	# put the style back to how it was
	$style->{'glyph'} = $oldglyph;
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
    $self->push($symbol->draw);

    my $from = $symbol->feature->{'end'};

    # For each feature in the group, draw
    # - the grouping line between the previous feature and this one
    # - the feature itself
    foreach my $f (@feature_group) {
	my $style = $self->get_featurestyle($f, $configuration);
	my $fdata = $self->get_featuredata($f, $configuration, $y_offset);
	my $symbol = $self->get_symbol ($style, $fdata, $y_offset);
	my $to = $symbol->feature->{'start'};

	$self->push($symbol->draw);
	if ((($to - $from) * $self->{pix_per_bp}) > 1){ # i.e. if the gap is > 1pix
	    my $groupsymbol = $self->get_groupsymbol($groupstyle, $from, $to, $configuration, $y_offset);
	    $self->push($groupsymbol->draw);
	}
	    
	# update 'from' for next time around
	$from = $symbol->feature->{'end'};
    }

    # Offset y coords by which row we're on
    $Composite->y($Composite->y() + $y_offset);
 
    $self->push($Composite);

    # put back original properties of the style, so it can be re-used:
    $groupstyle->{'glyph'} = $orig_groupstyle_glyph;
    $groupstyle->{'attrs'}{'style'} = $orig_groupstyle_line ;
   
  }

    if($more_features) {
    # There are more features to display : show the note
         my $yx = $configuration->{'depth'};
         my $ID = 'There are more '.$self->{'extras'}->{'caption'}.' features in this region. Increase source depth to view them all ';
         $self->errorTrack($ID, undef, $configuration->{'tstrand'}*($configuration->{'h'}) * $yx);
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
    'caption'         => $self->{'extras'}->{'label'},
  };

  my $id = $f->das_group_label() || $f->das_group_id() || $f->das_feature_label() || $f->das_id();
  $zmenu->{"01:GROUP: ". $id } = '';
  $zmenu->{"05:LABEL: ". $f->das_group_label} = '' if $f->das_group_label && uc($f->das_group_label()) ne 'NULL';
  $zmenu->{"06: &nbsp;&nbsp;$groupsize features in group"} = '' if $groupsize > 1;
  $zmenu->{"07:TYPE: ". $f->das_group_type() } = '' if $f->das_group_type() && uc($f->das_group_type()) ne 'NULL';
  $zmenu->{"07:CATEGORY: ". $f->das_type_category() } = '' if $f->das_type_category() && uc($f->das_type_category()) ne 'NULL';
#  $zmenu->{"08:DAS LINK: ".$f->das_link_label()     } = $f->das_link() if $f->das_link() && uc($f->das_link()) ne 'NULL';


  # Fix to handle features with multiple links.
  my $ids = 8;
  my @dlabels = $f->das_link_labels();
  foreach my $dlink ($f->das_links) {
      my $dlabel = sprintf("%02d:DAS LINK: %s", $ids++, shift @dlabels);
      $zmenu->{$dlabel} = $dlink if uc($dlink) ne 'NULL';
  }
  $zmenu->{"20:".$f->das_note()     } = '' if $f->das_note() && uc($f->das_note()) ne 'NULL';

  my $href;
  if($self->{'extras'}->{'linkURL'}){
      $href = $zmenu->{"30:".$self->{'link_text'}} = $self->{'ext_url'}->get_url( $self->{'extras'}->{'linkURL'}, $id );
  } 
 
  return( $href, $zmenu );
}


sub zmenu {
  my( $self, $f ) = @_;
  my $id = $f->das_feature_label() || $f->das_group_label() || $f->das_group_id() || $f->das_id();
  my $zmenu = {
    'caption'         => $self->{'extras'}->{'label'},
  };

  # Leave 02 to hold the number of features in the group
  $zmenu->{"03:TYPE: ". $f->das_type_id()           } = '' if $f->das_type_id() && uc($f->das_type_id()) ne 'NULL';
  $zmenu->{"04:SCORE: ". $f->das_score()            } = '' if $f->das_score() && uc($f->das_score()) ne 'NULL';
  $zmenu->{"05:GROUP: ". $f->das_group_id()         } = '' if $f->das_group_id() && uc($f->das_group_id()) ne 'NULL' && $f->das_group_id ne $id;
  $zmenu->{"06:METHOD: ". $f->das_method_id()       } = '' if $f->das_method_id() && uc($f->das_method_id()) ne 'NULL';
  $zmenu->{"07:CATEGORY: ". $f->das_type_category() } = '' if $f->das_type_category() && uc($f->das_type_category()) ne 'NULL';
  my $ids = 8;
  my @dlabels = $f->das_link_labels();
  foreach my $dlink ($f->das_links) {
      my $dlabel = sprintf("%02d:DAS LINK: %s", $ids++, shift @dlabels);
      $zmenu->{$dlabel} = $dlink if uc($dlink) ne 'NULL';
  }
  $zmenu->{"20:".$f->das_note()     } = '' if $f->das_note() && uc($f->das_note()) ne 'NULL';

  my $href = undef;
  if($self->{'extras'}->{'fasta'}) {
    foreach my $string ( @{$self->{'extras'}->{'fasta'}}) {
    my ($type, $db ) = split /_/, $string, 2;
      $zmenu->{ "25:$type sequence" } = $self->{'ext_url'}->get_url( 'FASTAVIEW', { 'FASTADB' => $string, 'ID' => $id } );
      $href = $zmenu->{ "20:$type sequence" } unless defined($href);
    }
  }

  $href = $f->das_link() if $f->das_link() && !$href;
  if($id && uc($id) ne 'NULL') {
    $zmenu->{"01:ID: $id"} = '';
    if($self->{'extras'}->{'linkURL'}){
      $href = $zmenu->{"22:".$self->{'link_text'}} = $self->{'ext_url'}->get_url( $self->{'extras'}->{'linkURL'}, $id );
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
    my $bp_textwidth = $self->{'textwidth'} * length($text) * 1.2; # add 10% for scaling text
    return unless $bp_textwidth < ($end - $start);

    my $y_offset = ($row_height - $self->{'textheight'})/2;
    my $tglyph = new Sanger::Graphics::Glyph::Text({
      'x'          => ( $end + $start - 1 - $bp_textwidth)/2,
      'y'          => $y_offset,
      'width'      => $bp_textwidth,
      'height'     => $self->{'textheight'},
      'font'       => 'Tiny',
      'colour'     => $self->{'config'}->colourmap->contrast($feature_colour),
      'text'       => $text,
      'absolutey'  => 1,
    });
    $composite->push($tglyph);
    return 0;
  } 
  elsif( uc($self->{'extras'}->{'labelflag'}) eq 'U') {	# draw Under feature
    my $bp_textwidth = $self->{'textwidth'} * length($text) * 1.2; # add 10% for scaling text
    my $y_offset = ($row_height + $glyph_height)/2;
    $y_offset += 2; # give a couple of pixels gap under the glyph
    my $tglyph = new Sanger::Graphics::Glyph::Text({
      'x'          => $start -1,
      'y'          => $y_offset,
      'width'      => $bp_textwidth,
      'height'     => $self->{'textheight'},
      'font'       => 'Tiny',
      'colour'     => $feature_colour,
      'text'       => $text,
      'absolutey'  => 1,
    });
    $composite->push($tglyph);
    return $self->{'textheight'} + 4;
  } 
  else {
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
  my $strand = $Config->get($das_config_key, 'str');
  my $Extra  = $self->{'extras'};

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
    'colour'   => $Config->get($das_config_key, 'col') || 'contigblue1',
    'depth'    => $Config->get($das_config_key, 'dep') || 4,
    'use_style'=> $Config->get($das_config_key, 'stylesheet') eq 'Y',
    'labelling'=> $Extra->{'labelflag'} =~ /^[ou]$/i ? 1 : 0,

  };

  my $dsn = $Extra->{'dsn'};
  my $url = defined($Extra->{'url'}) ? $Extra->{'url'}."/$dsn" :  $Extra->{'protocol'}.'://'. $Extra->{'domain'} ."/$dsn";

  my $srcname = $Extra->{'label'} || $das_name;
  $srcname =~ s/^(managed_|mananged_extdas)//;
  my $dastype = $Extra->{'type'} || 'ensembl_location';
  my @das_features = ();

  $configuration->{colour} = $Config->get($das_config_key, 'col') || $Extra->{color} || 'contigblue1';
  $configuration->{depth} =  defined($Config->get($das_config_key, 'dep')) ? $Config->get($das_config_key, 'dep') : $Extra->{depth} || 4;
  $configuration->{use_style} = $Extra->{stylesheet} ? uc($Extra->{stylesheet}) eq 'Y' : uc($Config->get($das_config_key, 'stylesheet')) eq 'Y';
  $configuration->{labelling} = $Extra->{labelflag} =~ /^[ou]$/i ? 1 : 0;
  $configuration->{length} = $container_length;

#  warn("$das_config_key:".$Config->get($das_config_key, 'stylesheet'));
#  warn(Dumper($Extra));
  $self->{'pix_per_bp'}    = $Config->transform->{'scalex'};
  $self->{'bitmap_length'} = int(($configuration->{'length'}+1) * $self->{'pix_per_bp'});
  ($self->{'textwidth'},$self->{'textheight'}) = $Config->texthelper()->real_px2bp('Tiny');
  $self->{'textwidth'}     *= (1 + 1/($container_length||1) );
  $configuration->{'h'} = $self->{'textheight'};

  my $styles;

  if ($dastype ne 'ensembl_location') {
      my $ga =  $self->{'container'}->adaptor->db->get_GeneAdaptor();
      my $genes = $ga->fetch_all_by_Slice( $self->{'container'});
      my $name = $das_name || $url;
      foreach my $gene (@$genes) {
#                      warn("GENE:$gene:".$gene->stable_id);       
         next if ($gene->strand != $self->strand);
         my $dasf = $gene->get_all_DASFeatures;
         my %dhash = %{$dasf};

        
         my $fcount = 0;
         my %fhash = ();
         my @aa = @{$dhash{$name}};
         foreach my $f (grep { $_->das_type_id() !~ /^(contig|component|karyotype)$/i &&  $_->das_type_id() !~ /^(contig|component|karyotype):/i } @{ $aa[1] || [] }) {
             if ($f->das_end) {
                if (($f->das_end + $gene->start) > 0 && ($f->das_start <= $configuration->{'length'})) {
                   $f->das_orientation or $f->das_orientation($gene->strand);
                   $f->das_start($f->das_start + $gene->start);
                   $f->das_end($f->das_end + $gene->start);
                   push(@das_features, $f);
                }
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
#                              warn("FT:$key:".$fhash{$key}->{count});
             my $ft = $fhash{$key}->{feature}; 
             if ((my $count = $fhash{$key}->{count}) > 1) {
                $ft->{das_feature_label} = "$key/$count";

                $ft->{das_note} = "Found $count annotations for $key";
                $ft->{das_link_label}  = 'View annotations in geneview';
                $ft->{das_link} = "/$ENV{ENSEMBL_SPECIES}/geneview?db=core&gene=$key&:DASselect_${srcname}=0&DASselect_${srcname}=1#$srcname";
                
             }
             $ft->{das_type_id}->{id} = 'summary';
             $ft->{das_start} = $gene->start;
             $ft->{das_end} = $gene->end;
             $ft->{das_orientation} = $gene->strand;
             $ft->{_gsf_strand} = $gene->strand;
             $ft->{das_strand} = $gene->strand;
             
             #         warn(Dumper($ft));
             push(@das_features, $ft);
         }
      }
  } else {
    my( $features, $das_styles ) = @{$self->{'container'}->get_all_DASFeatures->{$dsn}||[]};
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
	$styleheight = $_->{'attrs'}{'height'} if $_->{'attrs'}{'height'} > $styleheight;
      }
    } 
    $configuration->{'h'} = $styleheight if $styleheight;
    $configuration->{'styles'} = \%styles;
  } else {
    $configuration->{'use_style'} = 0;
  }

  $self->{'link_text'}    = $Extra->{'linktext'} || 'Additional info';
  $self->{'ext_url'}      = ExtURL->new( $Extra->{'name'} =~ /^managed_extdas/ ? ($Extra->{'linkURL'} => $Extra->{'linkURL'}) : () );


  $self->{helplink} = $Config->get($das_config_key, 'helplink');
  my $renderer = $Config->get($das_config_key, 'renderer');
#  my $group = ($Config->get($das_config_key, 'group') ? 'RENDER_grouped' : 'RENDER_simple';
	       
  my $group = uc($Config->get($das_config_key, 'group') || 'N');
  $renderer = $renderer ? "RENDER_$renderer" : ($group eq 'N' ? 'RENDER_simple' : 'RENDER_grouped');  

  $renderer =~ s/RENDER_RENDER/RENDER/;

  #warn("RENDER:[$das_config_key: $group] $renderer");
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
  $zmenu->{"03:".$f->das_link_label()     } = $f->das_link() if $f->das_link() && uc($f->das_link()) ne 'NULL';

  if($note && uc($note) ne 'NULL') {
    $zmenu->{"01:INFO: $note"} = '';
  } 
  return( $zmenu );
}


sub get_groupstyle {
    my ($self, $f, $configuration) = @_;
    my $group = $f->das_group_type;

    my $style;
    if($configuration->{'use_style'}) {
	$style = $configuration->{'styles'}{'group'}{$group};
	$style ||= $configuration->{'styles'}{'group'}{'default'};
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
	$style = $configuration->{'styles'}{$f->das_type_category}{$f->das_type_id};
	$style ||= $configuration->{'styles'}{$f->das_type_category}{'default'};
	$style ||= $configuration->{'styles'}{'default'}{'default'};
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

    # Load the glyph symbol module that we need to draw this style
    $glyph_symbol = 'Bio::EnsEMBL::Glyph::Symbol::'.$glyph_symbol;
    unless ($self->dynamic_use($glyph_symbol)){
	$glyph_symbol = 'Bio::EnsEMBL::Glyph::Symbol::box';
    }
    
    # vertically centre symbol in centre of row
    my $row_height = $featuredata->{'row_height'};
    my $glyph_height = $style->{'attrs'}{'height'};
    $y_offset = $y_offset + ($row_height - $glyph_height)/2;
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

1;
