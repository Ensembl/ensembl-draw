package Bio::EnsEMBL::GlyphSet::ensemblclones;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple;
use Bio::EnsEMBL::SeqFeature;
use Bio::EnsEMBL::ExternalData::DAS::DASAdaptor;
use Bio::EnsEMBL::ExternalData::DAS::DAS;
use Bio::Das; 
use EnsWeb;
use Data::Dumper;

@ISA = qw(Bio::EnsEMBL::GlyphSet_simple);

sub my_label { return "Ensembl Clones"; }

sub features {
    my ($self)      = @_;
    return unless ref(EnsWeb::species_defs->ENSEMBL_TRACK_DAS_SOURCES) eq 'HASH';
    my $slice       = $self->{'container'};
    my @clones      = ();

    ###### Create a list of clones to fetch #######
    foreach (@{$slice->get_tiling_path()}){
        my $clone = $_->component_Seq->clone->embl_id;
        push(@clones, $clone);
    }        

    ###### Get DAS source config for this track ######
    my $species_defs    = &EnsWeb::species_defs();
    my $source          = "das_ENSEMBLCLONES";
    my $dbname          = EnsWeb::species_defs->ENSEMBL_TRACK_DAS_SOURCES->{$source};
    my $URL             = $dbname->{'url'};
    my $dsn             = $dbname->{'dsn'};
    my $types           = $dbname->{'types'} || [];
    my $adaptor         = undef;
    my %SEGMENTS        = ();
    ###### Register a callback function to handle the DAS features #######
    ###### Called whenever the DAS XML parser finds a feature      #######
    my $feature_callback =  sub {
        my $f = shift;
     #  return if (exists $SEGMENTS{$f->segment->ref().".".$f->segment->version()} );
        $SEGMENTS{$f->segment->ref().".".$f->segment->version()}++;
        warn "\nSTORE: ", $f->segment->ref().".".$f->segment->version(), "\n";
    };


    ###### Create a new DAS adaptor #######
    eval {
        $URL = "http://$URL" unless $URL =~ /https?:\/\//i;
        $adaptor = Bio::EnsEMBL::DBDAS::DASAdaptor->new(
                                -url        => $URL,
                                -dsn        => $dsn,
                                -types      => $types || [], 
                                -proxy_url  => &EnsWeb::species_defs->ENSEMBL_DAS_PROXY,
                                );
    };
    if($@) {
      warn("\nEnsembl Clones DASAdaptor creation error\n$@\n") 
    } 
       
    my $dbh 	    = $adaptor->_db_handle();
    my $response    = undef;
    $types          = []; # just for now....
    
#    print "<br>\nclones" , join "\n", @clones;
#    print "<br>\nfeaturecallback" ,  $feature_callback;


    ###### DAS fetches happen here ##########
    if(1){     
       $response = $dbh->features(
                   -dsn         =>  "$URL/$dsn",
                   -segment     =>  \@clones,
                   -callback    =>  $feature_callback,
                   -type        =>  $types,
       );
    }
  
    ####### DAS URL debug trace ##########
    if(0){
        $response = $dbh->features(
                          -dsn        =>  "http://ecs3.internal.sanger.ac.uk:4001/das/$dsn",
                          -segment    =>  \@clones,
                          -callback   =>  $feature_callback,
                          -type       =>  $types,
        );
    }
    
   #print  "<br>SUCCESS<br>\n" if $response->is_success;
   # print  "<br>" . Dumper($response);
   # my $results = $response->results();
   # print  "<Br>RESULTS: $results\n";
   # foreach my $seg (keys %{$results}){
   #     print  "<br>SEGMENT: $seg\n";
   # }
    
    my $res = [];

    foreach my $c (keys %SEGMENTS){

        my ($name,$ver) = split(/\./,$c);
        foreach my $p (@{$slice->get_tiling_path()}){

#print "<br>ensemblclones.pm contig name" .  $p->{contig}->name() . " name". $name;



            if ($p->{contig}->name() =~ /$name/){
                my $s = Bio::EnsEMBL::SeqFeature->new();
                
                # remember if the Vega clone version is newer/older/same as e! clone
                if($ver > $p->component_Seq->clone->embl_version){
                    $s->{'status'} = 1; # vega has newer clone version
                } elsif ($ver == $p->{contig}->clone->embl_version){
                    $s->{'status'} = 0; # vega has same clone version
                } else {
                    $s->{'status'} = -1;# vega has older clone version
                }
                my $id = $p->component_Seq->clone->embl_id() . "." . $p->component_Seq->clone->embl_version();
                my $label = $id . " >";
                if($p->{strand} == -1){
                    $label = "< "  . $id;
                }
                $s->id($label);
                $s->start($p->{start});
                $s->end($p->{end});
                $s->strand($p->{strand});
                $s->{'embl_clone'} = $c;
                push(@{$res}, $s,)
            }
        }
    }       
    return $res;
    
}

sub href {
    my ($self, $f ) = @_;

my ($cloneid) = split /\./ ,  $f->{'embl_clone'};

    return "http://www.ensembl.org/$ENV{'ENSEMBL_SPECIES'}/$ENV{'ENSEMBL_SCRIPT'}?clone=". $cloneid;
}

sub colour {
    my ($self, $f ) = @_;
        if ($f->{'status'} > 0){
            return  $self->{'colours'}{"col1"},$self->{'colours'}{"lab1"},'border';
        } elsif ($f->{'status'} == 0) {
            return  $self->{'colours'}{"col2"},$self->{'colours'}{"lab2"},'border';
        } else {
            return  $self->{'colours'}{"col3"},$self->{'colours'}{"lab3"},'border';
        }
}

sub image_label {
    my ($self, $f ) = @_;
    return ($f->id,'overlaid');
}

sub zmenu {
    my ($self, $f ) = @_;
    my $zmenu = { 
        'caption' => "EnsEMBL Clones: ".$f->id,
        '01:bp: '.$f->start."-".$f->end => '',
        '02:length: '.($f->end-$f->start+1). ' bps' => '',
        '03:Jump to EnsEMBL' => $self->href($f),
    };
    return $zmenu;
}

1;
