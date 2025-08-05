requires 'perl', '5.010001';
requires 'Carp';
requires 'Scalar::Util';
requires 'Sub::Meta', '0.09';
requires 'Type::Tiny', '1.010004';
requires 'Sub::WrapInType', '0.05';
requires 'Moo', '2.004004';
requires 'namespace::autoclean', '0.29';

on 'configure' => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::Suite', '0.000138';
};

