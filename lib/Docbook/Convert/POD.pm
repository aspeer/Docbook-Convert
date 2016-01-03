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
#use Docbook::Convert::POD::Util;
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
&create_tag_synonym;

#===================================================================================================


sub new {

    #  New instance
    #
    my $class=shift();
    return bless((my $self={}), ref($class) || $class);

}


sub create_tag_synonym {

    #  Create tag equivalents
    #
    my %tag_synonym=(
        screen => [qw(programlisting)],
        _text  => [qw(blockquote)],
    );
    while (my ($tag, $tag_synonym_ar)=each %tag_synonym) {
        foreach my $tag_synonym (@{$tag_synonym_ar}) {
            *{$tag_synonym}=sub {shift()->$tag(@_)}
        }
    }
}


sub text {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return $text;
}

1;
__END__
