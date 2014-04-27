package Perinci::Sub::Normalize;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       normalize_function_metadata
               );

use Sah::Schema::Rinci;
my $sch = $Sah::Schema::Rinci::SCHEMAS{rinci_function}
    or die "BUG: Rinci schema structure changed (1)";
my $sch_proplist = $sch->[1]{_prop}
    or die "BUG: Rinci schema structure changed (2)";

our $VERSION = '0.01'; # VERSION
our $DATE = '2014-04-28'; # DATE

sub _normalize{
    my ($meta, $opts, $proplist, $nmeta, $prefix) = @_;

    my $opt_aup = $opts->{allow_unknown_properties};
    my $opt_nss = $opts->{normalize_sah_schemas};
    my $opt_rip = $opts->{_remove_internal_properties};

    for my $k (keys %$meta) {
        next if $k =~ /\./; # ignore attrs for now
        my $prop = $k;
        next if $opt_rip && $prop =~ /\A_/;
        my $prop_proplist = $proplist->{$prop};
        die "Unknown property '$prefix/$prop'"
            if !$opt_aup && !$prop_proplist;
        if ($prop_proplist && $prop_proplist->{_prop}) {
            die "Property '$prefix/$prop' must be a hash"
                unless ref($meta->{$k}) eq 'HASH';
            $nmeta->{$k} = {};
            _normalize(
                $meta->{$k},
                $opts,
                $prop_proplist->{_prop},
                $nmeta->{$k},
                "$prefix/$prop",
            );
        } elsif ($prop_proplist && $prop_proplist->{_elem_prop}) {
            die "Property '$prefix/$prop' must be an array"
                unless ref($meta->{$k}) eq 'ARRAY';
            $nmeta->{$k} = [];
            my $i = 0;
            for (@{ $meta->{$k} }) {
                my $href = {};
                if (ref($_) eq 'HASH') {
                    _normalize(
                        $_,
                        $opts,
                        $prop_proplist->{_elem_prop},
                        $href,
                        "$prefix/$prop/$i",
                    );
                    push @{ $nmeta->{$k} }, $href;
                } else {
                    push @{ $nmeta->{$k} }, $_;
                }
                $i++;
            }
        } elsif ($prop_proplist && $prop_proplist->{_value_prop}) {
            die "Property '$prefix/$prop' must be a hash"
                unless ref($meta->{$k}) eq 'HASH';
            $nmeta->{$k} = {};
            for (keys %{ $meta->{$k} }) {
                $nmeta->{$k}{$_} = {};
                die "Property '$prefix/$prop/$_' must be a hash"
                    unless ref($meta->{$k}{$_}) eq 'HASH';
                _normalize(
                    $meta->{$k}{$_},
                    $opts,
                    $prop_proplist->{_value_prop},
                    $nmeta->{$k}{$_},
                    "$prefix/$prop/$_",
                );
            }
        } else {
            if ($k eq 'schema' && $opt_nss) { # XXX currently hardcoded
                require Data::Sah;
                $nmeta->{$k} = Data::Sah::normalize_schema($meta->{$k});
            } else {
                $nmeta->{$k} = $meta->{$k};
            }
        }
    }

    $nmeta;
}

sub normalize_function_metadata {
    my ($meta, $opts) = @_;

    $opts //= {};

    unless (($meta->{v} // 1.0) == 1.1) {
        die "Can only normalize Rinci 1.1 metadata";
    }

    $opts->{allow_unknown_properties}    //= 0;
    $opts->{normalize_sah_schemas}       //= 1;
    $opts->{_remove_internal_properties} //= 0;

    _normalize($meta, $opts, $sch_proplist, {}, '');
}

1;
# ABSTRACT: Normalize Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Normalize - Normalize Rinci metadata

=head1 VERSION

This document describes version 0.01 of module Perinci::Sub::Normalize (in distribution Perinci-Sub-Normalize), released on 2014-04-28.

=head1 SYNOPSIS

 use Perinci::Sub::Normalize qw(normalize_function_metadata);

 my $nmeta = normalize_function_metadata($meta);

=head1 FUNCTIONS

=head2 normalize_function_metadata($meta, \%opts) => HASH

Normalize and check Rinci function metadata C<$meta>. Return normalized
metadata, which is a shallow copy of C<$meta>. Die on error.

Available options:

=over

=item * allow_unknown_properties => BOOL (default: 0)

=item * normalize_sah_schemas => BOOL (default: 1)

=back

=head1 SEE ALSO

L<Rinci::function>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Normalize>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Sub-Normalize>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Normalize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
