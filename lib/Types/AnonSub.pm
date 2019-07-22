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
    state $types_constraint = Types::Standard::HasMethods([qw( check get_message )]);
    state $checker          = Type::Params::compile(
      Types::Standard::ArrayRef([$types_constraint]),
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
  my $meta = do {
    if ( my $info = Sub::TypedAnon::get_info($typed_code_ref) ) {
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

Types::AnonSub - It's new $module

=head1 SYNOPSIS

    use Types::AnonSub;

=head1 DESCRIPTION

Types::AnonSub is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ybrliiu E<lt>raian@reeshome.orgE<gt>

=cut

