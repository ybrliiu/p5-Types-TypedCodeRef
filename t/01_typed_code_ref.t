use Test2::V0;
use Types::TypedCodeRef -types;
use Types::Standard qw( Int Str ArrayRef );
use Sub::WrapInType;

my $type = TypedCodeRef[ [Int, Int] => Int ];
ok $type->check(wrap_sub [Int, Int] => Int, sub { $_[0] + $_[1] });
ok !$type->check(wrap_sub [Int] => Int, sub { $_[0] + $_[1] });
ok !$type->check(0);
ok !$type->check([]);
ok !$type->check(sub {});
is $type->get_message([]), q{Reference [] did not pass type constraint "TypedCodeRef[ [Int, Int] => Int ]"};

my $type_named = TypedCodeRef[ +{ x => Int, y => Int } => Int ];
ok $type_named->check(wrap_sub +{ x => Int, y => Int } => Int, sub { $_[0] * $_[1] });
ok !$type_named->check(wrap_sub [Int] => Int, sub { $_[0] + $_[1] });
ok !$type_named->check(0);
ok !$type_named->check([]);
ok !$type_named->check(sub {});
is $type_named->get_message([]), q{Reference [] did not pass type constraint "TypedCodeRef[ { x => Int, y => Int } => Int ]"};

done_testing;
