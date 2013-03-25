package Pod::Weaver::Section::Contributors;
use Moose;
with 'Pod::Weaver::Role::Section';
# ABSTRACT: a section listing contributors
# CONTRIBUTOR: Carnë Draug <cdraug@cpan.org>

use Moose::Autobox;

use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Verbatim;

=for Pod::Coverage mvp_multivalue_args
=cut

sub mvp_multivalue_args { qw( contributors ) }

has contributors => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub{ [] },
);

=for Pod::Coverage weave_section
=cut

sub weave_section {
    my ($self, $document, $input) = @_;
    my @contributors;

    ## 1- get contributors passed to Pod::Weaver::Section::Contributors
    push (@contributors, @{$self->contributors});

    ## 2 - get contributors passed to Dist::Zilla::Stash::PodWeaver
    push (@contributors, @{$input->{contributors}}) if $input->{contributors};
    if ( $input->{zilla} ) {
        my $stash = $input->{zilla}->stash_named('%PodWeaver');
        my ($config, $contri);
        $config = $stash->get_stashed_config($self) if $stash;
        $contri = $config->{contributors}           if $config;
        push (@contributors, @{$contri})         if $contri;
    }

    ## 3 - get contributors from source comments
    my $ppi_document = $input->{ppi_document};
    $ppi_document->find( sub {
        my $ppi_node = $_[1];
        if ($ppi_node->isa('PPI::Token::Comment') &&
            $ppi_node->content =~ qr/^\s*#+\s*CONTRIBUTORS?:\s*(.+)$/m ) {
            push (@contributors, $1);
        }
        return 0;
    });

    ## 4 - remove repeated names, and sort them alphabetically
    @contributors = List::MoreUtils::uniq (@contributors);
    @contributors = sort (@contributors);

    return unless @contributors;
    my $multiple_contributors = @contributors > 1;
    my $name = $multiple_contributors ? 'CONTRIBUTORS' : 'CONTRIBUTOR';

    my $result = [map {
        Pod::Elemental::Element::Pod5::Ordinary->new({
            content => $_,
        }),
    } @contributors];

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

on dist.ini:

    [PodWeaver]
    [%PodWeaver]
    Contributors.contributors[0] = Keedi Kim (KEEDI)
    Contributors.contributors[1] = Jeen Lee (JEEN)

and/or weaver.ini:

    [Contributors]
    contributors = Keedi Kim (KEEDI)
    contributors = Jeen Lee (JEEN)

and/or in the source of individual files:

    # CONTRIBUTOR:  Keedi Kim (KEEDI)
    # CONTRIBUTORS: Jeen Lee (JEEN)

=head1 DESCRIPTION

This section adds a listing of the documents contributors.  It expects a C<contributors>
input parameter to be an arrayref of strings.  If no C<contributors> parameter is
given, it will do nothing.  Otherwise, it produces a hunk like this:

  =head1 CONTRIBUTORS

    Contributor One <a1@example.com>
    Contributor Two <a2@example.com>

To support distributions with multiple modules, it is also able to derive a list
of contributors in a file basis by looking at comments on each module. Names of
contributors on the source, will only appear on the POD of those modules.

=head1 SEE ALSO

=over

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::Stash::Plugins>

=item L<Pod::Weaver>

=item L<Pod::Weaver::Section::Authors>

=back


=cut
