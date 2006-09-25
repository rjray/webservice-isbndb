#!/usr/bin/perl

# $Id$

use Module::Build;

my $build = Module::Build->new(
    module_name    => 'WebService::ISBNDB',
    license        => 'artistic',
    requires       => { perl => '5.6.0',
                        LWP => '5.801',
                        Business::ISBN => '1.80',
                        Class::Std => '0.0.8',
                        Error => '0.17',
                        XML::LibXML => '1.58' },
    build_requires => { Test::More => 0 },
    recommends     => { Date::Parse => '2.27' },
    dist_author    => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract  =>
    'Data and communication classes for talking to isbndb.com',
    dist_version   => '0.20',
    sign           => 'yes, please',
);

$build->add_to_cleanup(qw(META.yml WebService-ISBNDB-* *.html *.log t/*.log));
$build->create_build_script;
