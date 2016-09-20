package PBS::Prompt; 

use strict; 
use warnings FATAL => 'all'; 

use Moose::Role;  

use namespace::autoclean; 
use experimental qw(signatures); 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst($method), $job;  
    my $reply = <STDIN>;  

    return 1 if $reply =~ /y|yes/i 
} 

1 
