#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2015 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
use vars qw($VERSION $AUTOLOAD @ISA @EXPORT);
use warnings;
no warnings qw(uninitialized);


#  Export functions
#
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
    md_join
    md_h1
    md_h2
    md_h3
    md_italic
    md_bold
    md_code
    md_list
    md_link
    md_email
    md_image
    md_image_build
);


#  External modules
#
use Docbook::Convert::Constant;
use Data::Dumper;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#  All done, init finished
#
1;


sub md_join {

    my ($text_ar, $join)=@_;
    my $md=join(ref($join) ? ${$join} : $join, @{$text_ar});
    return $md;
    
}
    

sub md_h1 {
    my $text=shift || return;
    return "# $text #";
}

sub md_h2 {
    my $text=shift || return;
    return "## $text ##";
}
    

sub md_h3 {
    my $text=shift || return;
    return "### $text ###";
}
    
sub md_italic {
    my $text=shift;
    return "*$text*";
}

sub md_bold {
    my $text=shift;
    return "**$text**";
}

sub md_code {
    my $text=shift;
    $text=~s/\`//g;
    return "`$text`";
}

sub md_list {
    my $text=shift;
    return "+ $text";
}

sub md_link {
    my ($url, $text, $title)=@_;
    if ($title) {
        return "[$text]($url \"$title\")";
    }
    else {
        return "[$text]($url)";
    }
}

sub md_image {
    my $md_link=&md_link(@_);
    return "!${md_link}";
}


sub md_image_build {
    my ($self, $data_ar)=@_;
    my $alt_text1=$self->find_node_tag_text($data_ar, 'alt', $NULL);
    my $title=$self->find_node_tag_text($data_ar, 'title', $NULL);
    my $image_data_ar=$self->find_node($data_ar, 'imagedata');
    my $image_data_attr_hr=$image_data_ar->[0][$ATTR_IX];
    my $alt_text2=$image_data_attr_hr->{'annotations'};
    my $alt_text=$alt_text1 || $alt_text2;
    my $url=$image_data_attr_hr->{'fileref'};
    return &md_image($url, $alt_text, $title);
}
    

sub md_email {
    my $email=shift();
    return "<$email>";
}

1;
