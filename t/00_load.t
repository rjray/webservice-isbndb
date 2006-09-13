#!/usr/bin/perl

use strict;
use vars qw(@MODULES);

use Test::More;

# $Id$
# Verify that the individual modules will load

BEGIN
{
    @MODULES = qw(Net::ISBNDB::API Net::ISBNDB::API::Books
                  Net::ISBNDB::API::Publishers Net::ISBNDB::API::Subjects
                  Net::ISBNDB::Agent Net::ISBNDB::Agent::REST);

    plan tests => scalar(@MODULES);
}

for (@MODULES)
{
    use_ok $_;
}

exit 0;
