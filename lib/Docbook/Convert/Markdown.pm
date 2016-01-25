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
package Docbook::Convert::Markdown;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Docbook::Convert::Constant;
use Data::Dumper;
use CGI;    # for HTMLescape


#  Inherit Base functions (find_node etc.)
#
use base Docbook::Convert::Base;
use base Docbook::Convert::Common;
use base Docbook::Convert::Markdown::Util;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.005';


#  Make synonyms
#
&Docbook::Convert::Base::create_tag_synonym($MD_TAG_SYNONYM_HR);


#===================================================================================================


sub text {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    unless ($self->_dont_escape($data_ar)) {
        $text=$self->_escape($text);
    }
    return $text;
}


sub _dont_escape {

    my ($self, $data_ar)=@_;
    if ($self->find_parent($data_ar, $MD_DONT_ESCAPE_AR)) {
        return 1;
    }
    else {
        return undef;
    }

}


sub _escape {

    my ($self, $text)=@_;

    #  Escape markdown characters
    $text=~s/\s+([*_`\\{}\[\]\(\)#+-\.\!]+)/ \\$1/g;

    #  And HTML
    $text=CGI::escapeHTML($text);
    return $text;

}

1;
__END__
