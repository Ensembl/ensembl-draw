package Bio::EnsEMBL::VDrawableContainer;
use Bio::Root::RootI;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet::Videogram;
use EnsWeb;

@ISA = qw(Bio::Root::RootI);

sub new {
    my ($class, $Container, $Config, $highlights, $strandedness) = @_;

    if(!defined $Container) {
        print STDERR qq(Bio::EnsEMBL::DrawableContainer::new No container defined\n);
        return;
    }

    if(!defined $Config) {
        print STDERR qq(Bio::EnsEMBL::DrawableContainer::new No Config object defined\n);
        return;
    }

    my $self = {
        'vc'         => $Container,
        'glyphsets'  => [],
        'config'     => $Config,
        'spacing'    => 20,
    };
    bless($self, $class);

    ########## loop over all the glyphsets the user wants:
    my $tmp = {};
    for my $row ($Config->subsections()) {
	    next unless ($Config->get($row, 'on') eq "on");
    	if( $row eq 'Videogram' && $Config->{'_all_chromomosomes'} eq 'yes') {
            my $pos = $tmp->{$Config->get($row, 'pos')};
    	    foreach my $chr ( @{EnsWeb::species_defs->ENSEMBL_CHROMOSOMES} ) {
    		    my $GlyphSet;
                eval {
    		        $GlyphSet = new Bio::EnsEMBL::GlyphSet::Videogram(
    			                $Container, $Config, $highlights, 0,
    			                { 'chr' => "chr$chr" }
    		        );
    		    };
    		    if($@) {
    		        print STDERR "GLYPHSET Videogram($chr) failed\n";
    		    } else {
    		        $GlyphSet->_init();
    		        $tmp->{$pos++} = $GlyphSet if( @{$GlyphSet->{'glyphs'}} );
                }
            } 
        } else {
            ########## create a new glyphset for this row
            my $classname = qq(Bio::EnsEMBL::GlyphSet::$row);
            ########## require & import the package
            eval "require $classname";
            
            if($@) {
                print STDERR qq(VDrawableContainer::new failed to require $classname: $@\n);
                next;
            } 
            $classname->import();
    
            my $GlyphSet;
            eval { $GlyphSet = new $classname($Container, $Config, $highlights); };
            if($@) {
               print STDERR "GLYPHSET $classname failed\n";
            } else {
               ########## load everything from the database
               ########## don't waste any more time on this row if there's nothing in it
               $GlyphSet->_init();
               $tmp->{$Config->get($row, 'pos')} = $GlyphSet if( @{$GlyphSet->{'glyphs'}} );
            }
        }
    }
    ########## sort out the resulting mess
    @{$self->{'glyphsets'}} = map { $tmp->{$_} } sort { $a <=> $b } keys %{$tmp};
    
    ########## calculate real scaling here
    my $spacing = $self->{'spacing'};
    
    ########## set scaling factor for base-pairs -> pixels
    my $scalex = $Config->{'_image_height'} / $Config->container_width();
    $Config->{'transform'}->{'scalex'} = $scalex;
    
    ########## set scaling factor for 'absolutex' coordinates -> real pixel coords
    $Config->{'transform'}->{'absolutescalex'} = $Config->{'_image_height'} / $Config->image_width();
    
    ########## because our text label starts are < 0, translate everything back onto the canvas
    $Config->{'transform'}->{'translatex'} += $Config->{'_top_margin'};
   
    ########## go ahead and do all the database work
    my $yoffset = 0;

    my $glyphsets = @{$self->{'glyphsets'}};

##
## Firstly lets work how many entries to draw per row!
## Then work out the minimum start for each of these rows
## We then shift up all these points up by that many base 
## pairs to close up any gaps
##

    my $entries_per_row = int( ($glyphsets - 1) / ($Config->{'_rows'} || 1) ) +1; 
    my $entry_no = 0;
    $Config->{'_max_height'} =  0;
    $Config->{'_max_width'}  =  0;

    my @row_min   = ();
    my @row_max   = ();
    my $row_count = 0;
    my $row_index = 0;
    for my $glyphset (@{$self->{'glyphsets'}}) {
        $row_min[$row_index] = $glyphset->minx() if(!defined $row_min[$row_index] || $row_min[$row_index] > $glyphset->minx() );
        $row_max[$row_index] = $glyphset->maxx() if(!defined $row_max[$row_index] || $row_max[$row_index] < $glyphset->maxx() );
        unless(++$row_count < $entries_per_row) {
            $row_count = 0;
            $row_index++;
        }
    }
    ## Close up gap!
    my $translateX = shift @row_min;
    $Config->{'transform'}->{'translatex'} -= $translateX * $scalex; #$xoffset;
    my $xoffset = -$translateX * $scalex;

    for my $glyphset (@{$self->{'glyphsets'}}) {
        $Config->{'_max_width'} = $xoffset + $Config->image_width();
        ########## set up the label for this strip 
	########## first we get the max width of label in characters
        my $gw = 0;
        $gw = length($glyphset->label->text()) if(defined $glyphset->label());
        if(defined $glyphset->label2()) {
            my $gw2 = length($glyphset->label2->text());                
            $gw = $gw2 if $gw2>$gw;
        }
        if($gw>0) {
	    ########## and convert it to pels
            $gw *= $Config->texthelper->width($glyphset->label->font());
	    ########## If the '_label' position is not 'above' move the labels below the image
            my $label_x = $Config->{'_label'} eq 'above' ? 0 : $Config->{'_image_height'};
            $label_x   += 4 - $Config->{'_top_margin'};
            my $label_y = ($glyphset->maxy() + $glyphset->miny() - $gw ) / 2;
            if(defined $glyphset->label()) {
                $glyphset->label->y( $label_y );
                $glyphset->label->x( $label_x / $scalex);                        
                $glyphset->label->height($gw);
                $glyphset->push($glyphset->label());
            }
            if(defined $glyphset->label2()) {
                $glyphset->label2->y( $label_y );
                $glyphset->label2->x( ( $label_x + 2 +
                                        $Config->texthelper->height($glyphset->label->font()) ) / $scalex);
                $glyphset->label2->height($gw);
                $glyphset->push($glyphset->label2());
            }                
        }
        ########## remove any whitespace at the top of this row
        $Config->{'transform'}->{'translatey'} = -$glyphset->miny() + $spacing/2 + $yoffset;
        $glyphset->transform();
        ########## translate the top of the next row to the bottom of this one
        $yoffset += $glyphset->height() + $spacing;
        $Config->{'_max_height'} = $yoffset if( $yoffset > $Config->{'_max_height'} );
        unless(++$entry_no < $entries_per_row) {
            $entry_no = 0;
            $yoffset = 0;
            my $translateX = shift @row_min;
            $xoffset += $Config->image_width() - $translateX * $scalex;
            ## Shift down - and then close up gap!
        	$Config->{'transform'}->{'translatex'} += $Config->image_width() - $translateX * $scalex; #$xoffset;
        }
    }

    ########## Store the maximum "width of the image"
    return $self;
}

########## render does clever drawing things
sub render {
    my ($self, $type) = @_;
    
    ########## build the name/type of render object we want
    my $renderer_type = qq(Bio::EnsEMBL::VRenderer::$type);
    ########## dynamic require of the right type of renderer
    eval "require $renderer_type";

    if($@) {
        print STDERR qq(VDrawableContainer::new failed to require $renderer_type\n);
        return;
    }
    $renderer_type->import();
    ########## big, shiny, rendering 'GO' button
    my $renderer = $renderer_type->new($self->{'config'}, $self->{'vc'}, $self->{'glyphsets'});
    return $renderer->canvas();
}

sub config {
    my ($self, $Config) = @_;
    $self->{'config'} = $Config if(defined $Config);
    return $self->{'config'};
}

sub glyphsets {
    my ($self) = @_;
    return @{$self->{'glyphsets'}};
}

1;

=head1 RELATED MODULES

See also: Bio::EnsEMBL::GlyphSet Bio::EnsEMBL::Glyph WebUserConfig

=head1 AUTHOR - Roger Pettett

Email - rmp@sanger.ac.uk

=cut
