package PBS::Job;

# pragma 
use autodie; 
use warnings FATAL => 'all'; 

# core 
use File::Find; 
use File::Path qw(rmtree); 
use Term::ANSIColor; 

# cpan  
use Moose; 
use namespace::autoclean; 

# features  
use experimental qw(signatures);  

# Moose types
use PBS::Types qw(ID); 

# Moose roles 
with qw(PBS::Qstat PBS::Prompt); 

# Moose attributes 
has 'id', ( 
    is       => 'ro', 
    isa      => ID, 
    required => 1 
); 

has 'bootstrap', ( 
    is        => 'ro', 
    isa       => 'Str', 
    predicate => 'has_bootstrap', 
    lazy      => 1,   
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return (grep { -d and /bootstrap-\d+/ } glob "${\$self->init}/*" )[0] 
    },    
); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => 'Str', 
    predicate => 'has_bookmark',
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my %mod_time = (); 
        find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $self->init ); 
        return ( sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 
    }, 
); 

# Moose modifiers 
after info => sub ( $self ) { 
    if ( $self->has_bookmark ) { 
        printf "%-9s=> %s\n", ucfirst('bookmark'), $self->bookmark =~ s/${\$self->init}\///r;  
    } 
}; 

# simplify the constructor: ->new(ID) 
override BUILDARGS => sub ( $class, @args ) { 
    if ( @args == 1 and ID->check($args[0]) ) { return { id => $args[0] } } 

    return super; 
}; 

# Moose methods
# delete and clean bootstrap directory 
sub delete ( $self ) { 
    $self->info; 

    if ( $self->prompt('delete') ) { 
        system 'qdel', $self->id;  
        if ( $self->has_bootstrap ) { rmtree $self->bootstrap };  
    }
} 

# reset job by deleting latest OUTCAR  
sub reset ( $self ) { 
    $self->info; 

    if ( $self->has_bookmark and $self->prompt('reset') ) { unlink join '/', $self->bookmark, 'OUTCAR' }
} 

sub info_oneline ( $self ) {  
    # depending on status of the job, print bookmark or init
    my $dir = $self->state eq "R" ? 
    $self->bookmark =~ s/$ENV{HOME}/~/r : 
    $self->init     =~ s/$ENV{HOME}/~/r; 

    printf "%s %s (%s)\n", $self->id, $dir , $self->state; 
} 

# parse output of qstatf -> set bootstrap -> set bookmark 
sub BUILD ( $self, @args ) { 
    $self->qstat;     
    # owner of the job is also the user 
    # who runs the scripts 
    if ( $self->owner eq $ENV{USER} ) { 
        $self->bootstrap; 
        $self->bookmark; 
    }
}

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
