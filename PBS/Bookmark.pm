package PBS::Bookmark; 

use strictures 2; 
use namespace::autoclean; 
use Term::ANSIColor; 
use File::Find; 
use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 
use experimental qw( signatures ); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => HashRef,  
    lazy      => 1, 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $bookmark = { }; 

        for my $job ( $self->get_user_jobs ) { 
            my %mod_time = (); 
            find( 
                { wanted => 
                    sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, 
                    follow => $self->follow_symbolic 
                }, $self->get_init( $job ) 
            ); 

            # current OUTCAR
            my $outcar =  ( 
                sort { $mod_time{$a} <=> $mod_time{$b} } 
                keys %mod_time 
            )[0] =~ s/\/OUTCAR//r; 

            $bookmark->{$job} = $outcar if $outcar; 
        }

        return $bookmark; 
    }, 

    handles   => { 
        has_bookmark => 'exists', 
        get_bookmark => 'get'
    } 
); 

sub print_job_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 
        printf "%-9s=> %s\n", ucfirst('bookmark'), $bookmark          
    }
} 

sub delete_job_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) { 
        unlink join '/', $self->get_bookmark( $job), 'OUTCAR'
    } 
} 
1 
