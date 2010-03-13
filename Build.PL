use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Mustache',
    license             => 'perl',
    dist_author         => q{Chas. J. Owens IV <chas.owens@gmail.com>},
    dist_version_from   => 'lib/Template/Mustache.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Template-Mustache-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
