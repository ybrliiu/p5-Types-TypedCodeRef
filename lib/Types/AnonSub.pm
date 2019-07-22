package Types::AnonSub;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.01";

use Type::Library (
  -base,
  -declare => qw( TypedCodeRef ),
);

use Carp ();
use Type::Params ();
use Types::Standard qw( CodeRef );
use Scalar::Util;
use Sub::TypedAnon ();
use Sub::Meta;
use Sub::Meta::Param;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;

__PACKAGE__->add_type({
  name                 => 'TypedCodeRef',
  parent               => CodeRef,
  constraint_generator => sub {
    # TODO: type constraint はこの判定方法でいいのか?
    state $types_constraint = Types::Standard::HasMethods([qw( check get_message )]);
    state $checker          = Type::Params::compile(
      # TODO: named parameters も受け付けるようにする
      # TODO: Sub::Meta::Parameters を受け付けれるようにするかどうか検討する
      Types::Standard::ArrayRef([$types_constraint]), 
      # TODO: Sub::Meta::Returns を受け付けれるようにするかどうか検討する
      $types_constraint
    );
    my ($params, $return_type) = $checker->(@_);

    my $constraint_meta = do {
      my @meta_params = map { Sub::Meta::Param->new($_) } @$params;
      Sub::Meta->new(
        parameters => Sub::Meta::Parameters->new(args => \@meta_params),
        returns    => Sub::Meta::Returns->new(
          scalar => $return_type,
          list   => $return_type,
        ),
      );
    };

    # TODO: CodeRefではなくTypeConstraint返した方がちゃんと型名つけれて良さそう
    sub {
      my $typed_code_ref = shift;
      return !!0 if ref $typed_code_ref ne 'CODE';
      my $meta = get_meta($typed_code_ref);
      $constraint_meta->is_same_interface($meta);
    };
  },
});

sub get_meta {
  my $typed_code_ref = shift;
  # TODO: 開放閉鎖原則に沿う形にする
  my $meta = do {
    if ( my $info = Sub::TypedAnon::get_info($typed_code_ref) ) {
      # TODO: $info->{params} がnamedな場合も考慮する
      my @parameters = map { Sub::Meta::Param->new($_) } @{ $info->{params} };
      Sub::Meta->new(
        parameters => Sub::Meta::Parameters->new(args => \@parameters),
        returns    => Sub::Meta::Returns->new(
          scalar => $info->{isa},
          list   => $info->{isa},
        ),
      );
    }
    else {
      # TODO: 渡されたAnonymous Subroutineの型が不明の場合の扱いがこれで良いのかは要検討
      Sub::Meta->new(
        parameters => Sub::Meta::Parameters->new(
          args   => [],
          slurpy => 1,
        ),
        returns => Sub::Meta::Returns->new(),
      );
    }
  };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf-8

=head1 NAME

Types::AnonSub - Types for any typed anonymous subroutine.

=head1 SYNOPSIS

    use Test2::V0;
    use Types::AnonSub -types;
    use Types::Standard qw( Int Str );
    use Sub::TypedAnon;
    
    my $type = TypedCodeRef[ [Int, Int] => Int ];
    ok $type->check(anon [Int, Int] => Int, sub { $_[0] + $_[1] });
    ok !$type->check(0);
    ok !$type->check([]);
    ok !$type->check(sub {});
    
    done_testing;

=head1 DESCRIPTION

Types::AnonSub is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ybrliiu E<lt>raian@reeshome.orgE<gt>

=cut

