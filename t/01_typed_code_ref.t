use Test2::V0;
use Types::TypedCodeRef -types;
use Types::Standard qw( Int Str );
use Sub::Anon::Typed;

$SIG{__DIE__} = \&Carp::confess;

my $type = TypedCodeRef[ [Int, Int] => Int ];
ok $type->check(anon [Int, Int] => Int, sub { $_[0] + $_[1] });
ok !$type->check(0);
ok !$type->check([]);
ok !$type->check(sub {});
diag $type->get_message([]);

done_testing;
