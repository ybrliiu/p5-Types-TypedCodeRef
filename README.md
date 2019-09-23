[![Build Status](https://circleci.com/gh/ybrliiu/p5-Types-TypedCodeRef.svg)](https://circleci.com/gh/ybrliiu/p5-Types-TypedCodeRef)
# NAME

Types::TypedCodeRef - Types for any typed anonymous subroutine.

# SYNOPSIS

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

# DESCRIPTION

Types::TypedCodeRef is ...

# LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ybrliiu <raian@reeshome.org>
