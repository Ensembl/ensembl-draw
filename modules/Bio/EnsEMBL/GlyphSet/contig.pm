package Bio::EnsEMBL::GlyphSet::contig;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Poly;
use Bio::EnsEMBL::Glyph::Space;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Composite;
use SiteDefs;
use ColourMap;

use constant MAX_VIEWABLE_ASSEMBLY_SIZE => 5e6;


sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
	    'text'      => 'DNA(contigs)',
    	'font'      => 'Small',
	    'absolutey' => 1,
        'href'      => qq[javascript:X=window.open(\'/$ENV{'ENSEMBL_SPECIES'}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#contig\',\'helpview\',\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\');X.focus();void(0)],

        'zmenu'     => {
            'caption'                     => 'HELP',
            "01:Track information..."     =>
qq[javascript:X=window.open(\\\'/$ENV{'ENSEMBL_SPECIES'}/helpview?se=1&kw=$ENV{'ENSEMBL_SCRIPT'}#contig\\\',\\\'helpview\\\',\\\'height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes\\\');X.focus();void(0)]
        }

    });
    $self->label($label);
}




sub _init {
  my ($self) = @_;

  # only draw contigs once - on one strand
  
  return unless ($self->strand() == 1);
  
  my $vc = $self->{'container'};
  my $length = $vc->length() +1;
  
  my $ystart = 3;
  
  my $gline = new Bio::EnsEMBL::Glyph::Rect({
	'x'         => 0,
        'y'         => $ystart + 7,
        'width'     => $length,
        'height'    => 0,
        'colour'    => $self->{'config'}->colourmap()->id_by_name('grey1'),
        'absolutey' => 1,
    });

  $self->push($gline);
  
  my @contig_tiling_path = $vc->get_tiling_path();
  
  my $useAssembly;
  eval {
    # Do we have assembly_contigs?
    $useAssembly = $vc->has_MapSet( 'assembly' ); 
  };
    
  if (!@contig_tiling_path) {
    ## Draw a warning track....
    $self->errorTrack("Golden path gap - no contigs to display!");
  } elsif($useAssembly && $length < MAX_VIEWABLE_ASSEMBLY_SIZE) {
    $self->_init_assembled_contig($ystart, \@contig_tiling_path);
  } else {
    $self->_init_non_assembled_contig($ystart, \@contig_tiling_path);
  }
}



sub _init_assembled_contig {
  my ($self, $ystart, $map_contigs) = @_;
  my @map_contigs;

  my $vc = $self->{'container'};
  my $length = $vc->length() +1;
  my $Config = $self->{'config'};


  my $module = ref($self);
  $module = $1 if $module=~/::([^:]+)$/;
  my $threshold_navigation = ($Config->get($module, 'threshold_navigation') 
			      || 2e6)*1001;
  my $navigation     = $Config->get($module, 'navigation') || 'on';
  my $show_navigation = ($length < $threshold_navigation) && ($navigation eq 'on');

  my $cmap     = $Config->colourmap();
  my $black    = $cmap->id_by_name('black');
  my $green    = $cmap->id_by_name('green');
  my $im_width = $Config->image_width();

  my ($w,$h)   = $Config->texthelper()->real_px2bp('Tiny');
  my $clone_based = $Config->get('_settings','clone_based') eq 'yes';
  my $param_string   = $clone_based ? $Config->get('_settings','clone') : ("chr=".$vc->chr_name());
  my $global_start   = $clone_based ? $Config->get('_settings','clone_start') : $vc->chr_start();
  my $global_end     = $global_start + $length - 1;


  my $i = 1;
    
  my %colours  = ( $i  => $cmap->id_by_name('contigblue1'), 
		     !$i => $cmap->id_by_name('contigblue2'));
  my %colours2 = ( $i  => $cmap->id_by_name('grey2'), 
		   !$i => $cmap->id_by_name('grey3'));

    
  $w *= $length/($length-1);

  my @assembly_contigs = $vc->get_all_MapFrags( 'assembly' );
  my %contigs = ();
  my %big_contigs = ();
  foreach my $big_contig ( @map_contigs ) {
    my $ID = $big_contig->contig->id();            
    $contigs{ $ID } = [];
    $big_contigs{ $ID } = [ $big_contig->start, $big_contig->end ];
    foreach my $little_contig (@assembly_contigs) {
      my $start = $little_contig->start;
      my $end   = $little_contig->end;
      if( $end   >= $big_contig->start || $start <= $big_contig->end ) {
	$start = $big_contig->start if $big_contig->start > $start;
	$end   = $big_contig->end   if $big_contig->end   < $end;
	push @{$contigs{$ID}}, [ $start, $end ]
      }
    }
  }
  
  my $FLAG = 0;
  
  foreach( sort { $big_contigs{$a}->[0] <=> $big_contigs{$b}->[0] } keys %contigs ) {
    my $composite = new Bio::EnsEMBL::Glyph::Composite({
				'y'            => $ystart-3,
				'x'            => $big_contigs{$_}->[0],
				'absolutey'    => 1
			});
    	

    if($show_navigation) {
      $composite->{'zmenu'} = {
		    "caption" => $_,
		    "Export this contig" => "/$ENV{'ENSEMBL_SPECIES'}/exportview?tab=fasta&type=feature&ftype=contig&id=$_"
		   }; 
    }
           
    my $col = $colours2{$i};
    my $glyph;

    if($FLAG) {
      $glyph = new Bio::EnsEMBL::Glyph::Rect({
                'x'         => $big_contigs{$_}->[0]-1,
                'y'         => $ystart-3,
                'width'     => 1,
                'height'    => 21,
                'colour'    => $green,
                'absolutey' => 1,
            }); 
    }
   
    $FLAG=1;
    $composite->push($glyph);
    $col = $colours{$i};
    $i      = !$i;
    foreach my $Q ( @{$contigs{$_}} ) {
      my $glyph = new Bio::EnsEMBL::Glyph::Rect({
                    'x'         => $Q->[0],
                    'y'         => $ystart+2,
                    'width'     => $Q->[1]-$Q->[0],
                    'height'    => 11,
                    'colour'    => $col,
                    'absolutey' => 1,
    			});
      
      $composite->push($glyph);
    }
     

    my $bp_textwidth = $w * length($_) * 1.2; # add 20% for scaling text
    #unless (1||$bp_textwidth > $composite->width() ) {
#      my $tglyph = new Bio::EnsEMBL::Glyph::Text({
#                    'x'          => int( (2 * $composite->x() + $composite->width() - $bp_textwidth)/2),
#                    'y'          => $ystart+5,
#                    'font'       => 'Tiny',
#                    'colour'     => $black,
#                    'text'       => $_,
#                    'absolutey'  => 1,
#                });

#      my $glyph = new Bio::EnsEMBL::Glyph::Rect({
#                    'x'          => int( (2 * $composite->x() + $composite->width() - $bp_textwidth)/2)-0.2/$w,
#                    'y'          => $ystart+5,
#                    'width'      => $bp_textwidth,
#                    'height'     => 7,
#                    'colour'     => $cmap->id_by_name('white'),
#                    'text'       => $_,
#                    'absolutey'  => 1,
#                });
         
#      $composite->push($glyph);
#      $composite->push($tglyph);
#    }
    $self->push($composite);
  }
}
 






sub _init_non_assembled_contig {
  my ($self, $ystart, $contig_tiling_path) = @_;

  my $gline;

  my $vc = $self->{'container'};
  my $length = $vc->length() +1;
  my $Config = $self->{'config'};

  my $module = ref($self);
  $module = $1 if $module=~/::([^:]+)$/;
  my $threshold_navigation = ($Config->get($module, 'threshold_navigation') 
			      || 2e6)*1001;
  my $navigation     = $Config->get($module, 'navigation') || 'on';
  my $show_navigation = ($length < $threshold_navigation) && ($navigation eq 'on');

  my $highlights = join('|', $self->highlights() ) ;
  $highlights = $highlights ? "&highlight=$highlights" : '';
  my $cmap     = $Config->colourmap();
  
  my $black    = $cmap->id_by_name('black');
  my $red      = $cmap->id_by_name('red');
  my $im_width = $Config->image_width();
  my ($w,$h)   = $Config->texthelper()->real_px2bp('Tiny');
  my $clone_based = $Config->get('_settings','clone_based') eq 'yes';
  my $param_string   = $clone_based ? $Config->get('_settings','clone') : ("chr=".$vc->chr_name());
  my $global_start   = $clone_based ? $Config->get('_settings','clone_start') : $vc->chr_start();
  my $global_end     = $global_start + $length - 1;
    
  my $i = 1;
    
  my %colours  = ( $i  => $cmap->id_by_name('contigblue1'), 
		   !$i => $cmap->id_by_name('contigblue2'));
  
  $w *= $length/($length-1);

  my $tot_width = @$contig_tiling_path[-1]->{'end'} - 
    @$contig_tiling_path[0]->{'start'} + 1;

  foreach my $tile ( @$contig_tiling_path ) {
    my $col = $colours{$i};
    $i      = !$i;
    
    my $rend   = $tile->{'end'};
    my $rstart = $tile->{'start'};
    my $rid    = $tile->{'contig'}->name();
    my $clone  = $tile->{'contig'}->clone->embl_id();
    my $strand = $tile->{'strand'};
    $rstart     = 1 if $rstart < 1;
    $rend       = $length if $rend > $length;
            
    my $glyph = new Bio::EnsEMBL::Glyph::Rect({
		'x'         => $rstart,
		'y'         => $ystart+2,
		'width'     => $rend - $rstart+1,
                'height'    => 11,
                'colour'    => $col,
                'absolutey' => 1,
		});

    if($navigation eq 'on') {
      $glyph->{'href'} = 
	"/$ENV{'ENSEMBL_SPECIES'}/$ENV{'ENSEMBL_SCRIPT'}?contig=$rid";
    }

    if($show_navigation) {
      $glyph->{'zmenu'} = {
		       'caption' => $rid,
		       "01:Clone: $clone"    => '',
		       '02:Centre on contig' => $glyph->{'href'},
		       "03:EMBL source file" => 
		       $self->{'config'}->{'ext_url'}->get_url( 'EMBL', $clone)
		     };
    }

    $self->push($glyph);
    $clone = $strand > 0 ? "$clone >" : "< $clone";
    my $bp_textwidth = $w * length($clone) * 1.2; # add 20% for scaling text
    
    if($bp_textwidth > ($rend - $rstart)) {
      my $pointer = $strand > 0 ? ">" : "<";
      $bp_textwidth = $w * length($pointer) * 1.2; # add 20% for scaling text
      unless($bp_textwidth > ($rend - $rstart)){
	my $tglyph = new Bio::EnsEMBL::Glyph::Text({
                     'x'          => int( ($rend + $rstart - $bp_textwidth)/2),
                     'y'          => $ystart+4,
                     'font'       => 'Tiny',
                     'colour'     => $cmap->id_by_name('white'),
                     'text'       => $pointer,
                     'absolutey'  => 1,
                    });
	$self->push($tglyph);
      }
    } else {
      my $tglyph = new Bio::EnsEMBL::Glyph::Text({
                    'x'          => int( ($rend + $rstart - $bp_textwidth)/2),
                    'y'          => $ystart+5,
                    'font'       => 'Tiny',
                    'colour'     => $cmap->id_by_name('white'),
                    'text'       => $clone,
                        'absolutey'  => 1,
                });
      $self->push($tglyph);
    }
  }

  $gline = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart,
        'width'     => $im_width,
        'height'    => 0,
        'colour'    => $black,
        'absolutey' => 1,
        'absolutex' => 1,
    });
  $self->unshift($gline);
    
  $gline = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart+15,
        'width'     => $im_width,
        'height'    => 0,
        'colour'    => $black,
        'absolutey' => 1,
        'absolutex' => 1,    
    });
  $self->unshift($gline);
    
  ## pull in our subclassed methods if necessary
  if ($self->can('add_arrows')){
    $self->add_arrows($im_width, $black, $ystart);
  }

  my $tick;
  my $interval = int($im_width/10);
  for (my $i=1; $i <=9; $i++){
    my $pos = $i * $interval;
   
    # the forward strand ticks
    $tick = new Bio::EnsEMBL::Glyph::Rect({
            'x'         => 0 + $pos,
            'y'         => $ystart-4,
            'width'     => 0,
            'height'    => 3,
            'colour'    => $black,
            'absolutey' => 1,
            'absolutex' => 1,
        });
    $self->unshift($tick);
    
    # the reverse strand ticks
    $tick = new Bio::EnsEMBL::Glyph::Rect({
            'x'         => $im_width - $pos,
            'y'         => $ystart+16,
            'width'     => 0,
            'height'    => 3,
            'colour'    => $black,
            'absolutey' => 1,
            'absolutex' => 1,
        });
    $self->unshift($tick);
  }
    
  # The end ticks
  $tick = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart-2,
        'width'     => 0,
        'height'    => 1,
        'colour'    => $black,
        'absolutey' => 1,
        'absolutex' => 1,
    });
  $self->unshift($tick);
   
  # the reverse strand ticks
  $tick = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => $im_width - 1,
        'y'         => $ystart+16,
        'width'     => 0,
        'height'    => 1,
        'colour'    => $black,
        'absolutey' => 1,
        'absolutex' => 1,
    });
  $self->unshift($tick);
    
  my $vc_size_limit = $Config->get('_settings', 'default_vc_size');
    # only draw a red box if we are in contigview top and there is a 
    # detailed display
    if ($Config->get('_settings','draw_red_box') eq 'yes') { 
      # only draw focus box on the correct display...
      my $LEFT_HS = $clone_based ? 0 : $global_start -1;
      my $boxglyph = new Bio::EnsEMBL::Glyph::Rect({
            'x'            => $Config->{'_wvc_start'} - $LEFT_HS,
            'y'            => $ystart - 4 ,
            'width'        => $Config->{'_wvc_end'} - $Config->{'_wvc_start'},
            'height'       => 23,
            'bordercolour' => $red,
            'absolutey'    => 1,
        });
      
      $self->unshift($boxglyph);

      my $boxglyph2 = new Bio::EnsEMBL::Glyph::Rect({
            'x'            => $Config->{'_wvc_start'} - $LEFT_HS,
            'y'            => $ystart - 3 ,
            'width'        => $Config->{'_wvc_end'} - $Config->{'_wvc_start'},
            'height'       => 21,
            'bordercolour' => $red,
            'absolutey'    => 1,
        });
      $self->unshift($boxglyph2);
    }

  my $width = $interval * ($length / $im_width) ;
  my $interval_middle = $width/2;
  
  if($navigation eq 'on') {
    foreach my $i(0..9){
      my $pos = $i * $interval;
      
      # the forward strand ticks
      $tick = new Bio::EnsEMBL::Glyph::Space({
                'x'         => 0 + $pos,
                'y'         => $ystart-4,
                'width'     => $interval,
                'height'    => 3,
                'absolutey' => 1,
                'absolutex' => 1,
                'href'	    => $self->zoom_URL($param_string, 
					    $interval_middle + $global_start, 
					    $length,  1  , $highlights),
                'zmenu'     => $self->zoom_zmenu($param_string, 
					    $interval_middle + $global_start, 
					    $length, $highlights ),
            });
      $self->unshift($tick);
            
      # the reverse strand ticks
      $tick = new Bio::EnsEMBL::Glyph::Space({
                'x'         => $im_width - $pos,
                'y'         => $ystart+16,
                'width'     => $interval,
                'height'    => 3,
                'absolutey' => 1,
                'absolutex' => 1,
                'href'	    => $self->zoom_URL($param_string, 
					     $global_end-$interval_middle, 
					     $length,  1  , $highlights),
                'zmenu'     => $self->zoom_zmenu($param_string, 
					     $global_end-$interval_middle, 
					     $length, $highlights ),
            });
      $self->unshift($tick);
      $interval_middle += $width;
    }
  }
}

1;
