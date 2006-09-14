#!/usr/bin/perl

# $Id$

use Module::Build;

my $build = Module::Build->new(
    module_name    => 'WebService::ISBNDB',
    license        => 'artistic',
    requires       => { perl => '5.6.0',
                        LWP => '5.801',
                        XML::LibXML => '1.58' },
    build_requires => { Test::More => 0 },
    dist_author    => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract  =>
    'Data and communication classes for talking to isbndb.com',
    dist_version   => '0.12',
    sign           => 'yes, please',
);

$build->add_to_cleanup(qw(META.yml WebService-ISBNDB-* *.html *.log t/*.log));
$build->create_build_script;
