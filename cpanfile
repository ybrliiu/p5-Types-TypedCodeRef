requires 'perl', '5.010001';
requires 'Carp';
requires 'Scalar::Util';
requires 'Sub::Meta';
requires 'Type::Tiny', '>= 1.010004';
requires 'Sub::WrapInType', '>= 0.03';
requires 'Moo';
requires 'namespace::autoclean';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::Suite';
};

