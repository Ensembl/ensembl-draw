package Bio::EnsEMBL::GlyphSet::repeat_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple_hash;

@ISA = qw( Bio::EnsEMBL::GlyphSet_simple_hash );

sub my_label { return "Repeats"; }

sub features {
  my $self = shift;
    
  my $max_length = $self->{'config'}->get('repeat_lite', 'threshold') || 2000;
  return $self->{'container'}->get_all_RepeatFeatures('RepeatMask');
}

sub zmenu {
  my( $self, $f ) = @_;

  ### Possibly should not use $f->repeat_consensus->name.... was f->{'hid'}
  return {
	  'caption' => $f->repeat_consensus()->name(),
	  "bp: " . ($f->start() . "-" . $f->end())           => '',
	  "length: ".($f->end()-$f->start()+1)  => ''
    }
}

1;
