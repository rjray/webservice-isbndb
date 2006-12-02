###############################################################################
#
# This file copyright (c) 2006 by Randy J. Ray, all rights reserved
#
# Copying and distribution are permitted under the terms of the Artistic
# License as distributed with Perl versions 5.005 and later. See
# http://language.perl.com/misc/Artistic.html
#
###############################################################################
#
#   $Id$
#
#   Description:    Empty, placeholder module for version-test capability.
#
#   Functions:      None
#
###############################################################################

package WebService::ISBNDB;

use 5.6.0;
use strict;
use vars qw($VERSION);

$VERSION = "0.32";

1;

=pod

=head1 NAME

WebService::ISBNDB - A Perl extension to access isbndb.com

=head1 DESCRIPTION

This module provides no routines or methods. Its purpose is to provide a
testable version for other modules that depend on this distribution.

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<WebService::ISBNDB::API::Authors>,
L<WebService::ISBNDB::Books>, L<WebService::ISBNDB::API::Categories>,
L<WebService::ISBNDB::API::Publishers>, L<WebService::ISBNDB::API::Subjects>,
L<WebService::ISBNDB::Agent>, L<WebService::ISBNDB::Agent::REST>,
L<WebService::ISBNDB::Iterator>

=head1 AUTHOR

Randy J. Ray E<lt>rjray@blackperl.comE<gt>

=head1 COPYRIGHT

This module and the code within are copyright (c) 2006 by Randy J. Ray and
released under the terms of the Artistic License
(http://www.opensource.org/licenses/artistic-license.php). This
code may be redistributed under either the Artistic License or the GNU
Lesser General Public License (LGPL) version 2.1
(http://www.opensource.org/licenses/lgpl-license.php).

=cut
