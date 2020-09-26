package Types::TypedCodeRef::Factory;
use 5.010001;
use strict;
use warnings;
use utf8;
use Moo;
use overload ();
use Carp ();
use Type::Tiny ();
use Type::Params qw( compile compile_named multisig );
use Types::Standard qw( Str ArrayRef HashRef CodeRef InstanceOf );
use Scalar::Util;
use Sub::WrapInType;
use Sub::Meta;
use Sub::Meta::Param;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;

has name => (
  is      => 'ro',
  isa     => Str,
  default => 'TypedCodeRef',
);

has name_generator => (
  is      => 'ro',
  isa     => CodeRef,
  builder => '_build_name_generator',
);

has constraint_generator => (
  is      => 'ro',
  isa     => CodeRef,
  lazy    => 1,
  builder => '_build_constraint_generator',
);

has sub_meta_finders => (
  is       => 'ro',
  isa      => ArrayRef[CodeRef],
  required => 1,
);

sub _build_name_generator {
  sub {
    my ($type_name, @type_parameters) = @_;
    $type_name . do {
      if ( @type_parameters == 2 ) {
        my $parameters = $type_parameters[0];
        if ( ref $parameters eq 'ARRAY' ) {
          '[ [' . join(', ', @$parameters) . '] => ' . $type_parameters[1] . ' ]';
        }
        else {
          '[ { '
            . join( ', ', map { "$_ => $parameters->{$_}" } sort keys %$parameters )
            . ' } => '
            . $type_parameters[1] . ' ]';
        }
      }
      else {
        "[$type_parameters[0]]";
      }
    };
  };
}

sub _build_constraint_generator {
  my $self = shift;

  sub {
    my $constraints_sub_meta = do {
      if ( @_ == 0 ) {
        create_unknown_sub_meta();
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

        my $maybe_sub_meta = $self->find_sub_meta($typed_code_ref);
        $constraints_sub_meta->is_same_interface($maybe_sub_meta // create_unknown_sub_meta());
    };
  };
}

sub _is_callable {
  my $callable = shift;
  my $reftype = Scalar::Util::reftype($callable);
  ( defined $reftype && $reftype eq 'CODE' ) || overload::Overloaded($callable);
}

sub find_sub_meta {
  my ($self, $typed_code_ref) = @_;
  for my $finder (@{ $self->sub_meta_finders }) {
    my $meta = $finder->($typed_code_ref);
    return $meta if defined $meta;
  }
  return;
}

sub create_unknown_sub_meta {
  # TODO: サブルーチンの引数の型と返り値の型が不明な場合これで良いのか
  Sub::Meta->new(
    parameters => Sub::Meta::Parameters->new(
      args   => [],
      slurpy => 1,
    ),
    returns => Sub::Meta::Returns->new(),
  );
}

sub create {
  my $self = shift;
  Type::Tiny->new(
    name                 => $self->name,
    name_generator       => $self->name_generator,
    constraint_generator => $self->constraint_generator,
  );
}

1;
