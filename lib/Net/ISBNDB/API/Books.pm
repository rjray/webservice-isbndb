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
#   Description:    Specialization of the API class for book data.
#
#   Functions:      BUILD
#                   copy
#                   find
#                   get_authors
#                   set_authors
#                   get_subjects
#                   set_subjects
#                   set_id
#                   set_isbn
#                   get_publisher
#                   normalize_args
#
#   Libraries:      Class::Std
#                   Error
#                   Business::ISBN
#
#   Global Consts:  $VERSION
#
###############################################################################

package Net::ISBNDB::API::Books;

use 5.6.0;
use strict;
use warnings;
use vars qw($VERSION);
use base 'Net::ISBNDB::API';

use Class::Std;
use Error;
use Business::ISBN qw(is_valid_checksum);

$VERSION = "0.10";

# Attributes for the Books class
my %id             : ATTR(:get<id>   :init_arg<id>             :default<>);
my %isbn           : ATTR(:get<isbn> :init_arg<isbn>           :default<>);
my %title          : ATTR(:name<title>                         :default<>);
my %longtitle      : ATTR(:name<longtitle>                     :default<>);
my %authors_text   : ATTR(:name<authors_text>                  :default<>);
my %authors        : ATTR(:init_arg<authors>                   :default<>);
my %publisher_text : ATTR(:name<publisher_text>                :default<>);
my %publisher      : ATTR(:init_arg<publisher> :set<publisher> :default<>);
my %subjects       : ATTR(:init_arg<subjects>                  :default<>);

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

    $self->set_type('Books');

    return;
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
    # needs to become either an ISBN or title argument.
    if (! ref($args))
    {
        if (is_valid_checksum($args) eq Business::ISBN::GOOD_ISBN)
        {
            $args = { isbn => $args };
        }
        else
        {
            $args = { title => $args };
        }
    }

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

        # If the key is 'author', it may be a name or an Authors object. If it
        # is not an object, it has to become a "full" key, which is very non-
        # specific.
        if ($key eq 'author')
        {
            if (ref $value)
            {
                if ($value->isa('Net::ISBNDB::API::Authors'))
                {
                    $args->{"index$count"} = 'person_id';
                    $args->{"value$count"} = $value->get_id;
                }
                else
                {
                    throw Error::Simple("Value for argument '$key' must be " .
                                        'string or Net::ISBNDB::API::Authors' .
                                        ' derivative');
                }
            }
            else
            {
                $args->{"index$count"} = 'combined';
                $args->{"value$count"} = $value;
            }

            next;
        }

        # If the key is 'publisher', treat the same as with author
        if ($key eq 'publisher')
        {
            if (ref $value)
            {
                if ($value->isa('Net::ISBNDB::API::Publishers'))
                {
                    $args->{"index$count"} = 'publisher_id';
                    $args->{"value$count"} = $value->get_id;
                }
                else
                {
                    throw Error::Simple("Value for argument '$key' must be " .
                                        'string or ' .
                                        'Net::ISBNDB::API::Publishers ' .
                                        'derivative');
                }
            }
            else
            {
                $args->{"index$count"} = 'combined';
                $args->{"value$count"} = $value;
            }

            next;
        }

        # A subject can be an object or an ID.
        if ($key eq 'subject')
        {
            if (ref $value)
            {
                if ($value->isa('Net::ISBNDB::API::Subjects'))
                {
                    $args->{"index$count"} = 'subject_id';
                    $args->{"value$count"} = $value->get_id;
                }
                else
                {
                    throw Error::Simple("Value for argument '$key' must be " .
                                        'string or Net::ISBNDB::API::Subjects' .
                                        ' derivative');
                }
            }
            else
            {
                $args->{"index$count"} = 'subject_id';
                $args->{"value$count"} = $value;
            }

            next;
        }

        # These are the only other allowed search-keys
        if ($key =~ /^(:?dewey_decimal|lcc_number|full|combined|title|isbn)$/)
        {
            $args->{"index$count"} = $key;
            $args->{"value$count"} = $value;

            next;
        }

        throw Error::Simple("'$key' is not a valid search-key for books");
    }

    # Add the "results" values that we want
    $args->{results} = [ qw(subjects authors) ];

    $args;
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
#   Sub Name:       set_isbn
#
#   Description:    Set the ISBN for this object. Tests the new value before
#                   assigning it.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $isbn     in      scalar    New ISBN value
#
#   Globals:        %isbn
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_isbn
{
    my ($self, $isbn) = @_;

    throw Error::Simple("The value '$isbn' is not a valid ISBN")
        unless (is_valid_checksum($isbn) eq Business::ISBN::GOOD_ISBN);
    $isbn{ident $self} = $isbn;

    $self;
}

###############################################################################
#
#   Sub Name:       get_publisher
#
#   Description:    Retrieve the "publisher" attribute for this object. If the
#                   value is a string rather than a reference, assume that it
#                   is an ID, and fetch the actual Publisher object before
#                   returning the value.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %publisher
#
#   Returns:        Success:    Publisher object
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_publisher
{
    my $self = shift;

    my $id = ident $self;

    my $publisher = $publisher{$id};
    unless (ref $publisher)
    {
        my $class = $self->class_for_type('Publishers');
        # Make sure it's loaded
        eval "require $class;";
        $publisher = $class->find({ publisher_id => $publisher });
        $publisher{$id} = $publisher;
    }

    $publisher;
}

###############################################################################
#
#   Sub Name:       set_authors
#
#   Description:    Set the list of Authors objects for this instance. The list
#                   will initially be a list of IDs, taken from the attributes
#                   of the XML. Only upon read-access (via get_authors) will
#                   the list be turned into real objects.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $list     in      ref       List-reference of author data
#
#   Globals:        %authors
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_authors
{
    my ($self, $list) = @_;

    throw Error::Simple("Argument to 'set_authors' must be a list reference")
        unless (ref($list) eq 'ARRAY');

    # Make a copy of the list
    $authors{ident $self} = [ @$list ];

    $self;
}

###############################################################################
#
#   Sub Name:       get_authors
#
#   Description:    Return a list-reference of the authors of the book. If this
#                   is the first such request, then the author values are going
#                   to be scalars, not objects, and must be converted to
#                   objects before being returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %authors
#
#   Returns:        Success:    list-reference of data
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_authors
{
    my $self = shift;

    my $authors = $authors{ident $self};

    # If the first element is not a reference, we need to transform the list
    if (grep(! ref($_), @$authors))
    {
        my $class = $self->class_for_type('Authors');
        # Make sure it's loaded
        eval "require $class;";
        my $auth_id;

        for (0 .. $#$authors)
        {
            unless (ref($auth_id = $authors->[$_]))
            {
                throw Error::Simple("No author found for ID '$auth_id'")
                    unless ref($authors->[$_] = $class->find({ id =>
                                                               $auth_id }));
            }
        }
    }

    # Make a copy, so the real reference doesn't get altered
    [ @$authors ];
}

###############################################################################
#
#   Sub Name:       set_subjects
#
#   Description:    Set the list of Subjects objects for this instance. The
#                   list will initially be a list of IDs, taken from the
#                   attributes of the XML. Only upon read-access (via
#                   get_subjects) will the list be turned into real objects.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $list     in      ref       List-reference of category data
#
#   Globals:        %subjects
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_subjects
{
    my ($self, $list) = @_;

    throw Error::Simple("Argument to 'set_subjects' must be a list reference")
        unless (ref($list) eq 'ARRAY');

    # Make a copy of the list
    $subjects{ident $self} = [ @$list ];

    $self;
}

###############################################################################
#
#   Sub Name:       get_subjects
#
#   Description:    Return a list-reference of the book subjects. If this is
#                   the first such request, then the subject values are going
#                   to be scalars, not objects, and must be converted to
#                   objects before being returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %subjects
#
#   Returns:        Success:    list-reference of data
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_subjects
{
    my $self = shift;

    my $subjects = $subjects{ident $self};

    # If any element is not a reference, we need to transform the list
    if (grep(! ref($_), @$subjects))
    {
        my $class = $self->class_for_type('Subjects');
        # Make sure it's loaded
        eval "require $class;";
        my $subj_id;

        for (0 .. $#$subjects)
        {
            unless (ref($subj_id = $subjects->[$_]))
            {
                throw Error::Simple("No subject found for ID '$subj_id'")
                    unless ref($subjects->[$_] = $class->find({ id =>
                                                                $subj_id }));
            }
        }
    }

    # Make a copy, so the real reference doesn't get altered
    [ @$subjects ];
}

###############################################################################
#
#   Sub Name:       copy
#
#   Description:    Copy the Books-specific attributes over from target object
#                   to caller.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $target   in      ref       Object of the same class
#
#   Globals:        %id
#                   %isbn
#                   %title
#                   %longtitle
#                   %authors
#                   %authors_text
#                   %publisher
#                   %publisher_text
#                   %subjects
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
    $id{$id1}             = $id{$id2};
    $isbn{$id1}           = $isbn{$id2};
    $title{$id1}          = $title{$id2};
    $longtitle{$id1}      = $longtitle{$id2};
    $authors_text{$id1}   = $authors_text{$id2};
    $publisher_text{$id1} = $publisher_text{$id2};
    $publisher{$id1}      = $publisher{$id2};

    # Each of these must be tested, and references copied by value
    $authors{$id1}  = [ @{$authors{$id2}}  ] if ref($authors{$id2});
    $subjects{$id1} = [ @{$subjects{$id2}} ] if ref($subjects{$id2});

    return;
}

1;

=pod

=head1 NAME

Net::ISBNDB::API::Books - Object representation of book data from isbndb.com

=head1 SYNOPSIS

    use Net::ISBNDB::API::Books;

    my $book = Net::ISBNDB::API->new({ api_key => $key,
                                       isbn => '0596002068' });

=head1 DESCRIPTION

This class represents book data from B<isbndb.com>. It is a sub-class of
B<Net::ISBNDB::API> (see L<Net::ISBNDB::API>), and inherits all the attributes
and methods from that class.

=head1 METHODS

The following methods are specific to this class, or overridden from the
super-class.

=head2 Constructor

The constructor for this class may take a single scalar argument in lieu of a
hash reference:

=over 4

=item new($ISBN|$TITLE|$ARGS)

This constructs a new object and returns a referent to it. If the parameter
passed is a hash reference, it is handled as normal, per B<Class::Std>
mechanics. If the value is a scalar, it is tested to see if it is a valid
ISBN (using the B<Business::ISBN> module). If it is, it is used as a search
key to find the corresponding book. If it is not a valid ISBN, it is assumed
to be the title, and is likewise used as a search key. Since the title may
return more than one match, the first matching record from the source is used
to construct the object.

If the argument is the hash-reference form, then a new object is always
constructed; to perform searches see the search() and find() methods. Thus,
the following two lines are in fact different:

    $book = Net::ISBNDB::API::Books->new({ isbn => '0596002068' });

    $book = Net::ISBNDB::API::Books->new('0596002068');

The first creates a new object that has only the C<isbn> attribute set. The
second returns a new object that represents the book with ISBN C<0596002068>,
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

See the copy() method in L<Net::ISBNDB::API>.

=head2 Accessors

The following attributes are used to maintain the content of a book object:

=over 4

=item id

The unique ID within the B<isbndb.com> system for this book.

=item isbn

The ISBN (International Standard Book Number) for the book (without hyphens).

=item title

The title of the book.

=item longtitle

The full title of the book, including any sub-title.

=item authors

An array (stored as a reference) of the B<Net::ISBNDB::API::Authors> objects
that refer to the authors of the book. These are not actually loaded from
the service until they are first fetched.

=item authors_text

A simple textual representation of the authors, as returned by the service.
This may be more convenient to use than the author objects, if you only want
to display the names themselves.

=item publisher

The B<Net::ISBNDB::API::Publisher> object that refers to the book's publisher.
This is not loaded until the first request to fetch it is made.

=item publisher_text

A simple textual representation of the publisher, as returned by the service.
This may be more convenient to use than the object, if you only wish to
display the publisher's name.

=item subjects

An array (stored as a reference) of the B<Net::ISBNDB::API::Subjects> objects
that refer to the subjects this book is associated with. As with the authors,
the actual objects are not loaded until requested.

=back

The following accessors are provided to manage these attributes:

=over 4

=item get_id

Return the book ID.

=item set_id($ID)

Sets the book ID. This method is restricted to this class, and cannot be
called outside of it. In general, you shouldn't need to set the ID after the
object is created, since B<isbndb.com> is a read-only source.

=item get_isbn

Return the ISBN of the book. In general, the ISBN has had any hyphens removed.

=item set_isbn($ISBN)

Set the book ISBN. The value is tested with B<Business::ISBN> to ensure that
the value is a valid ISBN.

=item get_title

Return the common title of the book.

=item set_title($TITLE)

Set the title of the book.

=item get_longtitle

Return the long title of the book. This will include subtitles, for example.

=item set_longtitle($LONGTITLE)

Set the long title of the book.

=item get_authors

Get the list of author objects (instances of B<Net::ISBNDB::API::Authors> or
a sub-class) for the book. The objects are not fetched from the source until
the first call to this method.

=item set_authors($LIST)

Set the list of authors for this book. The value must be a list-reference. If
the values in the list reference are strings instead of objects, then the
first call to get_authors() will convert them into objects. The strings must
be the author ID values as returned by the service.

=item get_authors_text

Return the text-representation of the authors, as returned by the service.

=item set_authors_text($TEXT)

Set the text-representation of the authors.

=item get_publisher

Return the publisher object (instance of B<Net::ISBNDB::API::Publishers> or a
sub-class) for this book. The object is not loaded from the source until the
first request to this method.

=item set_publisher($PUBLISHER)

Set the publisher for this book. The value should be either a publisher object
or a string containing the publisher ID. If the ID is set as the value, the
next call to get_publisher() will resolve it into an object.

=item get_subjects

Get the list of subject objects (instances of B<Net::ISBNDB::API::Subjects>
or a sub-class) for the book. The objects are not fetched from the source
until the first call to this method.

=item set_subjects($LIST)

Set the list of subjects. The value must be a list-reference, and may contain
either the objects themselves or the subject ID values as returned by the
source. If the content is the ID values, then the next call to get_subjects()
will resolve them to objects.

=back

=head2 Utility Methods

Besides the constructor and the accessors, the following methods are provided
for utility:

=over 4

=item find($ARG|$ARGS)

This is a specialization of find() from the parent class. It allows the
argument passed in to be a scalar in place of the usual hash reference. If the
value is a scalar, it is tested to see if it is a valid ISBN, and if so the
search is made against the ISBN with that value. If the scalar value is not a
valid ISBN, the search is made against the title instead. If the value is a
hash reference, it is passed to the super-class method.

=item normalize_args($ARGS)

This method maps the user-visible arguments as defined for find() and search()
into the actual arguments that must be passed to the service itself. In
addition, some arguments are added to the request to make the service return
extra data used for retrieving subjects, publisher information, etc. The
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

=item title

The value should be a text string. The search returns books whose title
matches the string.

=item isbn

The value should be a text string. The search returns the book whose ISBN
matches the string. The string is not checked for validity, so a bad ISBN
will simply not return any records.

=item author

The value for this key should be either an object of the
B<Net::ISBNDB::API::Authors> class (or sub-class thereof), or a text string.
If the value is an object, the search is done against the specific author ID.
If the value is a string, the search is done using the "combined" search key,
and may return results unrelated to the intended query.

=item publisher

The value for this key may be an object of the B<Net::ISBNDB::API::Publishers>
class (or sub-class thereof) or a text string. If it is an object, the ID is
used in a specific search. If the value is a string, it is used with the
"combined" search-key, and may return unexpected results.

=item subject

The value for this key is expected to be either an object (of the
B<Net::ISBNDB::API::Subjects> class or sub-class thereof) or a literal subject
ID as a string. The subject cannot be searched for using the "combined" key.

=item combined

The value should be a text string, and is searched against a combined field
that includes titles, authors and publisher names.

=item full

The value should be a text string, and is searched against almost all of the
textual data, including title, authors, publishers, summary, notes, award
information, etc.

=item dewey_decimal

The value should be a Dewey Decimal Classification number, and is used
directly in the search.

=item lcc_number

The value should be a Library of Congress Classification number, and is used
directly in the search.

=back

Note that the names above may not be the same as the corresponding parameters
to the service. The names are chosen to match the related attributes as
closely as possible, for ease of understanding.

=head1 EXAMPLES

Search for all books with "perl" in the title:

    $perlbooks = Net::ISBNDB::API::Books->search({ title => "perl" });

Search for all books by Edgar Allan Poe:

    $poebooks = Net::ISBNDB::API::Books->search({ author =>
                                                  'edgar allan poe' });

Find the record for "Progamming Web Services With Perl":

    $pwswp = Net::ISBNDB::API::Books->find('0596002068');

=head1 CAVEATS

The data returned by this class is only as accurate as the data retrieved from
B<isbndb.com>.

The list of results from calling search() is currently limited to 10 items.
This limit will be removed in an upcoming release, when iterators are
implemented.

=head1 SEE ALSO

L<Net::ISBNDB::API>, L<Net::ISBNDB::API::Authors>,
L<Net::ISBNDB::API::Publishers>, L<Net::ISBNDB::API::Subjects>,
L<Business::ISBN>

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
