use Test2::V0;
use Types::TypedCodeRef -types;
use Types::Standard qw( Int Str ArrayRef );
use Sub::Anon::Typed;

my $type = TypedCodeRef[ [Int, Int] => Int ];
ok $type->check(anon [Int, Int] => Int, sub { $_[0] + $_[1] });
ok !$type->check(anon [Int] => Int, sub { $_[0] + $_[1] });
ok !$type->check(0);
ok !$type->check([]);
ok !$type->check(sub {});
diag $type->get_message([]);

my $type_named = TypedCodeRef[ +{ x => Int, y => Int } => Int ];
ok $type_named->check(anon +{ x => Int, y => Int } => Int, sub { $_[0] * $_[1] });
ok !$type_named->check(anon [Int] => Int, sub { $_[0] + $_[1] });
ok !$type_named->check(0);
ok !$type_named->check([]);
ok !$type_named->check(sub {});
diag $type_named->get_message([]);

done_testing;
