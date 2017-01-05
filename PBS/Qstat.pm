package PBS::Qstat; 

use Moose::Role;  
use MooseX::Types::Moose qw/Undef Str HashRef/;  
use IO::Pipe; 

use namespace::autoclean; 
use feature 'switch'; 
use experimental qw/signatures smartmatch/;  

my @pbs_attributes = qw/owner name state queue nodes walltime elapsed init/;  

# automatically install pbs attributes
for my $name ( @pbs_attributes ) {
    has $name, ( 
        is        => 'ro', 
        isa       => HashRef[ Str | Undef ],  
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef, 
        default   => sub ( $self ) { $self->_build_attribute( $name ) }, 
        handles   => { 'get_'.$name => 'get' } 
    ); 
}

has 'qstat', ( 
    is       => 'ro', 
    isa      => HashRef,  
    traits   => [ 'Hash' ],
    lazy     => 1, 
    init_arg => undef,  
    builder  => '_build_qstat', 
    handles  => { isa_job => 'exists' } 
); 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @pbs_attributes ) { 
        my $reader = 'get_'.$attr;  
        
        printf "%-9s=> %s\n", ucfirst( $attr ), $self->$reader( $job );  
    } 
}

sub _build_qstat ( $self ) { 
    my $qstat = {};  
    my $pipe  = IO::Pipe->new->reader("qstat -f");  

    while ( <$pipe> ) {  
        if ( /Job Id: (\d+)\..*$/ ) { 
            my $id = $1; 
            $qstat->{ $id } = {};  

            # basic PBS status 
            while ( local $_ = <$pipe> ) {    
                if    ( /job_name = (.*)/i                ) { $qstat->{ $id }{ name }     = $1 } 
                elsif ( /job_owner = (.*)@/i              ) { $qstat->{ $id }{ owner }    = $1 }
                elsif ( /server = (.*)/i                  ) { $qstat->{ $id }{ server }   = $1 }
                elsif ( /job_state = (\w)/i               ) { $qstat->{ $id }{ state }    = $1 } 
                elsif ( /queue = (.*)/i                   ) { $qstat->{ $id }{ queue }    = $1 } 
                elsif ( /resource_list.nodes = (.*)/i     ) { $qstat->{ $id }{ nodes }    = $1 } 
                elsif ( /resource_list.walltime = (.*)/i  ) { $qstat->{ $id }{ walltime } = $1 } 
                elsif ( /resources_used.walltime = (.*)/i ) { $qstat->{ $id }{ elapsed }  = $1 } 
                elsif ( /PBS_O_WORKDIR=(.+?),/            ) { $qstat->{ $id }{ init }     = $1 }  
                elsif ( /^\s+$/                           ) { last                             } 
            }
        }
    }
        
    $pipe->close; 

    return $qstat; 
}

sub _build_attribute ( $self, $attr_name ) { 
    my %attr = (); 

    while ( my ( $id, $qstat ) = each $self->qstat->%* ) { 
        $attr{ $id } = $qstat->{ $attr_name }     
    } 
    
    return \%attr
} 

1
