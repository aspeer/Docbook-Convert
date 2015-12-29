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
package Docbook::Convert::Markdown;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Docbook::Convert::Markdown::Util;
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


#  All done, init finished
#
1;


#===================================================================================================

sub create_tag_synonym {

    #  Create markdown equivalents
    #
    my %md_synonym=(
        command         => [qw(classname parameter filename)],
        refsection      => [qw(refsect1)],
        para            => [qw(simpara)]
    );
    while (my($tag, $tag_synonym_ar)=each %md_synonym) {
        foreach my $tag_synonym (@{$tag_synonym_ar}) {
            *{$tag_synonym}=\&{$tag};
        }
    }
}


sub new {

    #  New instance
    #
    my $class=shift();
    return bless((my $self={}), ref($class) || $class );

}

sub para {

    my ($self, $data_ar)=@_;
    my $md=$self->find_node_text($data_ar, $NULL);
    return $md;
    
}

sub command {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return &md_code($text);
}


sub arg {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $SP);
    return &md_code("[$text]");
}
    

sub cmdsynopsis {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $SP);
    return &md_code($text);
}


sub option {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    return &md_code($text);
}


sub term {
    my ($self, $data_ar)=@_;
    my $md=$self->find_node_text($data_ar, $NULL);
    return &md_code($md);
}


sub listitem {
    my ($self, $data_ar)=@_;
    my $md=$self->find_node_text($data_ar, "${CR2}${SP4}");
    return $md;
}


sub variablelist {
    my ($self, $data_ar)=@_;
    my @md;
    foreach my $ar (@{$self->find_node($data_ar, 'varlistentry')}) {
        my $md=$self->find_node_text($ar, "${CR2}${SP4}");
        push @md, &md_list($md);
    }
    return join($CR2, @md);
}


sub refmeta {
    my ($self, $data_ar)=@_;
    my ($refentrytitle, $manvolnum)=
        $self->find_node_tag_text($data_ar, 'refentrytitle|manvolnum');
    my $md=&md_h1("$refentrytitle $manvolnum");
    return $md;
}

sub refnamediv {

    my ($self, $data_ar)=@_;
    my ($refname, $refpurpose)=
        $self->find_node_tag_text($data_ar, 'refname|refpurpose');
    my $md=&md_h2('NAME') . $CR2 . join(' - ', grep {$_} $refname, $refpurpose);
    return $md;
}
        
sub refsynopsisdiv {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    my $md=&md_h2('SYNOPSIS') . $CR2 . $text;
    return $md;
}


sub refsection {
    my ($self, $data_ar)=@_;
    my ($title, $subtitle)=
        $self->find_node_tag_text($data_ar, 'title|subtitle');
    my $text=$self->find_node_text($data_ar, $CR2);
    return join($CR2, &md_h2($title), $text);
}


sub programlisting {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $lang=$attr_hr->{'language'};
    my $text=$self->find_node_text($data_ar, $NULL);
    my $md="```${lang}${CR}${text}${CR}```";
    return $md
}


sub emphasis {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $role=$attr_hr->{'role'};
    if ($role eq 'bold') {
        &md_bold($text);
    }
    else {
        &md_italic($text);
    }
}

sub screen {
    my ($self, $data_ar)=@_;
    my $text=$self->find_node_text($data_ar, $NULL);
    my @text=($text=~/^(.*)$/gm);
    return join($CR, map { "${SP4}$_" } undef, @text);
}

sub itemizedlist {
    my ($self, $data_ar)=@_;
    my @md;
    foreach my $md ($self->find_node_text($data_ar)) {
        push @md, &md_list($md);
    }
    return join($CR2, @md);
}

sub orderedlist {
    my ($self, $data_ar)=@_;
    my (@md, $count);
    foreach my $md ($self->find_node_text($data_ar)) {
        $count++;
        push @md, "$count. $md";
    }
    return join($CR2, @md);
}


sub link {
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $url=$attr_hr->{'xlink:href'};
    my $title=$attr_hr->{'annotations'};
    my $text=$self->find_node_text($data_ar, $NULL);
    return &md_link($url, $text, $title);
}

sub email {
    my ($self, $data_ar)=@_;
    my $email=$self->find_node_text($data_ar, $NULL);
    return &md_email($email);
}


sub blockquote {
    my ($self, $data_ar)=@_;
    my @text=$self->find_node_text($data_ar);
    my $md;
    foreach my $line (@text) {
        my @line=($line=~/^(.*)$/gm);
        foreach my $line (@line) {
            chomp($line);
            $md.="> ${line}${CR}";
        }
        $md.=">${CR}";
    }
    return $md;
}


sub mediaobject {
    my ($self, $data_ar)=@_;
    if ($self->find_parent($data_ar, 'figure')) {
        #  render later
        return $data_ar;
    }
    else {
        return &md_image_build($self, $data_ar);
    }
}

sub figure {
    my ($self, $data_ar)=@_;
    return &md_image_build($self, $data_ar);
}


sub refentry {
    my ($self, $data_ar)=@_;
    my $md=$self->find_node_text($data_ar, $CR2);
    return $md;
}

1;
