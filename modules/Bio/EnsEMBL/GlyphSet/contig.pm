package Bio::EnsEMBL::GlyphSet::contig;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Poly;
use Bio::EnsEMBL::Glyph::Space;
use Bio::EnsEMBL::Glyph::Text;
use SiteDefs;
use ColourMap;

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
	    'text'      => 'DNA(contigs)',
    	'font'      => 'Small',
	    'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;

    #########
    # only draw contigs once - on one strand
    #
    return unless ($self->strand() == 1);

	my $vc = $self->{'container'};
    my $length   = $vc->length() +1;
    my $Config   = $self->{'config'};
	my $module = ref($self);
	$module = $1 if $module=~/::([^:]+)$/;
    my $threshold_navigation    = ($Config->get($module, 'threshold_navigation') || 2e6)*1001;
	my $show_navigation = $length < $threshold_navigation;
    my $highlights = join('|', $self->highlights() ) ;
    $highlights = $highlights ? "&highlight=$highlights" : '';
    my $cmap     = $Config->colourmap();
    my $col1     = $cmap->id_by_name('contigblue1');
    my $col2     = $cmap->id_by_name('contigblue2');
    my $col3     = $cmap->id_by_name('black');
    my $white    = $cmap->id_by_name('white');
    my $black    = $cmap->id_by_name('black');
    my $red      = $cmap->id_by_name('red');
    my $ystart   = 0;
    my $im_width = $Config->image_width();
    my ($w,$h)   = $Config->texthelper()->real_px2bp('Tiny');
    my $clone_based = $Config->get('_settings','clone_based') eq 'yes';
    my $clone       = $Config->get('_settings','clone');
    my $param_string   = $clone_based ? "seqentry=1&clone=$clone" : ("chr=".$vc->_chr_name());
    my $global_start   = $clone_based ? $Config->get('_settings','clone_start') : $vc->_global_start();
    my $global_end     = $global_start + $length - 1;
    
    $w *= $length/($length-1);

    my $gline = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart+7,
        'width'     => $length,
        'height'    => 0,
        'colour'    => $cmap->id_by_name('grey1'),
        'absolutey' => 1,
    });
    $self->push($gline);

    
    my @map_contigs = ();
    my $useAssembly;
    eval {
        $useAssembly = $vc->has_AssemblyContigs;
    };
    print STDERR "Using assembly $useAssembly\n";

    if ($useAssembly) {
       @map_contigs = $vc->each_AssemblyContig;
    } else {
       @map_contigs = $vc->_vmap->each_MapContig();
    }

    if (@map_contigs) {
        my $start;
        my $end;

        if ($useAssembly) {
         $start     = $map_contigs[0]->chr_start - 1;
         $end       = $map_contigs[-1]->chr_end;
        } else {
         $start     = $map_contigs[0]->start -1;
         $end       = $map_contigs[-1]->end;
        }
        
        my $tot_width = $end - $start;
    
        my $i = 1;
    
        my %colours = (
               $i  => $col1,
               !$i => $col2,
        );

        foreach my $temp_rawcontig ( @map_contigs ) {
            my $col = $colours{$i};
            $i      = !$i;

            my $rend;
            my $rstart;

            my $cstart;
            my $cend;

            my $rid; 
            my $strand;
            my $clone;

            if ($useAssembly) {       
              $cend   = $temp_rawcontig->chr_end;
              $cstart = $temp_rawcontig->chr_start -1;
              $rend   = $temp_rawcontig->chr_end - $vc->_global_start + 1;
              $rstart = $temp_rawcontig->chr_start - $vc->_global_start + 1;
              $rid    = $temp_rawcontig->display_id;
              $strand = $temp_rawcontig->orientation;
              $clone  = $temp_rawcontig->display_id;
            } else {
              $cend   = $temp_rawcontig->end() + $vc->_global_start -1;
              $cstart = $temp_rawcontig->start() + $vc->_global_start -1;
              $rend   = $temp_rawcontig->end;
              $rstart = $temp_rawcontig->start;
              $rid    = $temp_rawcontig->contig->id();
              $clone  = $temp_rawcontig->contig->cloneid();
              $strand = $temp_rawcontig->strand();
            }

            my $glyph = new Bio::EnsEMBL::Glyph::Rect({
                'x'         => $rstart,
                'y'         => $ystart+2,
                'width'     => $rend - $rstart,
                'height'    => 10,
                'colour'    => $col,
                'absolutey' => 1,
			});
            my $cid = $rid;
            $cid=~s/^([^\.]+\.[^\.]+)\..*/$1/;
            $glyph->{'href'} = "/$ENV{'ENSEMBL_SPECIES'}/contigview?chr=".
                        $vc->_chr_name()."&vc_start=".
                        ($cstart)."&vc_end=".
                        ($cend);
			$glyph->{'zmenu'} = {
                    'caption' => $rid,
                    "01:Clone: $clone"   => '',
                    '02:Centre on contig' => $glyph->{'href'},
                    "03:EMBL source file" => $self->{'config'}->{'ext_url'}->get_url( 'EMBL', $cid )
			} if $show_navigation;
			
            $self->push($glyph);

            $clone = $strand > 0 ? $clone."->" : "<-$clone";
        
            my $bp_textwidth = $w * length($clone) * 1.2; # add 20% for scaling text
            unless ($bp_textwidth > ($rend - $rstart)){
                my $tglyph = new Bio::EnsEMBL::Glyph::Text({
                    'x'          => int( ($rend + $rstart - $bp_textwidth)/2),
                    'y'          => $ystart+4,
                    'font'       => 'Tiny',
                    'colour'     => $white,
                    'text'       => $clone,
                    'absolutey'  => 1,
                });
                $self->push($tglyph);
            }
        }
    } else {
    # we are in the great void of golden path gappiness..
        my $text = "Golden path gap - no contigs to display!";
        my $bp_textwidth = $w * length($text);
        my $tglyph = new Bio::EnsEMBL::Glyph::Text({
            'x'         => int(($length - $bp_textwidth)/2),
            'y'         => $ystart+4,
            'font'      => 'Tiny',
            'colour'    => $red,
            'text'      => $text,
            'absolutey' => 1,
        });
        $self->push($tglyph);
    }

    $gline = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart,
        'width'     => $im_width,
        'height'    => 0,
        'colour'    => $col3,
        'absolutey' => 1,
        'absolutex' => 1,
    });
    $self->push($gline);
    
    $gline = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart+14,
        'width'     => $im_width,
        'height'    => 0,
        'colour'    => $col3,
        'absolutey' => 1,
        'absolutex' => 1,    
    });
    $self->push($gline);
    
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
            'colour'    => $col3,
            'absolutey' => 1,
            'absolutex' => 1,
        });
        $self->push($tick);
        # the reverse strand ticks
        $tick = new Bio::EnsEMBL::Glyph::Rect({
            'x'         => $im_width - $pos,
            'y'         => $ystart+15,
            'width'     => 0,
            'height'    => 3,
            'colour'    => $col3,
            'absolutey' => 1,
            'absolutex' => 1,
        });
        $self->push($tick);
    }
    # The end ticks
    $tick = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,
        'y'         => $ystart-2,
        'width'     => 0,
        'height'    => 1,
        'colour'    => $col3,
        'absolutey' => 1,
        'absolutex' => 1,
    });
    $self->push($tick);
    # the reverse strand ticks
    $tick = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => $im_width - 1,
        'y'         => $ystart+15,
        'width'     => 0,
        'height'    => 1,
        'colour'    => $col3,
        'absolutey' => 1,
        'absolutex' => 1,
    });
    $self->push($tick);
    
    my $vc_size_limit = $Config->get('_settings', 'default_vc_size');
    # only draw a red box if we are in contigview top and there is a detailed display
    if ($Config->get('_settings','draw_red_box') eq 'yes') { #  eq  && ($length <= $vc_size_limit+2))

    # only draw focus box on the correct display...
        my $LEFT_HS = $clone_based ? 0 : $global_start -1;
        my $boxglyph = new Bio::EnsEMBL::Glyph::Rect({
            'x'            => $Config->{'_wvc_start'} - $LEFT_HS,
            'y'            => $ystart - 4 ,
            'width'        => $Config->{'_wvc_end'} - $Config->{'_wvc_start'},
            'height'       => 22,
            'bordercolour' => $red,
            'absolutey'    => 1,
        });
        $self->push($boxglyph);

        my $boxglyph2 = new Bio::EnsEMBL::Glyph::Rect({
            'x'            => $Config->{'_wvc_start'} - $LEFT_HS,
            'y'            => $ystart - 3 ,
            'width'        => $Config->{'_wvc_end'} - $Config->{'_wvc_start'},
            'height'       => 20,
            'bordercolour' => $red,
            'absolutey'    => 1,
        });
        $self->push($boxglyph2);
    }
    my $width = $interval * ($length / $im_width) ;
    my $interval_middle = $width/2;

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
            'href'		=> $self->zoom_URL($param_string, $interval_middle + $global_start, $length,  1  , $highlights),
            'zmenu'     => $self->zoom_zmenu( $param_string, $interval_middle + $global_start, $length, $highlights ),
        });
        $self->push($tick);
        # the reverse strand ticks
        $tick = new Bio::EnsEMBL::Glyph::Space({
            'x'         => $im_width - $pos,
            'y'         => $ystart+15,
            'width'     => $interval,
            'height'    => 3,
            'absolutey' => 1,
            'absolutex' => 1,
            'href'		=> $self->zoom_URL(     $param_string, $global_end-$interval_middle, $length,  1  , $highlights),
            'zmenu'     => $self->zoom_zmenu(   $param_string, $global_end-$interval_middle, $length, $highlights ),
        });
        $self->push($tick);
        $interval_middle += $width;
    }

}

1;
