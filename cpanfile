requires 'perl', '5.010001';
requires 'Carp';
requires 'Scalar::Util';
requires 'Sub::Meta';
requires 'Type::Tiny';
requires 'AnonSub::Typed', url => 'git@github.com:ybrliiu/p5-AnonSub-Typed.git';
requires 'Moo';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

