package Bio::EnsEMBL::DrawableContainer;
use lib "../../../../bioperl-live";
use Bio::Root::RootI;
use strict;
use lib "../../../../modules";
use vars qw(@ISA);
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);
use Bio::EnsEMBL::Glyph::Rect;

@ISA = qw(Bio::Root::RootI);

sub new {
    my ($class, $display, $Container, $Config, $highlights, $strandedness) = @_;

    my @strands_to_show = (1, -1);

    if($strandedness == 1) {
       @strands_to_show = (1);
    }

    if(!defined $display) {
	print STDERR qq(Bio::EnsEMBL::DrawableContainer::new No display type defined\n);
	return;
    }

#    if($display !~ /transview|contigviewbottom|protview/) {
#	print STDERR qq(Bio::EnsEMBL::DrawableContainer::new Unknown display type $display\n);
#	return;
#    }

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
	'display'    => $display,
	'glyphsets'  => [],
	'config'     => $Config,
	'spacing'    => 5,
    };
    bless($self, $class);

    #########
    # loop over all the glyphsets the user wants:
    #

    my @subsections = $Config->subsections($self->{'display'});

    my @order = sort { $Config->get($self->{'display'}, $a, 'pos') <=> $Config->get($self->{'display'}, $b, 'pos') } @subsections;

    &eprof_start('glyphset_creation');

    #########
    # instantiate our list of glyphsets
    #
    for my $strand (@strands_to_show) {
      my @tmp;

      if($strand == 1) {
	@tmp = reverse @order;
      } else {
        @tmp = @order;
      }

      for my $row (@tmp) {
	#########
	# skip this row if user has it turned off
	#
	next if ($Config->get($self->{'display'}, $row, 'on') eq "off");
	next if ($Config->get($self->{'display'}, $row, 'str') eq "r" && $strand != -1);
	next if ($Config->get($self->{'display'}, $row, 'str') eq "f" && $strand != 1);

	#########
	# create a new glyphset for this row
	#
	my $classname = qq(Bio::EnsEMBL::GlyphSet::$row);

	#########
	# require & import the package
	#
	eval "require $classname";

	if($@) {
	    print STDERR qq(DrawableContainer::new failed to require $classname: $@\n);
	    next;
	}
	$classname->import();

	#########
	# generate a set for both strands
	#
	my $GlyphSet = new $classname($Container, $Config, $highlights, $strand);

	push @{$self->{'glyphsets'}}, $GlyphSet;
      }
    }

    #########
    # calculate real scaling here
    # 
    my $spacing = $self->{'spacing'};

    #########
    # calculate the maximum label width (plus margin)
    #
    my $label_length_px = 0;

    for my $glyphset (@{$self->{'glyphsets'}}) {
	next if(!defined $glyphset->label());

	my $chars  = length($glyphset->label->text());
	my $pixels = $chars * $Config->texthelper->width($glyphset->label->font());
	
	$label_length_px = $pixels if($pixels > $label_length_px);
    }

    #########
    # add spacing before and after labels
    #
    $label_length_px += $spacing * 2;

    #########
    # calculate scaling factors
    #
    my $pseudo_im_width = $Config->image_width() - $label_length_px - $spacing;

    #########
    # set scaling factor for base-pairs -> pixels
    #
    my $scalex = $pseudo_im_width / $Config->container_width();
    $Config->{'transform'}->{'scalex'} = $scalex;

    #########
    # set scaling factor for 'absolutex' coordinates -> real pixel coords
    #
    $Config->{'transform'}->{'absolutescalex'} = $pseudo_im_width / $Config->image_width();

    #########
    # because our text label starts are < 0, translate everything back onto the canvas
    #
    my $extra_translation = $label_length_px;
    $Config->{'transform'}->{'translatex'} += $extra_translation;

    for my $glyphset (@{$self->{'glyphsets'}}) {
	next if(!defined $glyphset->label());
	$glyphset->label->x(-($extra_translation - $spacing) / $scalex);
    }

    #########
    # pull out alternating background colours for this script
    #
    my $white  = $Config->bgcolour() || $Config->colourmap->id_by_name('white');
    my $bgcolours = {
	'0' => $Config->get($Config->script(), '_settings', 'bgcolour1') || $white,
	'1' => $Config->get($Config->script(), '_settings', 'bgcolour2') || $white,
    };

    my $bgcolour_flag;
    $bgcolour_flag = 1 if($$bgcolours{0} ne $$bgcolours{1});

    #########
    # go ahead and do all the database work
    #
    my $yoffset = $spacing;
    my $iteration = 0;
    for my $glyphset (@{$self->{'glyphsets'}}) {

	#########
	# load everything from the database
	#
	$glyphset->_init();

	#########
	# don't waste any more time on this row if there's nothing in it
	#
	next if(scalar @{$glyphset->{'glyphs'}} == 0);

	#########
	# remove any whitespace at the top of this row
	#
	my $gminy = $glyphset->miny();

	$Config->{'transform'}->{'translatey'} = -$gminy + $yoffset + ($iteration * $spacing);

	if(defined $bgcolour_flag) {
	    #########
	    # colour the area behind this strip
	    #
	    my $background = new Bio::EnsEMBL::Glyph::Rect({
		'x'         => 0,
		'y'         => $gminy,
		'width'     => $Config->image_width(),
		'height'    => $glyphset->maxy() - $gminy,
		'colour'    => $$bgcolours{$iteration % 2},
		'absolutex' => 1,
	    });

	    #########
	    # this accidentally gets stuffed in twice (for gif & imagemap)
	    # so with rounding errors and such we shouldn't track this for maxy & miny values
	    #
	    unshift @{$glyphset->{'glyphs'}}, $background;
	}

	#########
	# set up the label for this strip
	#
	if(defined $glyphset->label()) {
	    my $gh = $Config->texthelper->height($glyphset->label->font());
	    $glyphset->label->y((($glyphset->maxy() - $glyphset->miny() - $gh) / 2) + $gminy);
	    $glyphset->label->height($gh);
	    $glyphset->push($glyphset->label());
	}

	$glyphset->transform();

	#########
	# translate the top of the next row to the bottom of this one
	#
	$yoffset += $glyphset->height();
	$iteration ++;
    }

    &eprof_end('glyphset_creation');

    return $self;
}

#########
# render does clever drawing things
#
sub render {
    my ($self, $type) = @_;
    
    #########
    # build the name/type of render object we want
    #
    my $renderer_type = qq(Bio::EnsEMBL::Renderer::$type);

    #########
    # dynamic require of the right type of renderer
    #
    eval "require $renderer_type";

    if($@) {
	print STDERR qq(DrawableContainer::new failed to require $renderer_type\n);
	return;
    }
    $renderer_type->import();

    #########
    # big, shiny, rendering 'GO' button
    #
    &eprof_start(qq(renderer_creation_$type));
    my $renderer = $renderer_type->new($self->{'config'}, $self->{'vc'}, $self->{'glyphsets'});
    &eprof_end(qq(renderer_creation_$type));

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
