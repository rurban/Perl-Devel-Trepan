# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockbcpan.org>

use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Watch;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
our $CMD = "info watch";
our $HELP         = <<"EOH";
${CMD} [WATCHPOINT1 WATCHPOINT2 ...]

List watch information. If watchpoints are specified, only information
about them is shown. If no watchpoints are specified, show information
about all watchpoints.
EOH

our $MIN_ABBREV = length('wa');
our $SHORT_HELP = "Show watchpoint information";

# sub complete($$) {
# {
#     my ($self, $prefix) = @_;
#     my @cmds = sort keys %{$proc->{macros}};
#     Trepan::Complete.complete_token(@cmds, $prefix);
# }

# sub save_command($)
# {
#     my $self = shift;
#     my $proc = $self->{proc};
#     my $wpmgr = $proc->{dbgr}{watch};
#     my @res = ();
#     for my $bp ($wpmgr->list) {
# 	push @res, "watch ${loc}";
#     }
#     return @res;
# }

sub wpprint($$;$) 
{
    my ($self, $wp, $verbose) = @_;
    my $proc = $self->{proc};
    my $disp = $wp->enabled ? 'y  '   : 'n  ';

    my $mess = sprintf('%-4dwatchpoint %s %s', $wp->id, $disp, $wp->expr);
    $proc->msg($mess);

    if ($wp->hits > 0) {
    	my $ss = ($wp->hits > 1) ? 's' : '';
    	my $msg = sprintf("\twatchpoint already hit %d time%s",
    			  $wp->hits, $ss);
    	$proc->msg($msg);
    }
}

sub run($$) {
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $watchmgr = $proc->{dbgr}{watch};
    my @args = @$args;
    if (scalar(@args) > 2) {
    	shift @args; shift @args;
    	for my $wp_name (@args) {
    	    if ($watchmgr->find_by_name({$wp_name})) {
		$self->wpprint($wp);
    	    } else {
    		$proc->msg("$wp_name is not a defined watchpoint");
    	    }
    	}
    } else {
	my @watchpoints = $watchmgr->list;
	if (scalar @watchpoints == 0) {
	    $proc->msg("No watch expressions defined.");
	} else {
	    # There's at least one
	    $proc->section("Num Type       Enb Expression");
	    for my $wp (@watchpoints) { 
		$self->wpprint($wp);
	    }
	}
   }
}

unless(caller) {
    # Demo it.
    # require_relative '../../mock';
    # my $cmd = MockDebugger::sub_setup(__PACKAGE__);
    # my $cmd->run($cmd->{prefix} + %w(u foo));
}

1;
