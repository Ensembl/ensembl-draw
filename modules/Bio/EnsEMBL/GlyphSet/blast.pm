package Bio::EnsEMBL::GlyphSet::blast;
use strict;
use EnsWeb;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Space;
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Text;
use ColourMap;

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
    'text'      => 'BLAST hits',
    'font'      => 'Small',
    'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;
#    return unless ($self->strand() == 1);

    # Lets see if we have a BLAST hit
    # entry in higlights of the form BLAST:start:end

    my @blast_tickets;
    
    foreach($self->highlights) { 
        if(/BLAST:(.*)/) { push @blast_tickets, $1; } 
    }
    return unless @blast_tickets;

    my $vc   = $self->{'container'};
    my $vc_s = $vc->_global_start();
    my $vc_e = $vc->_global_end();
    my $vc_chr = $vc->_chr_name();
    my @hits;

    foreach my $ticket (@blast_tickets) {
        my $filename = EnsWeb::species_defs->ENSEMBL_TMP_ROOT."/blastqueue/$ticket.cache";
        if( -e $filename ) {
            open FH, $filename;
            while(<FH>) {
                chomp;
                my ($h_chr, $h_s, $h_e, $h_score, $h_percent, $h_name, $h_strand,$p_n,$q_s,$q_e) = split /\|/;
                if($h_chr eq $vc_chr) {
		  #  print STDERR "$vc_s -> $vc_e :: $h_s -> $h_e\n"; 
		  #  print STDERR "PUSHED:\n" unless(	($h_s > $vc_e) || ( $h_e < $vc_s));

                    push @hits, [$h_s,$h_e,$h_score,$h_percent,$ticket, $h_name, $h_strand, $p_n,$q_s,$q_e ] unless(
                        ($h_s > $vc_e) || ( $h_e < $vc_s)
                    );
                }
            }
            close FH;
        }
    }

    return unless @hits;
    ## We have a hit!;
  
    my $Config   = $self->{'config'};
    my $ppb      = $Config->transform->{'scalex'};
    my $cmap     = $Config->colourmap();
    my $bitmap_length = int($Config->container_width() * $ppb);
    my @bitmap = undef;

    my @colours = (
	[ 99, $cmap->add_hex( 'ff0000' ) ], 
	[ 90, $cmap->add_hex( 'ff4c4c' ) ],
	[ 80, $cmap->add_hex( 'ff7f7f' ) ],
	[ 70, $cmap->add_hex( 'ff9999' ) ],
	[ 50, $cmap->add_hex( 'ffa2a2' ) ],
	[  0, $cmap->add_hex( 'ffcccc' ) ] 
    ); 
    ## Lets draw a line across the glyphset

    my $gline = new Bio::EnsEMBL::Glyph::Rect({
        'x'         => 0,# $vc->_global_start(),
        'y'         => 4,
        'width'     => $vc_e - $vc_s,
        'height'    => 0,
        'colour'    => $cmap->id_by_name('yellow1'),
        'absolutey' => 1,
    });
    $self->push($gline);

    ## Lets draw a box foreach hit!
    foreach my $hit ( @hits ) {
		my $strand = $hit->[6];
	# print STDERR "HIT! $strand -", $self->strand,"\n";
        next if $strand != $self->strand();
        my $start = $hit->[0] < $vc_s ? $vc_s : $hit->[0];
        my $end   = $hit->[1] > $vc_e ? $vc_e : $hit->[1];
        $start = 0 if $start < 0;
        my ($col)    = map { $_->[0] <= $hit->[3] ? $_->[1] : () } @colours;
        my $gbox = new Bio::EnsEMBL::Glyph::Rect({
            'x'         => $start - $vc_s,
            'y'         => 0,
            'width'     => $end - $start,
            'height'    => 8,
            'colour'    => $col,
            'absolutey' => 1,
            'zmenu'     => {
                'caption' => 'Blast hit',
                "01:Score: $hit->[2]; identity: $hit->[3]%" => '',
                "02:Hit: $hit->[5]" => '',
                "03:Hit probability: $hit->[7]" => '',
                "04:Query start/end: $hit->[8]/$hit->[9]" => '',
                '06:Show blast alignment' =>
				    "/$ENV{'ENSEMBL_SPECIES'}/blastview?format=hit_format&id=$hit->[4]&hit=$hit->[5]",
                '07:Show on karyotype' =>
				    "/$ENV{'ENSEMBL_SPECIES'}/blastview?format=karyo_format&id=$hit->[4]"
            },
    	});
    
        my $bump_height = 10;
        ########## bump it baby, yeah! - bump-nology!
        my $bump_start = int($gbox->x * $ppb);
        $bump_start = 0 if ($bump_start < 0);
        my $bump_end = $bump_start + int($gbox->width * $ppb)+1;
        if ($bump_end > $bitmap_length) { $bump_end = $bitmap_length };
    
        my $row = &Bump::bump_row(
            $bump_start,
            $bump_end,
            $bitmap_length,
            \@bitmap
        );
    
        #########
        # shift the composite container by however much we're bumped
        #
        $gbox->y($gbox->y() - $self->strand() * $bump_height * $row);
        $self->push($gbox);
    }
}   

1;
