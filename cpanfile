requires 'perl', '5.010001';
requires 'Carp';
requires 'Scalar::Util';
requires 'Sub::Meta';
requires 'Type::Tiny';
requires 'Sub::Anon::Typed', git => 'git@github.com:ybrliiu/p5-Sub-Anon-Typed.git';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

