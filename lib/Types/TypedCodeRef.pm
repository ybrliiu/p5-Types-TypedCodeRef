package Types::TypedCodeRef;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.01";

use Type::Library (
  -base,
  -declare => qw( TypedCodeRef ),
);

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
    parent               => CodeRef,
    constraint_generator => sub {
      my $parent = CodeRef;
      return $parent unless @_;

      state $validator = do {
        my $TypeConstraint = Types::Standard::HasMethods( [qw( check get_message )] );
        multisig(
          compile( ArrayRef( [$TypeConstraint] ), $TypeConstraint ),
          compile( HashRef(  [$TypeConstraint] ), $TypeConstraint ),
          compile( InstanceOf( ['Sub::Meta'] ) ),
        );
      };

      my $constraint_meta = do {
        if ( @_ == 2 ) {
          my ( $params, $returns ) = $validator->(@_);
          Sub::Meta->new(
            parameters => do {
              if ( ref $params eq 'ARRAY' ) {
                my @meta_params = map { Sub::Meta::Param->new($_) } @$params;
                Sub::Meta::Parameters->new( args => \@meta_params );
              }
              else {
                my @meta_params = map {
                  Sub::Meta::Param->new({
                    name  => $_,
                    type  => $params->{$_},
                    named => 1,
                  });
                } keys %$params;
              }
            },
            returns => Sub::Meta::Returns->new(
              scalar => $returns,
              list   => $returns,
              void   => $returns,
            ),
          );
        }
        else {
          my ($constraint_meta) = $validator->(@_);
          $constraint_meta;
        }
      };

      return $parent->create_child_type(
        display_name => 'TypedCodeRef',
        message      => sub {
          my $invalid_value = shift;
          $parent->get_message($invalid_value);
        },
        constraint => sub {
          my $typed_code_ref = shift;
          return !!0 if ref $typed_code_ref ne 'CODE';

          my $maybe_meta = find_sub_meta($sub_meta_finders, $typed_code_ref);
          my $meta = do {
            if ( !defined $maybe_meta ) {
              # TODO: 渡されたAnonymous Subroutineの型が不明の場合の扱いがこれで良いのかは要検討
              Sub::Meta->new(
                parameters => Sub::Meta::Parameters->new(
                  args   => [],
                  slurpy => 1,
                ),
                returns => Sub::Meta::Returns->new(),
              );
            }
            else {
              $maybe_meta;
            }
          };
          $constraint_meta->is_same_interface($meta);
        },
      );
    },
  );
}

sub find_sub_meta {
  my ($sub_meta_finders, $typed_code_ref) = @_;
  for my $finder (@$sub_meta_finders) {
    my $meta = $finder->($typed_code_ref);
    return $meta if defined $meta;
  }
  return;
}

sub get_sub_meta_from_sub_anon_typed {
  my $typed_code_ref = shift;
  if ( my $info = Sub::Anon::Typed::get_info($typed_code_ref) ) {
    my @parameters = do {
      if ( ref $info->{params} eq 'ARRAY' ) {
        map { Sub::Meta::Param->new($_) } @{ $info->{params} };
      }
      else {
        map {
          Sub::Meta::Param->new({
            name  => $_,
            type  => $info->{params}{$_},
            named => 1,
          });
        } keys %{ $info->{params} };
      }
    };
    Sub::Meta->new(
      parameters => Sub::Meta::Parameters->new(args => \@parameters),
      returns    => Sub::Meta::Returns->new(
        scalar => $info->{isa},
        list   => $info->{isa},
        void   => $info->{isa},
      ),
    );
  }
}

__PACKAGE__->add_type( __PACKAGE__->create_type([\&get_sub_meta_from_sub_anon_typed]) );

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

