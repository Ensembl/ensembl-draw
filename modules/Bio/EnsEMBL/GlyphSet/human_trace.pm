package Bio::EnsEMBL::GlyphSet::human_trace;
use strict;
use vars qw(@ISA);
# use Bio::EnsEMBL::GlyphSet_simple;
# @ISA = qw(Bio::EnsEMBL::GlyphSet_simple);
use Bio::EnsEMBL::GlyphSet_feature2;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature2);


sub my_label { return "Human matches"; }

sub features {
    my ($self) = @_;
    print STDERR "\nHUMAN MATCHES---------------------------------\n\n";
    return grep { 
        ( $_->isa("Bio::EnsEMBL::Ext::FeaturePair") || $_->isa("Bio::EnsEMBL::FeaturePair") ) 
	        && $_->source_tag() eq "trace"
    } $self->{'container'}->get_all_ExternalFeatures( $self->glob_bp() );
}

sub href {
    my ($self, $id, $chr_pos ) = @_;
    return qq(/Homo_sapiens/contigview?$chr_pos);
}

sub zmenu {
    my ($self, $id, $chr_pos ) = @_;
    return { 
		'caption'    => $id, # $f->id,
		'Jump to Homo sapiens' => $self->href( $id, $chr_pos )
    };
}
1;
