requires 'perl', '5.010001';
requires 'Carp';
requires 'Scalar::Util';
requires 'Sub::Meta';
requires 'Type::Tiny';
requires 'Sub::TypedAnon';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

