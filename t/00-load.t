#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Mustache' );
}

diag( "Testing Template::Mustache $Template::Mustache::VERSION, Perl $], $^X" );
