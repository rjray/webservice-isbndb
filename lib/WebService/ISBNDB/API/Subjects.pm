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
#   Description:    Specialization of the API class for subjects data.
#
#   Functions:      BUILD
#                   copy
#                   set_id
#                   get_categories
#                   set_categories
#                   normalize_args
#                   find
#
#   Libraries:      Class::Std
#                   Error
#
#   Global Consts:  $VERSION
#
###############################################################################

package WebService::ISBNDB::API::Subjects;

use 5.6.0;
use strict;
use warnings;
use vars qw($VERSION);
use base 'WebService::ISBNDB::API';

use Class::Std;
use Error;

$VERSION = "0.10";

my %id               : ATTR(:init_arg<id> :get<id>  :default<>);
my %name             : ATTR(:name<name>             :default<>);
my %book_count       : ATTR(:name<book_count>       :default<>);
my %marc_field       : ATTR(:name<marc_field>       :default<>);
my %marc_indicator_1 : ATTR(:name<marc_indicator_1> :default<>);
my %marc_indicator_2 : ATTR(:name<marc_indicator_2> :default<>);
my %categories       : ATTR(:init_arg<categories>   :default<>);

###############################################################################
#
#   Sub Name:       BUILD
#
#   Description:    Builder for this class. See Class::Std.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $id       in      scalar    This object's unique ID
#                   $args     in      hashref   The set of arguments currently
#                                                 being considered for the
#                                                 constructor.
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub BUILD
{
    my ($self, $id, $args) = @_;

    $self->set_type('Subjects');

    if ($args->{categories})
    {
        throw Error::Simple("'categories' must be a list-reference")
            unless (ref($args->{categories}) eq 'ARRAY');
        $args->{categories} = [ @{$args->{categories}} ];
    }

    return;
}

###############################################################################
#
#   Sub Name:       copy
#
#   Description:    Copy the Subjects-specific attributes over from target
#                   object to caller.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $target   in      ref       Object of the same class
#
#   Globals:        %id
#                   %name
#                   %book_count
#                   %marc_field
#                   %marc_indicator_1
#                   %marc_indicator_2
#                   %categories
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub copy : CUMULATIVE
{
    my ($self, $target) = @_;

    throw Error::Simple("Argument to 'copy' must be the same class as caller")
        unless (ref($self) eq ref($target));

    my $id1 = ident $self;
    my $id2 = ident $target;

    # Do the simple (scalar) attributes first
    $id{$id1}               = $id{$id2};
    $name{$id1}             = $name{$id2};
    $book_count{$id1}       = $book_count{$id2};
    $marc_field{$id1}       = $marc_field{$id2};
    $marc_indicator_1{$id1} = $marc_indicator_1{$id2};
    $marc_indicator_2{$id1} = $marc_indicator_2{$id2};

    # This must be tested and copied by value
    $categories{$id1}  = [ @{$categories{$id2}}  ] if ref($categories{$id2});

    return;
}

###############################################################################
#
#   Sub Name:       set_id
#
#   Description:    Set the ID attribute on the object. Done manually so that
#                   we can restrict it to this package.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $id       in      scalar    ID, taken from isbndb.com data
#
#   Globals:        %id
#
#   Returns:        $self
#
###############################################################################
sub set_id : RESTRICTED
{
    my ($self, $id) = @_;

    $id{ident $self} = $id;
    $self;
}

###############################################################################
#
#   Sub Name:       set_categories
#
#   Description:    Set the list of Categories objects for this instance. The
#                   list will initially be a list of IDs, taken from the
#                   attributes of the XML. Only upon read-access (via
#                   get_categories) will the list be turned into real objects.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $list     in      ref       List-reference of category data
#
#   Globals:        %categories
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_categories
{
    my ($self, $list) = @_;

    throw Error::Simple("Argument to 'set_categories' must be a list reference")
        unless (ref($list) eq 'ARRAY');

    # Make a copy of the list
    $categories{ident $self} = [ @$list ];

    $self;
}

###############################################################################
#
#   Sub Name:       get_categories
#
#   Description:    Return a list-reference of the Categories. If this is
#                   the first such request, then the category values are going
#                   to be scalars, not objects, and must be converted to
#                   objects before being returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %categories
#
#   Returns:        Success:    list-reference of data
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_categories
{
    my $self = shift;

    my $categories = $categories{ident $self};

    # If any element is not a reference, we need to transform the list
    if (grep(! ref($_), @$categories))
    {
        my $class = $self->class_for_type('Categories');
        # Make sure it's loaded
        eval "require $class;";
        my $cat_id;

        for (0 .. $#$categories)
        {
            unless (ref($cat_id = $categories->[$_]))
            {
                throw Error::Simple("No category found for ID '$cat_id'")
                    unless ref($categories->[$_] = $class->find({ id =>
                                                                  $cat_id }));
            }
        }
    }

    # Make a copy, so the real reference doesn't get altered
    [ @$categories ];
}

###############################################################################
#
#   Sub Name:       find
#
#   Description:    Find a single record using the passed-in search criteria.
#                   Most of the work is done by the super-class: this method
#                   turns a single-argument call into a proper hashref, and/or
#                   turns user-supplied arguments into those recognized by the
#                   API.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $args     in      variable  See text
#
#   Returns:        Success:    result from SUPER::find
#                   Failure:    throws Error::Simple
#
###############################################################################
sub find
{
    my ($self, $args) = @_;

    # First, see if we were passed a single scalar for an argument. If so, it
    # needs to become the id argument
    $args = { publisher_id => $args } unless (ref $args);

    $self->SUPER::find($args);
}

###############################################################################
#
#   Sub Name:       normalize_args
#
#   Description:    Normalize the contents of the $args hash reference, turning
#                   the user-visible (and user-friendlier) arguments into the
#                   arguments that the API expects.
#
#                   Also adds some "results" values, to tailor the returned
#                   content.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Object ref or class name
#                   $args     in      hashref   Reference to the arguments hash
#
#   Returns:        Success:    $args (changed)
#                   Failure:    throws Error::Simple
#
###############################################################################
sub normalize_args
{
    my ($class, $args) = @_;

    my ($key, $value, @keys, $count, $results, %seen);

    # Turn the collection of arguments into a set that the isbndb.com API can
    # use. Each key/value pair has to become a pair of the form "indexX" and
    # "valueX". Some keys, like author and publisher, have to be handled with
    # more attention.
    @keys = keys %$args;
    $count = 0; # Used to gradually increment the "indexX" and "valueX" keys
    foreach $key (@keys)
    {
        $value = $args->{$key};
        delete $args->{$key};
        $count++;

        # A key of "id" needs to be translated as "subject_id"
        if ($key eq 'id')
        {
            $args->{"index$count"} = 'subject_id';
            $args->{"value$count"} = $value;

            next;
        }

        # A key of "category" should become "category_id". If it is a plain
        # scalar, the value carries over. If it is a Categories object, use
        # the "id" method.
        if ($key eq 'category')
        {
            $args->{"index$count"} = 'category_id';
            $args->{"value$count"} =
                (ref $value and
                 $value->isa('WebService::ISBNDB::API::Categories')) ?
                $value->id : $value;

            next;
        }

        # These are the only other allowed search-key(s)
        if ($key =~ /^(:?name|category_id|subject_id)$/)
        {
            $args->{"index$count"} = $key;
            $args->{"value$count"} = $value;

            next;
        }

        throw Error::Simple("'$key' is not a valid search-key for publishers");
    }

    # Add the "results" values that we want
    $args->{results} = [ qw(categories) ];

    $args;
}

1;

=pod

=head1 NAME

WebService::ISBNDB::API::Subjects - Data class for subject information

=head1 SYNOPSIS

    use WebService::ISBNDB::API::Subjects;

    $net_prog = WebService::ISBNDB::API::Subjects->
                    find('internet_programming');

=head1 DESCRIPTION

The B<WebService::ISBNDB::API::Subjects> class extends the
B<WebService::ISBNDB::API> class to add attributes specific to the data
B<isbndb.com> provides on subjects.

=head1 METHODS

The following methods are specific to this class, or overridden from the
super-class.

=head2 Constructor

The constructor for this class may take a single scalar argument in lieu of a
hash reference:

=over 4

=item new($SUBJECT_ID|$ARGS)

This constructs a new object and returns a referent to it. If the parameter
passed is a hash reference, it is handled as normal, per B<Class::Std>
mechanics. If the value is a scalar, it is assumed to be the subject's ID
within the system, and is looked up by that.

If the argument is the hash-reference form, then a new object is always
constructed; to perform searches see the search() and find() methods. Thus,
the following two lines are in fact different:

    $book = WebService::ISBNDB::API::Subjects->
        new({ id => "internet_programming" });

    $book = WebService::ISBNDB::API::Subjects->new('internet_programming');

The first creates a new object that has only the C<id> attribute set. The
second returns a new object that represents the given subject,
with all data present.

=back

The class also defines:

=over 4

=item copy($TARGET)

Copies the target object into the calling object. All attributes (including
the ID) are copied. This method is marked "CUMULATIVE" (see L<Class::Std>),
and any sub-class of this class should provide their own copy() and also mark
it "CUMULATIVE", to ensure that all attributes at all levels are copied.

=back

See the copy() method in L<WebService::ISBNDB::API>.

=head2 Accessors

The following attributes are used to maintain the content of a subject
object:

=over 4

=item id

The unique ID within the B<isbndb.com> system for this subject.

=item name

The name of the subject.

=item book_count

The number of books listed under this subject.

=item marc_field

=item marc_indicator_1

=item marc_indicator_2

These three attributes make up the subject's MARC (MAchine-Readable
Cataloging) information.

=item categories

A list of category objects for the categories the subject is listed in.

=back

The following accessors are provided to manage these attributes:

=over 4

=item get_id

Return the category ID.

=item set_id($ID)

Sets the category ID. This method is restricted to this class, and cannot be
called outside of it. In general, you shouldn't need to set the ID after the
object is created, since B<isbndb.com> is a read-only source.

=item get_name

Return the author's name. This is the full name, as would appear in the
C<author_text> field of a B<WebService::ISBNDB::API::Books> object.

=item set_name($NAME)

Set the name to the value in C<$NAME>.

=item get_book_count

Returns the number of books under this subject.

=item set_book_count($COUNT)

Set the number of books under this subject.

=item get_marc_field

Get the MARC field value.

=item set_marc_field($MARC)

Set the MARC field value.

=item get_marc_indicator_1

Get the value for the first MARC indicator.

=item set_marc_indicator_1($MARC_1)

Set the value for the first MARC indicator.

=item get_marc_indicator_2

Get the value for the second MARC indicator.

=item set_marc_indicator_2($MARC_1)

Set the value for the second MARC indicator.

=item get_categories

Return a list-reference of the categories this aubject is listed in. Each
element of the list will be an instance of
B<WebService::ISBNDB::API::Categories>.

=item set_categories($CATEGORIES)

Set the categories to the list-reference given in C<$CATEGORIES>. When the
author object is first created from the XML data, this list is populated
with the IDs of the categories. They are not converted to objects until
requested (via get_categories()) by the user.

=back

=head2 Utility Methods

Besides the constructor and the accessors, the following methods are provided
for utility:

=over 4

=item find($ARG|$ARGS)

This is a specialization of find() from the parent class. It allows the
argument passed in to be a scalar in place of the usual hash reference. If the
value is a scalar, it is searched for as if it were the ID. If the value is a
hash reference, it is passed to the super-class method.

=item normalize_args($ARGS)

This method maps the user-visible arguments as defined for find() and search()
into the actual arguments that must be passed to the service itself. In
addition, some arguments are added to the request to make the service return
extra data used for retrieving categories, location, etc. The
method changes C<$ARGS> in place, and also returns C<$ARGS> as the value from
the method.

=back

See the next section for an explanation of the available keys for searches.

=head1 SEARCHING

Both find() and search() allow the user to look up data in the B<isbndb.com>
database. The allowable search fields are limited to a certain set, however.
When either of find() or search() are called, the argument to the method
should be a hash reference of key/value pairs to be passed as arguments for
the search (the exception being that find() can accept a single string, which
has special meaning as detailed earlier).

Searches in the text fields are done in a case-insensitive manner.

The available search keys are:

=over 4

=item name

The value should be a text string. The search returns authors whose name
matches the string.

=item id|subject_id

The value should be a text string. The search returns the author whose ID
in the system matches the value.

=item category|category_id

You can search for subjects in a given category. If the search-key is
C<category>, the value may be either the ID or a category object. If it is an
object, the ID is derived from it. If the search-key is C<category_id>, the
value must be the ID itself.

=back

Note that the names above may not be the same as the corresponding parameters
to the service. The names are chosen to match the related attributes as
closely as possible, for ease of understanding.

=head1 EXAMPLES

Get the record for the subject, "perl_computer_program_language":

    $perl = WebService::ISBNDB::API::Subjects->
                find('perl_computer_program_language');

Find all subject with "perl" in their name:

    $allperl = WebService::ISBNDB::API::Subjects->
                   search({ name => 'perl' });

=head1 CAVEATS

The data returned by this class is only as accurate as the data retrieved from
B<isbndb.com>.

The list of results from calling search() is currently limited to 10 items.
This limit will be removed in an upcoming release, when iterators are
implemented.

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<WebService::ISBNDB::API::Categories>

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
