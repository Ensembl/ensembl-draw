package Bio::EnsEMBL::GlyphSet::generic_alignment;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Composite;
use Sanger::Graphics::Bump;

@ISA = qw(Bio::EnsEMBL::GlyphSet);

sub init_label {
  my ($self) = @_;
  return if( defined $self->{'config'}->{'_no_label'} );
  my $HELP_LINK = 'compara_alignment';
  my $code      = $self->check();
  $self->label( new Sanger::Graphics::Glyph::Text({
    'text'      => $self->{'config'}->get($code,'label')||'---',
    'font'      => 'Small',
    'absolutey' => 1,
    'title'     => $self->{'config'}->get($code,'title')||$self->{'config'}->get($code,'label')||'',
    'href'      => qq[javascript:X=hw('@{[$self->{container}{_config_file_name_}]}','$ENV{'ENSEMBL_SCRIPT'}','$HELP_LINK')],
    'zmenu'     => {
      'caption'                 => 'HELP',
      "01:Track information..." => qq[javascript:X=hw(\'@{[$self->{container}{_config_file_name_}]}\',\'$ENV{'ENSEMBL_SCRIPT'}\',\'$HELP_LINK\')]
    }
  }));
  $self->bumped( $self->{'config'}->get($code, 'compact') ? 'no' : 'yes' ) unless $self->{'config'}{'compara'};
}

sub colour   { return $_[0]->{'feature_colour'}, $_[0]->{'label_colour'}, $_[0]->{'part_to_colour'}; }

sub _init {
  my ($self) = @_;
  my $type = $self->check();
  return unless defined $type;  ## No defined type arghhh!!

  my $strand = $self->strand;
  my $Config = $self->{'config'};
  my $strand_flag    = $Config->get($type, 'str');
  return if( $strand_flag eq 'r' && $strand != -1 || $strand_flag eq 'f' && $strand != 1 );

  if( $Config->get($type,'compact') ) {
    $self->compact_init($type);
  } else {
    $self->expanded_init($type);
  }
}

sub expanded_init {
  my ($self,$type) = @_;
  my $WIDTH          = 1e5;
  my $container      = $self->{'container'};
  my $Config         = $self->{'config'};
  my $strand         = $self->strand();
  my $strand_flag    = $Config->get($type, 'str');

  my $caption        = $Config->get($type,'title')||$Config->get($type,'label')||'Comparative alignment';
  my %highlights;
  @highlights{$self->highlights()} = ();
  my $length         = $container->length;
  my @bitmap         = undef;
  my $pix_per_bp     = $Config->transform()->{'scalex'};
  my $DRAW_CIGAR     = $pix_per_bp > 0.2 ;
  my $bitmap_length  = int($length * $pix_per_bp);
  my $feature_colour = $Config->get($type, 'col');
  my $join_col       = $Config->get($type, 'join_col') || 'gold'; 
  my $join_z         = $Config->get($type, 'join_z') || 10;
  my $hi_colour      = $Config->get($type, 'hi');
  my %id             = ();
  my $small_contig   = 0;
  my $dep            = $Config->get($type, 'dep');
  my $h              = $Config->get('_settings','opt_halfheight') ? 4 : 8;
  my $chr       = $self->{'container'}->seq_region_name;
  my $other_species  = $Config->get($type, 'species' );
  ( my $species_2    = $other_species ) =~ s/_ / /g;
  my $self_species   = $container->{_config_file_name_};
  my $compara        = $self->{'config'}{'compara'};
  my $link = 0;
  my $TAG_PREFIX;
  my $METHOD         = $Config->get($type, 'method' );
  if( $compara) {
    $link = $Config->get($type,'join');
    $TAG_PREFIX  = uc( $compara eq 'primary' ? 
                       join ( '_', $METHOD, $self_species, $other_species ) :
                       join ( '_', $METHOD, $other_species, $self_species ) );
  } 
  my ($T,$C1,$C) = (0, 0, 0 ); ## Diagnostic counters....
  my $K = 0;

  warn ">>>>> $other_species $METHOD <<<<<";
  foreach my $f ( @{$self->features( $other_species, $METHOD )} ){
    next if $strand_flag eq 'b' && $strand != $f->hstrand || $f->end < 1 || $f->start > $length ;
    push @{$id{$f->hseqname().':'. ($f->group_id||("00".$K++)) }}, [$f->start,$f];
  }


## Now go through each feature in turn, drawing them
  my @glyphs;
  my $BLOCK = 0;
  my $script = $ENV{'ENSEMBL_SCRIPT'} eq 'multicontigview' ? 'contigview' : $ENV{'ENSEMBL_SCRIPT'};
  my $SHORT = $self->species_defs->ENSEMBL_SHORTEST_ALIAS->{ $Config->get( $type, 'species' ) };
  my $HREF  = $Config->get( $type, 'linkto' )."/$SHORT/$script";

  # sort alignments by size
  my @s_i = sort {($id{$b}[0][1]->hend() - $id{$b}[0][1]->hstart()) <=> ($id{$a}[0][1]->hend() - $id{$a}[0][1]->hstart())} keys %id;
  foreach my $i (@s_i){
    my @F = sort { $a->[0] <=> $b->[0] } @{$id{$i}};
    $T+=@F; ## Diagnostic report....
    my( $seqregion,$group ) = split /:/, $i;
    my $START = $F[0][0] < 1 ? 1 : $F[0][0];
    my $END   = $F[-1][1]->end > $length ? $length : $F[-1][1]->end;
    my $start = $F[0][1]->hstart();
    my $end   = $F[0][1]->hend();
    my $bump_start = int($START * $pix_per_bp) -1 ;
       $bump_start = 0 if $bump_start < 0;
    my $bump_end   = int($END * $pix_per_bp);
       $bump_end   = $bitmap_length if $bump_end > $bitmap_length;
    my $row = & Sanger::Graphics::Bump::bump_row( $bump_start, $bump_end, $bitmap_length, \@bitmap, $dep );
    next if $row > $dep;
    my $y_pos = - $row * int( 1.5 * $h ) * $strand;
    $C1 += @{$id{$i}}; ## Diagnostic report....
    my $Composite = new Sanger::Graphics::Glyph::Composite({
      'x'     => $F[0][0]> 1 ? $F[0][0]-1 : 0,
      'width' => 0,
      'y' => 0
    });
    my $X = -1000000;
    foreach  ( @F ){
      my $f = $_->[1];
      $start = $f->hstart() if $f->hstart < $start;
      $end   = $f->hend()   if $f->hend   > $end;
      next if int($f->end * $pix_per_bp) <= int( $X * $pix_per_bp );
      $C++;
      if($DRAW_CIGAR) {
        $self->draw_cigar_feature($Composite, $f, $h, $feature_colour, 'black', $pix_per_bp, 1 );
      } else {
        my $START = $_->[0] < 1 ? 1 : $_->[0];
        my $END   = $f->end > $length ? $length : $f->end;
        $X = $END;
        my $BOX = new Sanger::Graphics::Glyph::Rect({
          'x'          => $START-1,
          'y'          => 0,
          'width'      => $END-$START+1,
          'height'     => $h,
          'colour'     => $feature_colour,
          'absolutey'  => 1,
        });
        if( $strand_flag eq 'z' && $join_col) {
          $self->join_tag( $BOX, "BLOCK_$type$BLOCK", $strand == -1 ? 0 : 1, 0 , $join_col, 'fill', $join_z ) ;
          $self->join_tag( $BOX, "BLOCK_$type$BLOCK", $strand == -1 ? 1 : 0, 0 , $join_col, 'fill', $join_z ) ;
#warn "BLOCK_$type$BLOCK";
          $BLOCK++;
        }
        $Composite->push($BOX);
      }
    }
    if( ($compara eq 'primary' || $compara eq 'secondary') && $link ) {
      my $Z = $strand == -1 ? 1 : 0;
      foreach( @F ) {
        my $f = $_->[1];
        my( $start, $end, $start2,$end2) = ( $f->hstart, $f->hend, $f->start, $f->end );
        my( $start3, $end3 ) = $self->slice2sr( $start2, $end2 );
        my $S = $start2 < $Composite->x ? 0 : ( $start2 - $Composite->x ) / $Composite->width;
        my $E = $end2   > $Composite->x+$Composite->width ? 1 : ( $end2 - $Composite->x ) / $Composite->width;
        if( $strand != -1 ) {
          my $TAG = $Config->{'slice_id'}."$TAG_PREFIX.$start.$end:$start3.$end3.$strand";
          $self->join_tag( $Composite, $TAG, $S, $Z, $join_col, 'fill', $join_z );
          $self->join_tag( $Composite, $TAG, $E, $Z, $join_col, 'fill', $join_z );
        } else {
          my $TAG = ($Config->{'slice_id'}+1)."$TAG_PREFIX.$start3.$end3:$start.$end.".(-$strand);
          $self->join_tag( $Composite, $TAG, $E, $Z, $join_col, 'fill', $join_z );
          $self->join_tag( $Composite, $TAG, $S, $Z, $join_col, 'fill', $join_z );
        }
      }
    }
    $Composite->y( $Composite->y + $y_pos );
    $Composite->bordercolour($feature_colour);
    my $ZZ;
    if($end-$start<$WIDTH) {
      my $X =int(( $start + $end - $WIDTH) /2);
      my $Y = $X + $WIDTH ;
      $ZZ = "l=$seqregion:$X-$Y";
    } else {
      $ZZ = "l=$seqregion:$start-$end";
    }
    $Composite->href(  "$HREF?$ZZ" );

	#decide whether to jump within or between species;
	my $jump_type = $self_species eq $species_2 ? "chromosome $seqregion" : $species_2;

    $Composite->zmenu( {
      'caption' => $caption,
      "01:$seqregion: $start-$end" => '',
      "02:Jump to $jump_type"        => "$HREF?$ZZ",
      "03:Orientation: @{[ $F[0][1]->hstrand * $F[0][1]->strand>0 ? 'Forward' : 'Reverse' ]}"         => ''
    } );
    $self->push( $Composite );
    if(exists $highlights{$i}) {
      $self->unshift(new Sanger::Graphics::Glyph::Rect({
        'x'         => $Composite->x() - 1/$pix_per_bp,
        'y'         => $Composite->y() - 1,
        'width'     => $Composite->width() + 2/$pix_per_bp,
        'height'    => $h + 2,
        'colour'    => $hi_colour,
        'absolutey' => 1,
      }));
    }
  }
## No features show "empty track line" if option set....
  $self->errorTrack( "No ". $self->{'config'}->get($type,'label')." features in this region" ) unless( $C || $Config->get('_settings','opt_empty_tracks')==0 );
  0 && warn( ref($self), " $C out of a total of ($C1 unbumped) $T glyphs" );
}

sub compact_init {
  my ($self,$type) = @_;
  my $WIDTH          = 1e5;
  my $container      = $self->{'container'};
  my $Config         = $self->{'config'};
  my $caption        = $Config->get($type,'title')||$Config->get($type,'label')||'Comparative alignment';
  my $strand         = $self->strand();
  my $strand_flag    = $Config->get($type, 'str');
  my %highlights;
  @highlights{$self->highlights()} = ();
  my $length         = $container->length;
  my $pix_per_bp     = $Config->transform()->{'scalex'};
  my $DRAW_CIGAR     = $pix_per_bp > 0.2 ;
  my $feature_colour = $Config->get($type, 'col');
  my $join_col       = $Config->get($type, 'join_col') || 'gold';
  my $join_z         = $Config->get($type, 'join_z') || 10;
  my $hi_colour      = $Config->get($type, 'hi');
  my %id             = ();
  my $small_contig   = 0;
  my $dep            = $Config->get($type, 'dep');
  my $h              = $Config->get('_settings','opt_halfheight') ? 4 : 8;
  my $chr       = $self->{'container'}->seq_region_name;
  my $other_species  = $Config->get($type, 'species' );
  ( my $species_2    = $other_species ) =~ s/_ / /g;
  my $short_other    = $Config->species_defs->ENSEMBL_SHORTEST_ALIAS->{ $other_species };
  my $self_species   = $container->{_config_file_name_};
  my $short_self     = $Config->species_defs->ENSEMBL_SHORTEST_ALIAS->{ $self_species };
  my $compara        = $self->{'config'}{'compara'};
  my $link = 0;
  my $TAG_PREFIX;

  my $METHOD         = $Config->get($type, 'method' );
  my $COMPARA_HTML_EXTRA = '';
  my $MULTICONTIGVIEW_TEXT_LINK = 'MultiContigView';
  if( $compara) {
    $link = $Config->get($type,'join');
    $TAG_PREFIX  = uc( $compara eq 'primary' ?
                       join ( '_', $METHOD, $self_species, $other_species ) :
                       join ( '_', $METHOD, $other_species, $self_species ) );
    my $C=1;
    foreach my $T ( @{$Config->{'other_slices'}||[]} ) {
      if( $T->{'species'} ne $self_species && $T->{'species'} ne $other_species ) {
        $C++;
        $COMPARA_HTML_EXTRA.=";s$C=".$Config->species_defs->ENSEMBL_SHORTEST_ALIAS->{ $T->{'species'} };
      }
    }
    $MULTICONTIGVIEW_TEXT_LINK = 'Centre on this match';
  }

  my( $T,$C1,$C) = (0, 0, 0 ); ## Diagnostic counters....
  my $domain = $Config->get( $type, 'linkto' );
  my $HREF_TEMPLATE = "/$short_self/dotterview?c=$chr:%d;s1=$other_species;c1=%s:%d";
  my $X = -1e8;
  my $CONTIGVIEW_TEXT_LINK =  $compara ? 'Jump to ContigView' : 'Centre on this match' ;
  my $MCV_TEMPLATE  = "/$short_self/multicontigview?c=%s:%d;w=%d;s1=$short_other;c1=%s:%d;w1=%d$COMPARA_HTML_EXTRA";
  
  warn "!>>>>> $other_species $METHOD <<<<<";
  my @T = sort { $a->[0] <=> $b->[0] }
    map { [$_->start, $_ ] }
    grep { !( ($strand_flag eq 'b' && $strand != $_->hstrand) ||
              ($_->start > $length) ||
              ($_->end < 1)
         ) } @{$self->features( $other_species, $METHOD )};
  foreach (@T) {
    my $f       = $_->[1];
    my $START   = $_->[0];
    my $END     = $f->end;
    ($START,$END) = ($END, $START) if $END<$START; # Flip start end YUK!
    my( $rs, $re ) = $self->slice2sr( $START, $END );
    $START      = 1 if $START < 1;
    $END        = $length if $END > $length;
    $T++; $C1++;
    next if int( $END * $pix_per_bp ) == int( $X * $pix_per_bp );
    $X = $START;
    $C++;
    my @X = (
      [ $chr, int(($rs+$re)/2) ],
      [ $f->hseqname, int(($f->hstart + $f->hend)/2) ],
      int($WIDTH/2),
      "@{[$f->hseqname]}:@{[$f->hstart]}-@{[$f->hend]}", 
      "$chr:$rs-$re"
    );
    my $TO_PUSH;
    my $chr_2 = $f->hseqname; 
    my $s_2   = $f->hstart;
    my $e_2   = $f->hend;
    my $href  = '';
    #z menu links depend on whether jumping within or between species;
    my $jump_type;
    if( $self->species_defs->ENSEMBL_SITETYPE eq 'Vega' ) { #st3 - checked and OK
      if( $self_species eq $species_2 ) {
        $jump_type = "chromosome $chr_2";
        if( $compara ) {			
          $CONTIGVIEW_TEXT_LINK = "Go to chromosome $chr";
        }
      } else {	
        $jump_type = "$other_species chr $chr_2";
        if( $compara) {			
          $CONTIGVIEW_TEXT_LINK = "Go to $self_species chr $chr";
        }
      }
    } else {
      $jump_type = $species_2;
    }

    my $zmenu = { 'caption'              => $caption,
                  "01:$chr_2:$s_2-$e_2"     => '',
                  "02:Jump to $jump_type"   => "$domain/$short_other/contigview?l=$chr_2:$s_2-$e_2",
                  "03:$CONTIGVIEW_TEXT_LINK"  => "/$short_self/contigview?l=$chr:$rs-$re" };

    unless( $domain ) {
      $href = sprintf $HREF_TEMPLATE, ($rs+$re)/2, $chr_2, ($s_2 + $e_2)/2;
      $zmenu->{ '04:Dotter' }    = $href;
      $zmenu->{ '05:Alignment' } = "/$self_species/alignview?class=DnaDnaAlignFeature;l=$chr:$rs-$re;s1=$other_species;l1=$chr_2:$s_2-$e_2;type=$METHOD";
      $zmenu->{ "06:$MULTICONTIGVIEW_TEXT_LINK" } = sprintf( $MCV_TEMPLATE, $chr, ($rs+$re)/2, $WIDTH/2, $chr_2, ($s_2+$e_2)/2, $WIDTH/2 );
    }
    $zmenu->{ '99:Orientation: '.($f->hstrand * $f->strand>0?'Forward' : 'Reverse' ) } = undef;
    if($DRAW_CIGAR) {
      $TO_PUSH = new Sanger::Graphics::Glyph::Composite({
        'href'  => $href,
        'zmenu' => $zmenu,
#        'zmenu' => $self->unbumped_zmenu( @X , 'Orientation: '.($f->hstrand * $f->strand>0?'Forward' : 'Reverse' ), $f->{'alignment_type'} ) ,
        'x'     => $START-1,
        'width' => 0,
        'y'     => 0
      });
      $self->draw_cigar_feature($TO_PUSH, $f, $h, $feature_colour, 'black', $pix_per_bp, 1 );
      $TO_PUSH->bordercolour($feature_colour);
    } else {
      $TO_PUSH = new Sanger::Graphics::Glyph::Rect({
        'x'          => $START-1,
        'y'          => 0,
        'width'      => $END-$START+1,
        'height'     => $h,
        'colour'     => $feature_colour,
        'absolutey'  => 1,
        '_feature'   => $f, 
        'href'  => $href,
        'zmenu' => $zmenu,
      });
    }
    if( ($compara eq 'primary' || $compara eq 'secondary') && $link ) {
      my( $start, $end, $start2,$end2) = ( $f->hstart, $f->hend, $f->start, $f->end );
      my( $start2, $end2 ) = $self->slice2sr( $start2, $end2 );
      my $Z = $strand == -1 ? 1 : 0;
      if( $strand != -1 ) {
        my $TAG = $Config->{'slice_id'}."$TAG_PREFIX.$start.$end:$start2.$end2.$strand";
        $self->join_tag( $TO_PUSH, $TAG, 0, $Z, $join_col, 'fill', $join_z );
        $self->join_tag( $TO_PUSH, $TAG, 1, $Z, $join_col, 'fill', $join_z );
      } else {
        my $TAG = ($Config->{'slice_id'}+1)."$TAG_PREFIX.$start2.$end2:$start.$end.".(-$strand);
        $self->join_tag( $TO_PUSH, $TAG, 1, $Z, $join_col, 'fill', $join_z );
        $self->join_tag( $TO_PUSH, $TAG, 0, $Z, $join_col, 'fill', $join_z );
      }
    }
    $self->push( $TO_PUSH );
  }
## No features show "empty track line" if option set....
  $self->errorTrack( "No ". $self->{'config'}->get($type,'label')." features in this region" ) unless( $C || $Config->get('_settings','opt_empty_tracks')==0 );
  0 && warn( ref($self), " $C out of a total of ($C1 unbumped) $T glyphs" );
}

1;

use Time::HiRes qw(time);
sub features {
  my ($self, $species, $method ) = @_;
  (my $species_2 = $species) =~ s/_/ /; 
  my $assembly = $self->species_defs->other_species($species,'ENSEMBL_GOLDEN_PATH');
  my $START = time();
  Bio::EnsEMBL::Registry->add_alias("Multi","compara");
  my $T = $self->{'container'}->get_all_compara_DnaAlignFeatures( $species_2, $assembly, $method );
  warn "generic_alignment - $method $species ",time()-$START;
  return $T;
}

