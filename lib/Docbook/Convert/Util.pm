#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2016 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

#
#
package Docbook::Convert::Util;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA @EXPORT);
use warnings;
no warnings qw(uninitialized);


#  Constants
#
use Docbook::Convert::Constant;


#  External modules
#
require Exporter;
use Carp;


#  Export functions
#
@ISA=qw(Exporter);
@EXPORT=qw(err msg dump_ar);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.006';


#  All done, init finished
#
1;


#===================================================================================================


sub dump_ar {

    my $data_ar=shift();
    my $cr=sub {
        my ($cr, $data_ar)=@_;
        if ($data_ar->[$NODE_IX] eq 'text') {
            foreach my $ix (0..@{$data_ar->[$PRNT_IX][$CHLD_IX]}) {
                if ($data_ar->[$PRNT_IX][$CHLD_IX][$ix] eq $data_ar) {
                    $data_ar->[$PRNT_IX][$CHLD_IX][$ix]=$data_ar->[$CHLD_IX][0];
                }
            }
        }
        foreach my $ar (@{$data_ar->[$CHLD_IX]}) {
            if (ref($ar)) {
                $cr->($cr, $ar);
            }
            $data_ar->[$PRNT_IX]=$data_ar->[$PRNT_IX][$NODE_IX];
        }

    };
    $cr->($cr, $data_ar);
    return $data_ar;

}


sub err {


    #  Quit on errors
    #
    my $msg=shift();
    my $err=&fmt("*error*\n\n" . ucfirst($msg), @_);
    return $ERR_BACKTRACE ? confess $err : croak $err;

}


sub fmt {


    #  Format message nicely. Always called by err or msg so caller=2
    #
    my $message=sprintf(shift(), @_);
    chomp($message);
    my $caller=(split(/:/, (caller(2))[3]))[-1];
    $caller=~s/^_?!(_)//;
    my $format=' @<<<<<<<<<<<<<<<<<<<<<< @<';
    formline $format, $caller . ':', undef;
    $message=$^A . $message; $^A=undef;
    return $message;

}


sub msg {


    #  Print message
    #
    CORE::print &fmt(@_), "\n" if $VERBOSE;

}
