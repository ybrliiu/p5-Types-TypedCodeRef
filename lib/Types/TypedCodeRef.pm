package Types::TypedCodeRef;
use 5.010001;
use strict;
use warnings;
use utf8;

our $VERSION = "0.01";

use Type::Library (
  -base,
  -declare => qw( TypedCodeRef ),
);

use Types::TypedCodeRef::Factory;

{
  my $factory =
    Types::TypedCodeRef::Factory->new(sub_meta_finders => [\&get_sub_meta_from_sub_anon_typed]);
  __PACKAGE__->add_type($factory->create());
}

sub get_sub_meta_from_sub_anon_typed {
  my $typed_code_ref = shift;
  if ( Scalar::Util::blessed($typed_code_ref) && $typed_code_ref->isa('AnonSub::Typed') ) {
    my @parameters = do {
      if ( ref $typed_code_ref->params eq 'ARRAY' ) {
        map { Sub::Meta::Param->new($_) } @{ $typed_code_ref->params };
      }
      else {
        map {
          Sub::Meta::Param->new({
            name  => $_,
            type  => $typed_code_ref->params->{$_},
            named => 1,
          });
        } sort keys %{ $typed_code_ref->params };
      }
    };
    return Sub::Meta->new(
      parameters => Sub::Meta::Parameters->new(args => \@parameters),
      returns    => Sub::Meta::Returns->new(
        scalar => $typed_code_ref->returns,
        list   => $typed_code_ref->returns,
        void   => $typed_code_ref->returns,
      ),
    );
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf-8

=head1 NAME

Types::TypedCodeRef - Types for any typed anonymous subroutine.

=head1 SYNOPSIS

    use Test2::V0;
    use Types::TypedCodeRef -types;
    use Types::Standard qw( Int Str );
    use AnonSub::Typed qw( anon );
    
    my $type = TypedCodeRef[ [Int, Int] => Int ];
    ok $type->check(anon [Int, Int] => Int, sub { $_[0] + $_[1] });
    ok !$type->check(0);
    ok !$type->check([]);
    ok !$type->check(sub {});
    
    done_testing;

=head1 DESCRIPTION

Types::TypedCodeRef is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ybrliiu E<lt>raian@reeshome.orgE<gt>

=cut

