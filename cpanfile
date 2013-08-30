requires 'perl', '5.008005';

requires 'IO::Socket::IP';

on test => sub {
    requires 'Test::More', '0.88';
};
