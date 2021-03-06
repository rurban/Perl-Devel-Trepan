#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::Util" );

BEGIN {
use_ok( 'Devel::Trepan::Util' );
}

import Devel::Trepan::Util;

note 'Test hash_merge';
my $default_config = {a => 1, b => 'c', term_adjust=>0};
my $config = {};
hash_merge $config, $default_config;
is($config->{a}, $default_config->{a},
    "Should pick up default_config value");

$config = {
    term_adjust   => 1,
    bogus         => 'yep'
};
is($config->{term_adjust}, 1,
    "Should pick up supplied value over default");
is($config->{bogus}, 'yep',
    "Should pick up supplied value");


note 'Test safe_repr';
my $string = 'The time has come to talk of many things.';
is(safe_repr($string, 50), $string);
is(safe_repr($string, 17), 'The time...  things.');

note 'Test uniq_abbrev';

my @list = qw(disassemble disable distance up);
for my $pair 
    (
     ['dis', 'dis'],
     ['disas', 'disassemble'],
     ['u', 'up'],
     ['upper', 'upper'],
     ['foo', 'foo']) {
	my ($name, $expect) = @$pair;
	is(uniq_abbrev(\@list, $name), $expect);
}

note 'Test extract expression';
for my $pair (
    ['if (condition("if"))', 'condition("if")'], 
    ['if (condition("if")) {', 'condition("if")'], 
    ['if(condition("if")){', 'condition("if")'], 
    ['until (until_termination)', 'until_termination'],
    ['until (until_termination){', 'until_termination'],
    ['return return_value', 'return_value'],
    ['return return_value;', 'return_value'],
    ['nothing to be done', 'nothing to be done'], 
    ['my ($a,$b) = (5,6);', '($a,$b) = (5,6)'],
    ) {
    my ($stmt, $expect) = @$pair;
    is(extract_expression($stmt), $expect);
}

note 'Test parse_eval_suffix';
for my $pair (
    ['eval',  ''],
    ['eval$', '$'],
    ['eval%', '%'],
    ['eval@', '@'],
    ['evaluate%', '%'],
    ['none', '']) {
    is(parse_eval_suffix($pair->[0]), parse_eval_suffix($pair->[1]),
       sprintf("parse_eval_suffix(%s) => '%s' should be '%s'", 
	       $pair->[0], parse_eval_suffix($pair->[0]), $pair->[1]));
}


for my $pair 
    ([__FILE__, ''],
     ['bogus', 1]) {
	my ($name, $expect) = @$pair;
	my $result = Devel::Trepan::Util::invalid_filename($name);
	is(!!$result, $expect, $result || "$name should exist");
};

for my $pair 
    (['yes', 1],
     ['no',  1],
     ['Y',   1],
     ['NO',  1],
     ['nein', 1],
     ['nien', ''],
     ['huh?', '']) {
	my ($resp, $expect) = @$pair;
	my $result = Devel::Trepan::Util::YN($resp);
	is($result, $expect, $resp);
}

for my $pair 
    ([1,      'Yes'],
     [0,      'No'],
     ['',     'No'],
     ['Foo',  'Yes'],
     [undef,  'No']) {
	my ($resp, $expect) = @$pair;
	my $result = Devel::Trepan::Util::bool2YN($resp);
	is($result, $expect, 'bool2YN of ' . ($resp || 'undef'));
}
