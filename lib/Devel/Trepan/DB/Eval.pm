# Eval part of Perl's Core DB.pm library and perl5db.pl with modification.

use lib '../..';

package DB;
use warnings; use strict;
use English;
use feature 'switch';
use vars qw($eval_result @eval_result %eval_result
            $eval_str $eval_opts $event $return_type );

BEGIN {
    # When we want to evaluate a string in the context of the running
    # program we use these:
    $eval_str = '';             # The string to eval
    $eval_opts = {};            # Options controlling how we want the
				# eval to take place
    $DB::eval_result = undef;   # Place for result if scalar;
    @DB::eval_result = ();      # place for result if array
    %DB::eval_result = ();      # place for result if hash.
}    

sub eval_with_return {
    my ($usrctxt, @saved) = @_;
    no strict;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;
    use strict;
    given ($eval_opts->{return_type}) {
	when ('$') {
	    eval "$usrctxt \$DB::eval_result=$eval_str";
	    $eval_result = eval "$usrctxt $eval_str";
	}
	when ('@') {
	    eval "$usrctxt \@DB::eval_result=$eval_str";
	}
	when ('%') {
	    eval "$usrctxt \%DB::eval_result=$eval_str";
	} 
	default {
	    $eval_result = eval "$usrctxt $eval_str";
	}
    }

    my $EVAL_ERROR_SAVE = $EVAL_ERROR;
    eval "$usrctxt &DB::save";
    if ($EVAL_ERROR_SAVE) {
	_warnall($EVAL_ERROR_SAVE);
	$eval_str = '';
	return undef;
    } else {
	given ($eval_opts->{return_type}) {
	    when ('$') {
		return $eval_result;
	    }
	    when ('$') {
		return @eval_result;
	    }
	    when ('%') {
		return %eval_result;
	    } 
	    default {
		return $eval_result;
	    }
	}
    }
}

1;
