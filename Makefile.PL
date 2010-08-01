use inc::Module::Install;
name 'AnyEvent-FSNotify';
all_from 'lib/AnyEvent/FSNotify.pm';
readme_from 'lib/AnyEvent/FSNotify.pm';
githubmeta;

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
