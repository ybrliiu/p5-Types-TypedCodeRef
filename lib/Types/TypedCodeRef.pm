package Types::TypedCodeRef;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.01";

use Type::Library (
  -base,
  -declare => qw( TypedCodeRef ),
);

use overload ();
use Carp ();
use Type::Tiny ();
use Type::Params qw( compile compile_named multisig );
use Types::Standard qw( ClassName ArrayRef HashRef CodeRef InstanceOf );
use Scalar::Util;
use Sub::Anon::Typed ();
use Sub::Meta;
use Sub::Meta::Param;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;

sub create_type {
  state $check = compile( ClassName, ArrayRef[CodeRef] );
  my ($class, $sub_meta_finders) = $check->(@_);

  Type::Tiny->new(
    name                 => 'TypedCodeRef',
    name_generator       => $class->_build_name_generator,
    constraint_generator => $class->_build_constraint_generator($sub_meta_finders),
  );
}

sub _build_name_generator {
  sub {
    my ($type_name, @type_parameters) = @_;
    if ( @type_parameters == 2 ) {
      my $parameters = $type_parameters[0];
      if ( ref $parameters eq 'ARRAY' ) {
        $type_name . '[ [' . join(', ', @$parameters) . '] => ' . $type_parameters[1] . ' ]';
      }
      else {
        $type_name . '[ { '
          . join( ', ', map { "$_ => $parameters->{$_}" } sort keys %$parameters )
          . ' } => '
          . $type_parameters[1] . ' ]';
      }
    }
    else {
        "${type_name}[$type_parameters[0]]";
    }
  };
}

sub _build_constraint_generator {
  state $check = compile( ClassName, ArrayRef[CodeRef] );
  my (undef, $sub_meta_finders) = $check->(@_);

  sub {
    my $constraints_sub_meta = do {
      if ( @_ == 0 ) {
        unknown_sub_meta();
      }
      elsif ( @_ == 1 ) {
        state $validator = compile( InstanceOf( ['Sub::Meta'] ) );
        my ($constraints_sub_meta) = $validator->(@_);
        $constraints_sub_meta;
      }
      elsif ( @_ == 2 ) {
        state $validator = do {
          my $TypeConstraint = Types::Standard::HasMethods( [qw( check get_message )] );
          multisig(
            compile( ArrayRef( [$TypeConstraint] ), $TypeConstraint ),
            compile( HashRef(  [$TypeConstraint] ), $TypeConstraint ),
          );
        };
        my ($params, $returns) = $validator->(@_);

        Sub::Meta->new(
          parameters => do {
            my @meta_params = ref $params eq 'ARRAY'
              ? map { Sub::Meta::Param->new($_) } @$params
              : map {
                  Sub::Meta::Param->new({
                    name  => $_,
                    type  => $params->{$_},
                    named => 1,
                  });
                } sort keys %$params;
            Sub::Meta::Parameters->new(args => \@meta_params);
          },
          returns => Sub::Meta::Returns->new(
            scalar => $returns,
            list   => $returns,
            void   => $returns,
          ),
        );
      }
      else {
        Carp::croak 'Too many arguments.';
      }
    };

    sub {
        my $typed_code_ref = shift;
        return !!0 unless _is_callable($typed_code_ref);

        my $maybe_sub_meta = find_sub_meta($sub_meta_finders, $typed_code_ref);
        $constraints_sub_meta->is_same_interface($maybe_sub_meta // unknown_sub_meta());
    };
  }
}

sub unknown_sub_meta {
  # TODO: サブルーチンの引数の型と返り値の型が不明な場合これで良いのか
  Sub::Meta->new(
    parameters => Sub::Meta::Parameters->new(
      args   => [],
      slurpy => 1,
    ),
    returns => Sub::Meta::Returns->new(),
  );
}

sub _is_callable {
  my $callable = shift;
  my $reftype = Scalar::Util::reftype($callable);
  ( defined $reftype && $reftype eq 'CODE' ) || overload::Overloaded($callable);
}

sub find_sub_meta {
  my ($sub_meta_finders, $typed_code_ref) = @_;
  for my $finder (@$sub_meta_finders) {
    my $meta = $finder->($typed_code_ref);
    return $meta if defined $meta;
  }
  return;
}

__PACKAGE__->add_type( __PACKAGE__->create_type([\&get_sub_meta_from_sub_anon_typed]) );

sub get_sub_meta_from_sub_anon_typed {
  my $typed_code_ref = shift;
  if ( Scalar::Util::blessed($typed_code_ref) && $typed_code_ref->isa('Sub::Anon::Typed') ) {
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
    use Sub::Anon::Typed qw( anon );
    
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

