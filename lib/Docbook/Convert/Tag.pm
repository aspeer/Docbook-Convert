#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2017 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
package Docbook::Convert::Tag;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
#use Docbook::Convert::Markdown::Util;
use Docbook::Convert::Constant;
use Data::Dumper;


#  Inherit Base functions (find_node etc.)
#
use base Docbook::Convert::Base;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.015';


#  Make synonyms
#
#&create_tag_synonym;


#  All done, init finished
#
1;


#===================================================================================================


sub command {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    return $self->_code($text);

    #return &_code();
}


sub para {

    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    $text=~s/ +/ /g;
    return $text;

}

