###############################################################################
#
# $Id$
#
# This is the MakeMaker skeleton for Net::ISBNDB.
#
###############################################################################
use ExtUtils::MakeMaker;

$CLEAN = 'pod2html-* *.html *.log t/*.log META.yml SIGNATURE *.ppd ';

WriteMakefile(
              (MM->can('signature_target') ? (SIGN => 1) : ()),
              NAME      => 'Net::ISBNDB',
              VERSION   => '0.10',
              AUTHOR    => 'Randy J. Ray',
              ABSTRACT  =>
              'Data and communication classes for talking to isbndb.com',
              PREREQ_PM => { XML::LibXML => 1.58,
                             LWP         => 5.801 },
              dist      => { COMPRESS => 'gzip -9f' },
              clean     => { FILES => $CLEAN },
             );
