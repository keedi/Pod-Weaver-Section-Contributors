package Pod::Weaver::Section::ReplaceContributors;
use Moose;
extends 'Pod::Weaver::Section::Contributors';
with 'Pod::Weaver::Role::SectionReplacer';
# ABSTRACT: replaces a section listing contributors

sub mvp_multivalue_args { qw( contributors ) }
sub default_section_name { 'CONTRIBUTORS' }
# sub default_section_aliases { [ 'CONTRIBUTOR' ] }

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

This section plugin provides the same behaviour as
Pod::Weaver::Section::Contributors but with the
Pod::Weaver::Role::SectionReplacer role applied.

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
