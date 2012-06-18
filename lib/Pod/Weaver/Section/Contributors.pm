package Pod::Weaver::Section::Contributors;
use Moose;
with 'Pod::Weaver::Role::Section';
# ABSTRACT: a section listing contributors

use Moose::Autobox;

use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Verbatim;

sub mvp_multivalue_args { qw( contributors ) }

has contributors => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub{ [] },
);

sub weave_section {
    my ($self, $document, $input) = @_;

    my $contributors = $self->contributors;
    $contributors = $input->{contributors} if $input && $input->{contributors};
    if ( $input && $input->{zilla} ) {
        my $stash = $input->{zilla}->stash_named('%PodWeaver');
        my $config;
        $config = $stash->get_stashed_config($self) if $stash;
        $contributors = $config->{contributors}     if $config;
    }

    return unless $contributors;

    $contributors = [ $contributors ] unless ref $contributors;

    return unless $contributors->length;

    my $multiple_contributors = $contributors->length > 1;

    my $name = $multiple_contributors ? 'CONTRIBUTORS' : 'CONTRIBUTOR';

    my $result = $contributors->map(sub {
        Pod::Elemental::Element::Pod5::Ordinary->new({
            content => $_,
        }),
    });

    $result = [
        Pod::Elemental::Element::Pod5::Command->new({
            command => 'over', content => '4',
        }),
        $result->map(sub {
            Pod::Elemental::Element::Pod5::Command->new({
                command => 'item', content => '*',
            }),
            $_,
        })->flatten,
        Pod::Elemental::Element::Pod5::Command->new({
            command => 'back', content => '',
        }),
    ] if $multiple_contributors;

    $document->children->push(
        Pod::Elemental::Element::Nested->new({
            type     => 'command',
            command  => 'head1',
            content  => $name,
            children => $result,
        }),
    );
}

no Moose;
1;

__END__
=pod

=head1 SYNOPSIS

dist.ini:

    [PodWeaver]
    [%PodWeaver]
    Contributors.contributors[0] = Keedi Kim (KEEDI)
    Contributors.contributors[1] = Jeen Lee (JEEN)

weaver.ini:

    [Contributors]


=head1 DESCRIPTION

This section adds a listing of the documents contributors.  It expects a C<contributors>
input parameter to be an arrayref of strings.  If no C<contributors> parameter is
given, it will do nothing.  Otherwise, it produces a hunk like this:

  =head1 CONTRIBUTORS

    Contributor One <a1@example.com>
    Contributor Two <a2@example.com>


=head1 SEE ALSO

=over

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::Stash::Plugins>

=item L<Pod::Weaver>

=item L<Pod::Weaver::Section::Authors>

=back


=cut
