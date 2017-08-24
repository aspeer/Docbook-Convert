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
package Docbook::Convert::Markdown::Util;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Docbook::Convert::Constant;
use Data::Dumper;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.015';


#===================================================================================================


sub _anchor {

    my ($self, $id)=@_;
    my $anchor=qq(<a name="$id"></a>);
    return $anchor;

}


sub _anchor_fix {

    #  Nothing to fix in markdown
    #
    my ($self, $output)=@_;
    return $output;

}


sub _bold {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text : "**$text**";
}


sub _code {
    my ($self, $text)=@_;
    $text=~s/\`//g;
    $text=~s/\s+\Q<**SBR**>\E\s+/`  $CR`/g;
    return $self->{'_plaintext'} ? $text : "`$text`";
}


sub _email {
    my ($self, $email)=@_;
    return $self->{'_plaintext'} ? $email : "<$email>";
}


sub _h1 {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text : "# $text #";
}


sub _h2 {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text : "## $text ##";
}


sub _h3 {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text : "### $text ###";
}


sub _h4 {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text :  "#### $text ####";
}


sub _quote {
    my ($self, $text)=@_;
    my $quote;
    my @line=($text=~/^(.*)$/gm);
    foreach my $line (@line) {
        chomp($line);
        $quote.="> ${line}${CR}";
    }
    $quote.=">${CR}";
    return $quote;
}
    

sub _image {
    my ($self, $url, $alt_text, $title, $attr_hr)=@_;
    if ((my $width=$attr_hr->{'width'}) && !$NO_HTML) {

        #  MD generally can't do width - convert to HTML link
        return $self->_image_html($url, $alt_text, $title, $attr_hr);
    }
    else {
        my $md_link=$self->_link($url, $alt_text, $title, $attr_hr);
        return "!${md_link}";
    }
}


sub _image_html {
    my ($self, $url, $alt_text, $title, $attr_hr)=@_;
    my $width=$attr_hr->{'width'};
    $width && ($width=qq(width="$width"));
    my $html=<<HERE;
<p><img src="$url" alt="$alt_text" $width /></p>
HERE
    return $html
}


sub _italic {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text :  "*$text*";
}


sub _link {
    my ($self, $url, $text, $title)=@_;

    #print "url $url\n";
    if ($self->{'_plaintext'}) {
        return $url
    }
    elsif ($title) {
        return "[$text]($url \"$title\")";
    }
    else {
        return "[$text]($url)";
    }
}


sub _list {
    my $self=shift;
    my $text=shift;
    return "+ $text";
}


sub _list_begin {
    return undef;
}


sub _list_end {
    return undef;
}


sub _list_item {
    my ($self, $text)=@_;
    return $text;
}


sub _listitem_join {
    &_variablelist_join(@_);
}


sub _prefix {
    return undef;
}


sub _strikethrough {
    my ($self, $text)=@_;
    return $self->{'_plaintext'} ? $text : "~~$text~~";
}


sub _suffix {
    return undef;
}


sub _variablelist_join {
    return "${CR2}${SP4}";
}

1;
__END__

