package Pod::Weaver::Section::Contributors;
use Moose;
with 'Pod::Weaver::Role::Section';
# ABSTRACT: a section listing contributors

use List::Util 1.45 'uniq';

use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Verbatim;


=attr head

The heading level of this section.  If 0, it inserts an ordinary piece of text
with no heading. Defaults to 1.

In case the value is passed both to Pod::Weaver and to the Pod::Weaver stash,
it uses the value found in the stash.

=cut

has head => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => 1,
);

=for Pod::Coverage mvp_multivalue_args
=cut

sub mvp_multivalue_args { qw( contributors ) }

=attr contributors

The list of contributors.

In case the value is passed to C<weave_section()>, to Pod::Weaver
and to the Pod::Weaver stash, it merges all contributors.

=cut

has contributors => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub{ [] },
);

=attr all_modules

Enable this if you want to add the CONTRIBUTOR/CONTRIBUTORS section to
all the modules in a dist, not only the main one. Defaults to false.

In case the value is passed both to Pod::Weaver and to the Pod::Weaver stash,
it uses the value found in the stash.

=cut

has all_modules => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);

=for Pod::Coverage weave_section
=cut

sub weave_section {
    my ($self, $document, $input) = @_;

    my $stash = $input->{zilla} ? $input->{zilla}->stash_named('%PodWeaver') : undef;

    ## get configs ('head', 'contributors', 'all_modules') provided to [%PodWeaver] in dist.ini
    $stash->merge_stashed_config($self) if $stash;

    ## Is this the main module POD?
    if ( $input->{zilla} && ! $self->all_modules ) {
        return if $input->{zilla}->main_module->name ne $input->{filename};
    }

    #
    # assemble list of contributors
    #

    ## get contributors passed to [%PodWeaver] and Pod::Weaver::Section::Contributors
    my @contributors = @{$self->contributors};

    ## get contributors from $input parameter of weave_section()
    push(@contributors, @{$input->{contributors}})
        if $input->{contributors} && ref($input->{contributors}) eq 'ARRAY';

    ## get contributors from Dist::Zilla metadata
    if ($input->{zilla}
            and my $_contributors = $input->{zilla}->distmeta->{x_contributors}) {
        push(@contributors, @$_contributors);
    }

    ## get contributors from source comments
    my $ppi_document = $input->{ppi_document};
    $ppi_document->find( sub {
        my $ppi_node = $_[1];
        if ($ppi_node->isa('PPI::Token::Comment') &&
            $ppi_node->content =~ qr/^\s*#+\s*CONTRIBUTORS?:\s*(.+)$/m ) {
            push (@contributors, $1);
        }
        return 0;
    });

    ## remove repeated names
    @contributors = uniq (@contributors);

    return unless @contributors;

    #
    # assemble pod elements
    #

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
        ( map {
            Pod::Elemental::Element::Pod5::Command->new({
                command => 'item', content => '*',
            }),
            $_,
        } @$result ),
        Pod::Elemental::Element::Pod5::Command->new({
            command => 'back', content => '',
        }),
    ] if $multiple_contributors;


    #
    # pass list of contributors to the StopWords plugin and Pod::Spell via directives
    #

    my @stopwords = uniq
        map { $_ ? split / / : ()    }
        map { /^(.*?)(\s+<.*)?$/; $1 }
        @contributors;

    unshift @$result, Pod::Elemental::Element::Pod5::Command->new({
        command => 'for', content => join(' ', 'stopwords', @stopwords),
    });


    #
    # create the section at the right level
    #

    if ( $self->head ) {
        push @{ $document->children },
            Pod::Elemental::Element::Nested->new({
                type     => 'command',
                command  => 'head' . $self->head,
                content  => $name,
                children => $result,
            });
    }
    else {
        push @{ $document->children }, @$result;
    }
}

no Moose;
1;

__END__
=pod

=head1 SYNOPSIS

on dist.ini:

    [PodWeaver]
    [%PodWeaver]
    Contributors.head = 2
    Contributors.contributors[0] = keedi - Keedi Kim - 김도형 (cpan: KEEDI) <keedi@cpan.org>
    Contributors.contributors[1] = carandraug - Carnë Draug (cpan: CDRAUG) <cdraug@cpan.org>

and/or weaver.ini:

    [Contributors]
    head = 2
    contributors = keedi - Keedi Kim - 김도형 (cpan: KEEDI) <keedi@cpan.org>
    contributors = carandraug - Carnë Draug (cpan: CDRAUG) <cdraug@cpan.org>

and/or in the source of individual files:

    # CONTRIBUTOR:  keedi - Keedi Kim - 김도형 (cpan: KEEDI) <keedi@cpan.org>
    # CONTRIBUTORS: carandraug - Carnë Draug (cpan: CDRAUG) <cdraug@cpan.org>

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

=for :list
* L<dagolden's 'How I'm using Dist::Zilla to give credit to contributors'|http://www.dagolden.com/index.php/1921/how-im-using-distzilla-to-give-credit-to-contributors/>
* L<Dist::Zilla::Plugin::ContributorsFromGit>
* L<Dist::Zilla::Stash::Contributors>
* L<Dist::Zilla::Plugin::Meta::Contributors>
* L<Dist::Zilla::Plugin::ContributorsFile>
* L<Dist::Zilla>
* L<Dist::Zilla::Stash::PodWeaver>
* L<Pod::Weaver>
* L<Pod::Weaver::Section::Authors>


=cut
