package Bio::EnsEMBL::GlyphSet::synteny;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);


sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
        'text'      => 'Syntenic Regions',
        'font'      => 'Small',
        'absolutey' => 1,
    });
    $self->label($label);
}

sub features {
    my ($self) = @_;
    return map { ($_->strand() == $self->strand) && ($_->source_tag() eq 'synteny') ? $_ : () } $self->{'container'}->get_all_ExternalFeatures($self->glob_bp)

}
=head


#not used..... 
sub _init {
    my ($self) = @_;
    my $vc             = $self->{'container'}; #it's like the Virtual contig.pm
    my $Config         = $self->{'config'}; # defined in DrawableContainer.pm
    my $type           = $Config->get( 'synteny', 'src'); #taken from snp.pm
 
#not used yet coz too few hits
#    my $max_length     = $Config->get( 'synteny', 'score' ) || 1e10;  # get is inherited from modules/WebUserConfig.pm
                                                                          # you can set it to whatever value you want.. 
    my $y              = 8; #this this has something to do with teh hight of the boxes?
    my $h              = 8;
    my $feature_colour = $Config->get( 'synteny', 'col' );

     my @xf = $vc->get_all_ExternalFeatures( $self->glob_bp() );
     my $ext_url = ExtURL->new;

      my @snp = grep $_->isa("Bio::EnsEMBL::SeqFeature"), @xf;


    foreach my $s (@snp) {
        my $x = $s->start();
        my $id = $s->seqname();
        my $glyph = new Bio::EnsEMBL::Glyph::Rect({
            'x'         => $x,
            'y'         => 0,
            'width'     => $vc->length(),
            'height'    => $h,
#            'colour'    => 'black',
            #'colour'    => $feature_colour,
            'absolutey' => 1,
            'href'      => "/$ENV{'ENSEMBL_SPECIES'}/syntenyview?synteny=$id",
            'zmenu'     => {
                'caption'           => "SNP: $id",
                'SNP properties'    => "/$ENV{'ENSEMBL_SPECIES'}/syntenyview?synteny=$id",
                #don't think there will be any ext. db?
                #'dbSYNTENY data'        => $ext_url->get_url('SYNTENY',$id),
            },

        });
        $self->push( $glyph );
    }
}
=cut
1;
