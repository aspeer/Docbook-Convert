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
package Docbook::Convert::POD::Util;


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


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#===================================================================================================


sub _bold {
    my ($self, $text)=@_;
    return "B<<< $text >>>";
}


sub _strikethrough {
    #  No strikethrough in POD
    my ($self, $text)=@_;
    return $text;
}


sub _code {
    my ($self, $text)=@_;
    $text=~s/C<<<\s+(.*?)\s+>>>/$1/g;
    return "C<<< $text >>>";
}


sub _email {
    my ($self, $email)=@_;
    return "<$email>";
}


sub _h1 {
    my ($self, $text)=@_;
    return "=head1 $text";
}


sub _h2 {
    my ($self, $text)=@_;
    return "=head2 $text";
}


sub _h3 {
    my ($self, $text)=@_;
    return "=head3 $text";
}


sub _h4 {
    my ($self, $text)=@_;
    return "=head4 $text";
}


sub _image_html {
    my ($self, $url, $alt_text, $title, $attr_hr)=@_;
    my $width=$attr_hr->{'width'};
    $width && ($width=qq(width="$width"));
    my $html=<<HERE;
=begin HTML

<p><img src="$url" alt="$alt_text" $width /></p>

=end HTML
HERE
    return $html
}


sub _image {

    #  Only HTML images available in POD
    shift()->_image_html(@_);
}


sub _italic {
    my ($self, $text)=@_;
    return "I<<< $text >>>";
}


sub _link {
    my ($self, $url, $text, $title)=@_;
    if (0) {
        return "L<[$text|$url> \"$title\")";
    }
    else {
        return "L<$text|$url>";
    }
}


sub _list_begin {
    return "${CR2}=over";
}


sub _list_end {
    return "=back${CR2}";
}


sub _list_item {
    my ($self, $text)=@_;
    return "=item $text";
}


sub _variablelist_join {
    return "${CR2}";
}


sub _listitem_join {
    &_variablelist_join(@_);
}


sub _anchor {
    return undef;
}
1;


sub _anchor_fix {

    #  Fix anchor refs to point to POD headers
    #
    my ($self, $output, $id_hr)=@_;
    while (my ($id, $title)=each %{$self->{'_id'}}) {
        $title=~s/\W+/-/g;
        $output=~s/L\<(.*?)\|#\Q$id\E/L\<$1|\"$title\"/g;
    }
    return $output;

}


1;
__END__

