# NAME

Types::AnonSub - Types for any typed anonymous subroutine.

# SYNOPSIS

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

# DESCRIPTION

Types::AnonSub is ...

# LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ybrliiu <raian@reeshome.org>
