# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Eval;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => qw(eval? eval@ eval$ eval% eval@? eval%? @ % $ p);
use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Run code in the current context';
use constant NEED_STACK  => 1;
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}
use strict;
use Devel::Trepan::Util;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [STRING]

Run code in the context of the current frame.

The value of the expression is stored into a global variable so it
may be used again easily. The name of the global variable is printed
next to the value.

If no string is given, we run the string from the current source code
about to be run. If the command ends ? (via an alias) and no string is
given we will the perform the translations:

   {if|elsif|unless} (expr) [{]  => expr
   {until|while} (expr) [{]      => expr
   return expr [;]               => expr
   my (expr) = val ;             => expr = val 
   my var = val ;                => var = val 
   given expr                    => expr
   sub fn(params)                => (params)
   var = expr                    => expr

The above is done via regular expression. No fancy parsing is done, say,
to look to see if expr is split across a line or whether var an assigment
might have multiple variables on the left-hand side.

Normally ${NAME} assumes you are typing a statement, not an expresion;
the result is a scalar value. However you can force the type of the result
by adding the appropriate sigil @, %, or \$.

Examples:

${NAME} 1+2 # 3
${NAME}\$ 3   # Same as above, but the return type is explicit
\$ 3       # Probably same as above if \$ alias is around
${NAME} \$^X  # Possibly /usr/bin/perl
${NAME}      # Run current source-code line
${NAME}?     # but strips off leading 'if', 'while', ..
          # from command 
${NAME}@ \@ARGV  # Make sure the result saved is an array rather than 
             # an array converted to a scalar.
@ \@ARG       # Same as above if \@ alias is around
use English  # Note this is a statement, not an expression
use English; # Same as above
${NAME}\$ use English # Error because this is not a valid expression 

See also 'set autoeval'. The command can help one predict future execution.
See 'set buffer trace' for showing what may have already been run.
HELP

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    if (!$prefix) {
	if (0 == index($self->{proc}{leading_str}, 'eval?')) {
	    Devel::Trepan::Util::extract_expression(
		$self->{proc}->current_source_text());
	} else {
	    $self->{proc}->current_source_text();
	}
    } else {
	$prefix;
    }
}

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $code_to_eval;
    my $cmd_name = $args->[0];
    if (1 == scalar @$args) {
	$code_to_eval  = $proc->current_source_text();
	if ('?' eq substr($cmd_name, -1)) {
	    $cmd_name = substr($cmd_name, 0, length($cmd_name)-1);
	    $code_to_eval = 
		Devel::Trepan::Util::extract_expression($code_to_eval);
	    $proc->msg("eval: ${code_to_eval}");
	    my @args = split /\s+/, $code_to_eval;
	    $cmd_name = $args[0];
	}
    } else {
	$code_to_eval = $proc->{cmd_argstr};
    }
    {
	my $return_type = parse_eval_suffix($cmd_name);
	$return_type = parse_eval_sigil($cmd_name) unless $return_type;
	my $opts = {return_type => $return_type};
	no warnings 'once';
	# FIXME: 4 below is a magic fixup constant, also found in
	# DB::finish.  Remove it.
	$proc->eval($code_to_eval, $opts, 4);
    }
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # my $arg_str = '1 + 2';
  # $proc->{cmd_argstr} = $arg_str;
  # print "eval ${arg_str} is: ${cmd.run([cmd.name, arg_str])}\n";
  # $arg_str = 'return "foo"';
  # # sub cmd.proc.current_source_text
  # # {
  # #   'return "foo"';
  # # }
  # # $proc->{cmd_argstr} = $arg_str;
  # # print "eval? ${arg_str} is: ", $cmd->run([$cmd->name + '?'])";
}
