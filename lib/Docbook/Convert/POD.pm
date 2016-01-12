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
package Docbook::Convert::POD;


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


#  Inherit Base functions (find_node etc.)
#
use base Docbook::Convert::Base;
use base Docbook::Convert::Common;
use base Docbook::Convert::POD::Util;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#  Make synonyms
#
&Docbook::Convert::Base::create_tag_synonym($POD_TAG_SYNONYM_HR);

#===================================================================================================


sub text {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return $text;
}

sub replaceable {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return $self->_italic($text);
}
    


1;

__END__
