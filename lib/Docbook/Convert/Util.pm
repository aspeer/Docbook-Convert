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
@EXPORT=qw(err msg arg);



#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#  All done, init finished
#
1;


#===================================================================================================


sub err {


    #  Quit on errors
    #
    my $msg=shift();
    croak &fmt("*error*\n\n" . ucfirst($msg), @_);

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
    CORE::print &fmt(@_), "\n";

}


