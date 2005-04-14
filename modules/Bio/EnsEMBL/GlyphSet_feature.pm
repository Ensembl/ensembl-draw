package Bio::EnsEMBL::GlyphSet_feature;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Composite;
use  Sanger::Graphics::Bump;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Data::Dumper;

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
      "02:Track information..."     => qq[javascript:X=hw(\'@{[$self->{container}{_config_file_name_}]}\',\'$ENV{'ENSEMBL_SCRIPT'}\',\'$HELP_LINK\')]
    }
  });
  if( $self->{'extras'} && $self->{'extras'}{'description'} ) {
    $label->{'zmenu'}->{'01:'.CGI::escapeHTML($self->{'extras'}{'description'})} = ''; 
  }
  $self->label($label);
  unless ($self->{'config'}->get($HELP_LINK, 'bump') eq 'always') {
    $self->bumped( $self->{'config'}->get($HELP_LINK, 'compact') ? 'no' : 'yes' );
  }
}


sub colour   { return $_[0]->{'feature_colour'}, $_[0]->{'label_colour'}, $_[0]->{'part_to_colour'}; }
sub my_label { return 'Missing label'; }
sub features { return (); } 
sub zmenu    { return { 'caption' => $_[0]->check(), "$_[1]" => "Missing caption" }; }
sub href     { return undef; }

## Returns the 'group' that a given feature belongs to. Features in the same
## group are linked together via an open rectangle. Can be subclassed.
sub feature_group{
  my( $self, $f ) = @_;
  return $f->display_id;
}

sub _init {
  my ($self) = @_;
  my $type = $self->check();
  return unless defined $type;  ## No defined type arghhh!!

  my $strand = $self->strand;
  my $Config = $self->{'config'};
  my $strand_flag    = $Config->get($type, 'str');
  return if( $strand_flag eq 'r' && $strand != -1 || $strand_flag eq 'f' && $strand != 1 );
  $self->{'colours'} = $Config->get( $type, 'colour_set' ) ? 
    { $Config->{'_colourmap'}->colourSet( $Config->get( $type, 'colour_set' ) ) } :
    $Config->get( $type, 'colours' );
  $self->{'feature_colour'} = $Config->get($type, 'col') || $self->{'colours'} && $self->{'colours'}{'col'};
  $self->{'label_colour'}   = $Config->get($type, 'lab') || $self->{'colours'} && $self->{'colours'}{'lab'};
  $self->{'part_to_colour'} = '';

  if( $Config->get($type,'compact') ) {
    $self->compact_init($type);
  } else {
    $self->expanded_init($type);
  }
}

sub expanded_init {
  my($self,$type) = @_;

## Information about the container...
  my $length = $self->{'container'}->length();
  my $strand = $self->strand;
## And now about the drawing configuration
  my $Config = $self->{'config'};
  my $strand_flag    = $Config->get($type, 'str');
  my $pix_per_bp     = $Config->transform()->{'scalex'};
  my $DRAW_CIGAR     = ( $Config->get($type,'force_cigar') eq 'yes' )|| ($pix_per_bp > 0.2) ;
## Highlights...
  my %highlights = map { $_,1 } $self->highlights;

  my $hi_colour = $Config->get($type, 'hi');
  $hi_colour  ||= $self->{'colours'} ? $self->{'colours'}{'hi'} : 'black';

## Bumping bitmap...
  my @bitmap         = undef;
  my $bitmap_length  = int($length * $pix_per_bp);

  my %id             = ();
  my $dep            = $Config->get(  $type, 'dep' );
  my $h              = $Config->get('_settings','opt_halfheight') ? 4 : 8;
  my ($T,$C1,$C) = (0, 0, 0 );

## Get array of features and push them into the id hash...
  foreach my $features ( grep { ref($_) eq 'ARRAY' } $self->features ) {
    foreach my $f ( @$features ){
      my $hstrand  = $f->can('hstrand')  ? $f->hstrand : 1;
      my $fgroup_name = $self->feature_group( $f );
      next if $strand_flag eq 'b' && $strand != ( $hstrand*$f->strand || -1 ) || $f->end < 1 || $f->start > $length ;
      push @{$id{$fgroup_name}}, [$f->start,$f->end,$f];
    }
  }

## Now go through each feature in turn, drawing them
  my $y_pos;
  my $n_bumped = 0;
  foreach my $i (keys %id){
    $T+=@{$id{$i}}; ## Diagnostic report....
    my @F = sort { $a->[0] <=> $b->[0] } @{$id{$i}};
    my $START = $F[0][0] < 1 ? 1 : $F[0][0];
    my $END   = $F[-1][1] > $length ? $length : $F[-1][1];
    my $bump_start = int($START * $pix_per_bp) - 1;
       $bump_start = 0 if $bump_start < 0;
    my $bump_end   = int($END * $pix_per_bp);
       $bump_end   = $bitmap_length if $bump_end > $bitmap_length;
    my $row = & Sanger::Graphics::Bump::bump_row( $bump_start, $bump_end, $bitmap_length, \@bitmap, $dep );
    if( $row > $dep ) {
      $n_bumped++;
      next;
    }
    $y_pos = $row * int( -1.5 * $h ) * $strand;
    $C1 += @{$id{$i}}; ## Diagnostic report....
    my $Composite = new Sanger::Graphics::Glyph::Composite({
      'href'  => $self->href( $i, $id{$i} ),
      'x'     => $F[0][0]> 1 ? $F[0][0]-1 : 0,
      'width' => 0,
      'y'     => 0,
      'zmenu'    => $self->zmenu( $i, $id{$i} ),
    });
    my $X = -1000000;
    #my ($feature_colour, $label_colour, $part_to_colour) = $self->colour( $F[0][2]->display_id );
    my ($feature_colour, $label_colour, $part_to_colour) = $self->colour( $F[0][2]->display_id, $F[0][2] );
    $feature_colour ||= 'black';
    foreach my $f ( @F ){
      next if int($f->[1] * $pix_per_bp) <= int( $X * $pix_per_bp );
      $C++;
      if($DRAW_CIGAR) {
        $self->draw_cigar_feature($Composite, $f->[2], $h, $feature_colour, 'black', $pix_per_bp );
      } else {
        my $START = $f->[0] < 1 ? 1 : $f->[0];
        my $END   = $f->[1] > $length ? $length : $f->[1];
        $X = $END;
        $Composite->push(new Sanger::Graphics::Glyph::Rect({
          'x'          => $START-1,
          'y'          => 0, # $y_pos,
          'width'      => $END-$START+1,
          'height'     => $h,
          'colour'     => $feature_colour,
          'absolutey'  => 1,
        }));
      }
    }
    $Composite->y( $Composite->y + $y_pos );
    $Composite->bordercolour($feature_colour);
    $self->push( $Composite );
    if(exists $highlights{$i}) {
      $self->unshift( new Sanger::Graphics::Glyph::Rect({
        'x'         => $Composite->{'x'} - 1/$pix_per_bp,
        'y'         => $Composite->{'y'} - 1,
        'width'     => $Composite->{'width'} + 2/$pix_per_bp,
        'height'    => $h + 2,
        'colour'    => $hi_colour,
        'absolutey' => 1,
      }));
    }
  }
## No features show "empty track line" if option set....
  $self->errorTrack( "No ".$self->my_label." features in this region" ) unless( $C || $Config->get('_settings','opt_empty_tracks')==0 );
  if( $Config->get('_settings','opt_show_bumped') && $n_bumped ) {
    my $ypos = 0;
    if( $strand < 0 ) {
      $y_pos = ($dep+1) * int( 1.5 * $h ) + 2;
    } else {
      $y_pos  = 2 + $self->{'config'}->texthelper()->height('Tiny');
    }
    $self->errorTrack( "$n_bumped ".$self->my_label." omitted", undef, $y_pos );
  }
  0 && warn( ref($self), " $C out of a total of ($C1 unbumped) $T glyphs" );
}

sub compact_init {
  my($self,$type) = @_;
  my $length = $self->{'container'}->length();
  my $strand = $self->strand;
  my $Config = $self->{'config'};
  my $strand_flag    = $Config->get($type, 'str');
  my $pix_per_bp     = $Config->transform()->{'scalex'};
  my $DRAW_CIGAR     = ( $Config->get($type,'force_cigar') eq 'yes' )|| ($pix_per_bp > 0.2) ;

  my $h              = 8;

  my ($T,$C1,$C) = (0, 0, 0 );

  my $X = -1e8;
  foreach my $f (
    sort { $a->[0] <=> $b->[0]      }
    map  { [$_->start, $_->end,$_ ] }
    grep { !($strand_flag eq 'b' && $strand != ( ( $_->can('hstrand') ? $_->hstrand : 1 ) * $_->strand||-1) || $_->start > $length || $_->end < 1) } 
    map  { @$_                      }
    grep { ref($_) eq 'ARRAY'       } $self->features
  ) {
    my $START   = $f->[0];
    my $END     = $f->[1];
    ($START,$END) = ($END, $START) if $END<$START; # Flip start end YUK!
    $START      = 1 if $START < 1;
    $END        = $length if $END > $length;
    $T++; $C1++;
    my ($feature_colour, $label_colour, $part_to_colour) = $self->colour( $f->[2]->display_id() );
    next if( $END * $pix_per_bp ) == int( $X * $pix_per_bp );
    $X = $START;
    $C++;
    if($DRAW_CIGAR) {
      $self->draw_cigar_feature($self, $f->[2], $h, $feature_colour, 'black', $pix_per_bp );
    } else {
      $self->push(new Sanger::Graphics::Glyph::Rect({
        'x'          => $X-1,
        'y'          => 0, # $y_pos,
        'width'      => $END-$X+1,
        'height'     => $h,
        'colour'     => $feature_colour,
        'absolutey'  => 1,
      }));
    }
  }
  $self->errorTrack( "No ".$self->my_label." features in this region" ) unless( $C || $Config->get('_settings','opt_empty_tracks')==0 );

  0 && warn( ref($self), " $C out of a total of ($C1 unbumped) $T glyphs" );
}

1;
