package Bio::EnsEMBL::GlyphSet::repeat_lite;

use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end);

@ISA = qw( Bio::EnsEMBL::GlyphSet );

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    print STDERR "LABEL\n";
    my $label = new Bio::EnsEMBL::Glyph::Text({
        'text'      => 'Repeats',
        'font'      => 'Small',
        'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;
    my $vc             = $self->{'container'};
    my $Config         = $self->{'config'};

    my $max_length     = $Config->get( 'repeat_lite', 'threshold' ) || 2000;
    my $navigation     = $Config->get( 'repeat_lite', 'navigation' ) || 'off';
    my $max_length_nav = $Config->get( 'repeat_lite', 'navigation_threshold' ) || 1500;
    my $feature_colour = $Config->get( 'repeat_lite', 'col' );
    my $vc_length      = $vc->length;
    my $h              = 8;

    return unless ( $self->strand() == -1 );
	
    if( $vc_length > ($max_length*1001)) {
        $self->errorTrack("Repeats only displayed for less than $max_length Kb.");
        return;
    }
	
	my $show_navigation =  $navigation eq 'on' && ( $vc_length < $max_length_nav * 1001 );

    &eprof_start('lite_adaptor_call');
	my $repeats = $vc->dbobj->get_LiteAdaptor->fetch_virtualRepeatFeatures_start_end(
		$vc->_chr_name(), $vc->_global_start(), $vc->_global_end(), '', $self->glob_bp() 
	);
    unless(@$repeats>0 || $Config->get('_settings','opt_empty_tracks')==0 ) {
        $self->errorTrack("No repeats in this region");
        return;
    }

    &eprof_end('lite_adaptor_call');
    &eprof_start('lite_drawing');
	foreach my $f ( @$repeats ) {
        my $start = $f->{'start'};
        $start = 1 if $start < 1;
        my $end = $f->{'end'};
        $end = $vc_length if $end>$vc_length;
        my $glyph = new Bio::EnsEMBL::Glyph::Rect({
            'x'         => $start,
            'y'         => 0,
            'width'     => $end-$start,
            'height'    => $h,
            'colour'    => $feature_colour,
            'absolutey' => 1,
        });
        $glyph->{'zmenu'} = {
			'caption' 											=> $f->{'hid'},
			"bp: $f->{'chr_start'}-$f->{'chr_end'}" 			=> '',
			"length: ".($f->{'chr_end'}-$f->{'chr_start'}+1) 	=> ''
		} if($show_navigation);
        $self->push( $glyph );
    }
    &eprof_end('lite_drawing');
}

1;
