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
package Docbook::Convert::Common;


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
$VERSION='0.001';


#  Make synonyms
#
&create_tag_synonym; 


#===================================================================================================


sub create_tag_synonym { ## no subsort

    #  Create tag formatting equivalents
    #
    my %tag_synonym=(
        command         => [qw(classname parameter filename markup)],
        refsection      => [qw(refsect1)],
        para            => [qw(simpara)],
        _text           => [qw(refentry article literallayout)],
        _null           => [qw(imageobject)]
    );
    while (my($tag, $tag_synonym_ar)=each %tag_synonym) {
        foreach my $tag_synonym (@{$tag_synonym_ar}) {
            *{$tag_synonym}=sub { shift()->$tag(@_) }
        }
    }
}


sub _text {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $CR2);
    #  Clean up and extra blank lines
    $text=~s/^(\s*${CR}){2,}/${CR}/gm;
    return $text;
}


sub _null {
    my ($self, $data_ar)=@_;
    return $data_ar;
}


sub arg {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $SP);
    return $self->_code("[$text]");
}


sub blockquote {
    my ($self, $data_ar)=@_;
    my @text=$self->find_node_text($data_ar);
    my $text;
    foreach my $line (@text) {
        my @line=($line=~/^(.*)$/gm);
        foreach my $line (@line) {
            chomp($line);
            $text.="> ${line}${CR}";
        }
        $text.=">${CR}";
    }
    return $text;
}

sub cmdsynopsis {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $SP);
    return $self->_code($text);
}

sub command {
    my ($self, $data_ar)=@_;
    if ($self->find_parent($data_ar, 'screen')) {
        #  render later
        return $data_ar;
    }
    else {
        my $text=$self->find_node_text($data_ar, $NULL);
        return $self->_code($text);
    }
}


sub email {
    my ($self, $data_ar)=@_;
    my $email=$self->find_node_text($data_ar, $NULL);
    return $self->_email($email);
}


sub emphasis {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $role=$attr_hr->{'role'};
    if ($role eq 'bold') {
        $self->_bold($text);
    }
    else {
        $self->_italic($text);
    }
}


sub figure {
    my ($self, $data_ar)=@_;
    return $self->_image_build($data_ar);
}


sub itemizedlist0 {
    my ($self, $data_ar)=@_;
    my @text;
    foreach my $text ($self->find_node_text($data_ar)) {
        push @text, $self->_list($text);
    }
    return join($CR2, @text);
}


sub itemizedlist {
    my ($self, $data_ar)=@_;
    my @list;
    foreach my $text ($self->find_node_text($data_ar)) {
        push @list, $self->_list_item("* $text");
    }
    return join($CR2, grep {$_} $self->_list_begin(), @list, $self->_list_end);
}


sub variablelist {
    my ($self, $data_ar)=@_;
    my @list;
    foreach my $ar (@{$self->find_node($data_ar, 'varlistentry')}) {
        my $text=$self->find_node_text($ar, $self->_variablelist_join());
        push @list, "* $text";
    }
    return join($CR2, grep {$_} $self->_list_begin(), @list, $self->_list_end);
}


sub orderedlist {
    my ($self, $data_ar)=@_;
    my (@list, $count);
    foreach my $text ($self->find_node_text($data_ar)) {
        $count++;
        push @list, $self->_list_item("$count. $text");
    }
    return join($CR2, grep {$_} $self->_list_begin(), @list, $self->_list_end);
}


sub link {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $url;
    if ($attr_hr->{'xlink:href'}) {
        $url=$attr_hr->{'xlink:href'};
    }
    elsif (my $linkend=$attr_hr->{'linkend'}) {
        $url="#${linkend}";
    }
    my $title=$attr_hr->{'annotations'};
    my $text=$self->find_node_text($data_ar, $NULL);
    return $self->_link($url, $text, $title);
}


sub ulink {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $url=$attr_hr->{'url'};
    my $text=$self->find_node_text($data_ar, $NULL);
    return $self->_link($url, $text);
}


sub listitem {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $self->_listitem_join());
    return $text;
}

sub mediaobject {
    my ($self, $data_ar)=@_;
    if ($self->find_parent($data_ar, 'figure')) {
        #  render later
        return $data_ar;
    }
    else {
        return $self->_image_build($data_ar);
    }
}
        
sub option {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return $self->_code($text);
}


sub para {

    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return $text;
    
}

sub programlisting {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $lang=$attr_hr->{'language'};
    my $text=$self->find_node_text($data_ar, $NULL);
    $text="${CR2}```${lang}${CR}${text}${CR}```${CR2}";
    return $text
}

sub refmeta {
    my ($self, $data_ar)=@_;
    my ($refentrytitle, $manvolnum)=
        $self->find_node_tag_text($data_ar, 'refentrytitle|manvolnum', $NULL);
    my $text=$self->_h1("$refentrytitle $manvolnum");
    return $text;
}


sub refnamediv {

    my ($self, $data_ar)=@_;
    my ($refname, $refpurpose)=
        $self->find_node_tag_text($data_ar, 'refname|refpurpose');
    my $text=$self->_h2('NAME') . $CR2 . join(' - ', grep {$_} $refname, $refpurpose);
    return $text;
}

sub refsection {
    my ($self, $data_ar)=@_;
    my ($title, $subtitle)=
        $self->find_node_tag_text($data_ar, 'title|subtitle');
    my $text=$self->find_node_text($data_ar, $CR2);
    return join($CR2, $self->_h2($title), $text);
}


sub appendix {

    my ($self, $data_ar)=@_;
    delete @{$self}{qw(_sect1 _sect2 _sect3 _sect4)};
    my $app_ix=$self->{'_appendix_count'}++;
    my @label;
    my $cr=sub {
        my ($cr, $num)=@_;
        my $int;
        if ($int=int($num/26)) {
            $cr->($cr, ($int-1));
        }
        push @label, chr(($num%26)+65);
    };
    $cr->($cr, $app_ix);
    my $label=join(undef, @label);
    my ($title, $subtitle)=
        $self->find_node_tag_text($data_ar, 'title|subtitle');
    my $text=$self->find_node_text($data_ar, $CR2);
    my $appendix=$self->_h1("Appendix $label: $title");
    return join($CR2, $appendix, $text);

}


sub sect1 {    
    my ($self, $data_ar)=@_;
    my $count_sect1=++$self->{'_sect1'};
    delete @{$self}{qw(_sect2 _sect3 _sect4)};
    return $self->_sect($data_ar, $count_sect1);
}

        
sub sect2 {    
    my ($self, $data_ar)=@_;
    my $count_sect1=($self->{'_sect1'}+1);
    my $count_sect2=++$self->{'_sect2'};
    delete @{$self}{qw(_sect3 _sect4)};
    my $count="$count_sect1.$count_sect2";
    return $self->_sect($data_ar, $count);
}

sub sect3 {    
    my ($self, $data_ar)=@_;
    my $count_sect1=($self->{'_sect1'}+1);
    my $count_sect2=($self->{'_sect2'}+1);
    my $count_sect3=++$self->{'_sect3'};
    delete @{$self}{qw(_sect4)};
    my $count="$count_sect1.$count_sect2.$count_sect3";
    return $self->_sect($data_ar, $count);
}

sub sect4 {    
    my ($self, $data_ar)=@_;
    my $count_sect1=($self->{'_sect1'}+1);
    my $count_sect2=($self->{'_sect2'}+1);
    my $count_sect3=($self->{'_sect3'}+1);
    my $count_sect4=++$self->{'_sect4'};
    my $count="$count_sect1.$count_sect2.$count_sect3.$count_sect4";
    return $self->_sect($data_ar, $count);
}

sub _sect {
    my ($self, $data_ar, $count)=@_;
    my ($title, $subtitle)=
        $self->find_node_tag_text($data_ar, 'title|subtitle', $NULL);
    my $anchor;
    if ($data_ar->[$ATTR_IX] && (my $id=$data_ar->[$ATTR_IX]{'id'})) {
        $anchor=$self->_anchor($id) unless $NO_HTML;
        $self->{'_id'}{$id}=$title;
    }
    my $text=$self->find_node_text($data_ar, $CR2);
    my $tag=$data_ar->[$NODE_IX];
    my ($h_level)=($tag=~/(\d+)$/);
    $h_level="_h${h_level}";
    return join($CR2, grep {$_} $anchor, $self->$h_level("$count $title"), $text);
}


sub refsynopsisdiv {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    $text=$self->_h2('SYNOPSIS') . $CR2 . $text;
    return $text;
}


sub screen {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    my @text=($text=~/^(.*)$/gm);
    return $CR2 . join($CR, map { "${SP4}$_" } @text) . $CR2;
}

sub term {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return $self->_bold($self->_code($text));
}


sub _image_build {
    my ($self, $data_ar)=@_;
    my $alt_text1=$self->find_node_tag_text($data_ar, 'alt', $NULL);
    my $title=$self->find_node_tag_text($data_ar, 'title', $NULL);
    my $image_data_ar=$self->find_node($data_ar, 'imagedata');
    my $image_data_attr_hr=$image_data_ar->[0][$ATTR_IX];
    my $alt_text2=$image_data_attr_hr->{'annotations'};
    my $alt_text=$alt_text1 || $alt_text2;
    my $url=$image_data_attr_hr->{'fileref'};
    if ((my $scale=$image_data_attr_hr->{'scale'}) && !$NO_HTML && !$NO_IMAGE_FETCH) {
        #  Get Image width
        #
        my $width=$self->image_getwidth($url);
        $width*=($scale/100);
        $image_data_attr_hr->{'width'}=$width;
    }
    return $self->_image($url, $alt_text, $title, $image_data_attr_hr);
}


1;
__END__
