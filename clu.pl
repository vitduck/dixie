#!/usr/bin/env perl 

use strict; 
use warnings;  
use feature qw( switch );  
use experimental qw( smartmatch );  

use Data::Printer; 
use PBS::CLU;  

my $pbs = PBS::CLU->new_with_options; 

my ( $mode, @jobs ) = $pbs->extra_argv->@*; 

# set job 
$pbs->set_job( \@jobs ) if @jobs; 

given ( $mode // 'default' ) { 
    when ( /status/ ) { $pbs->status } 
    when ( /delete/ ) { $pbs->delete }
    when ( /reset/  ) { $pbs->reset  } 
    default           { $pbs->help( 0 ) }
} 
