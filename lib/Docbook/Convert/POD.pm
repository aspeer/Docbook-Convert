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
package Docbook::Convert::POD;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Docbook::Convert::Constant;
#use Docbook::Convert::MarkDown::Constant;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


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


__END__


sub new {

    #  New instance
    #
    my $class=shift();
    return bless(\(my $self=undef), ref($class) || $class );

}


sub para {
    my ($self, $data_ar)=@_;
    my @text=&find_node_text($data_ar);
    my $text=join(undef, @text);
    $text=~s/\n//mg;
    return $text;
    
}


sub emphasis {
    my ($self, $data_ar)=@_;
    my $text=&find_node_text($data_ar);
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $role=$attr_hr->{'role'};
    if ($role eq 'bold') {
        return "B<< $text >>";
    }
    else {
        return "I<< $text >>";
    }
}

sub refentry {
    my ($self, $data_ar)=@_;
    #die Dumper($data_ar);
    my $text=&find_node_text($data_ar, undef, "\n\n");
    return $text;
    die("text $text");
    #print Dumper($data_ar);
}


sub refmeta {
    my ($self, $data_ar)=@_;
    my $refentrytitle=&find_node_text($data_ar, 'refentrytitle');
    my $manvolnum=&find_node_text($data_ar, 'manvolnum');
    my $md="=head1 $refentrytitle $manvolnum";
    return $md;
}



sub classname {
    my ($self, $data_ar)=@_;
    my $text=&find_node_text($data_ar);
    return "C<< $text >>";
}

sub command {
    return &classname(@_);
}

sub cmdsynopsis {
    my ($self, $data_ar)=@_;
    #die Dumper(\@_);
    my $text=&find_node_text($data_ar);
    #die "text: $text\n";
    return $text;
    return die &find_node_text(@_, "\n\n");
}

sub refsynopsisdiv {
    my ($self, $data_ar)=@_;
    my $text=&find_node_text($data_ar);
    return "=head2 SYNOPSIS\n\n$text";
}

sub refnamediv {
    my ($self, $data_ar)=@_;
    my $name_text=&find_node_text($data_ar, 'refname');
    my $purpose_text=&find_node_text($data_ar, 'refpurpose');
    my $md="=head2 NAME\n\n$name_text - $purpose_text";
    return $md;
}

sub varlistentry {
    my ($self, $data_ar)=@_;
    my $term_text=&find_node_text($data_ar, 'term');
    my $item_text=&find_node_text($data_ar, 'listitem');
    my $md="=item C<< $term_text >>\n\n$item_text";
    return $md;
}


sub refsection {
    my ($self, $data_ar)=@_;
    my $title=&find_node_text($data_ar, 'title');
    my $text=&find_node_text($data_ar, undef, "\n\n");
    return "=head2 $title\n\n$text";
}

sub variablelist {
    my ($self, $data_ar)=@_;
    my $md="=over\n\n". &find_node_text($data_ar, undef, "\n\n");
    $md.="\n\n=back";
    return $md;
}

sub itemizedlist {
    my ($self, $data_ar)=@_;
    my @item_data_ar=&find_node($data_ar, 'listitem');
    my @item;
    foreach my $item_data_ar (@item_data_ar) {
        my $item_text=&find_node_text($item_data_ar, undef, "\n\n");
        push @item, "=item *\n\n$item_text";
    }
    my $item=join("\n\n", @item);
    $item="=over\n\n$item\n\n=back";
}

sub orderedlist {
    my ($self, $data_ar)=@_;
    my @item_data_ar=&find_node($data_ar, 'listitem');
    my @item;
    my $count;
    foreach my $item_data_ar (@item_data_ar) {
        my $item_text=&find_node_text($item_data_ar, undef, "\n\n");
        $count++;
        push @item, "=item $count\n\n$item_text";
    }
    my $item=join("\n\n", @item);
    $item="=over\n\n$item\n\n=back";
}

sub screen {
    my ($self, $data_ar)=@_;
    my $text=&find_node_text($data_ar);
    my @text=($text=~/^(.*)$/gm);
    #die Dumper(\@text);
    return join("\n", map { "    $_" } @text);
}

sub programlisting {
    &screen(@_);
}


sub link {
    #return "Hello";
    my ($self, $data_ar)=@_;
    my $attr_hr=$data_ar->[$ATTR_IX];
    my $url=$attr_hr->{'xlink:href'};
    my $title=$attr_hr->{'annotations'};
    my $text=&find_node_text($data_ar);
    #die $text;
    #$url="$url \"$title\"" if $title;
    $url=join('|', $title, $url) if $title;
    my $md="L<< $url >>";
    #die $md;
    return $md;
}

sub email {
    #return "World";
    my ($self, $data_ar)=@_;
    my $text=&find_node_text($data_ar);
    my $md="<$text>";
    return $md;
}

sub imageobject0 {
    my ($self, $data_ar)=@_;
    my $image_data_ar=&find_node($data_ar, 'imagedata');
    #my @image_data_ar=&find_node($data_ar, 'imagedata');
    #die "BANG !" , Dumper($image_data_ar);
    my $image_data_attr_hr=$image_data_ar->[$ATTR_IX];
    #die "BANG !" , Dumper($image_data_attr_hr);
    my $url=$image_data_attr_hr->{'fileref'};
    my $alt_text=$image_data_attr_hr->{'annotations'};
    my $md="![$alt_text]($url)";
    return $md;
}


sub mediaobject0 {
    my ($self, $data_ar)=@_;
    my $alt_text1=&find_node_text($data_ar, 'alt');
    my $image_data_ar=&find_node($data_ar, 'imagedata');
    #die "BANG !" , Dumper($image_data_ar);
    my $image_data_attr_hr=$image_data_ar->[$ATTR_IX];
    my $alt_text2=$image_data_attr_hr->{'annotations'};
    my $alt_text=$alt_text1 || $alt_text2;
    my $url=$image_data_attr_hr->{'fileref'};
    my $md="![$alt_text]($url)";
    return $md;
}

sub figure {
    my ($self, $data_ar)=@_;
    my $alt_text1=&find_node_text($data_ar, 'alt');
    my $title=&find_node_text($data_ar, 'title');
    my $image_data_ar=&find_node($data_ar, 'imagedata');
    my $image_data_attr_hr=$image_data_ar->[$ATTR_IX];
    my $alt_text2=$image_data_attr_hr->{'annotations'};
    my $alt_text=$alt_text1 || $alt_text2;
    my $url=$image_data_attr_hr->{'fileref'};
    if ($title) { $url="$url \"$title\"" }
    my $md="![$alt_text]($url)";
    return $md;
}

sub blockquote {
    my ($self, $data_ar)=@_;
    my @text=&find_node_text($data_ar, undef);
    my $md;
    $md="=over\n\n";
    foreach my $line (@text) {
        my @line=($line=~/^(.*)$/gm);
        foreach my $line (@line) {
            chomp($line);
            $md.="$line\n";
        }
        $md.="\n";
    }
    $md.="\n=back";
    return $md;

}


sub AUTOLOAD {
    my ($self, $data_ar)=@_;
    #print "AUTOLOAD $AUTOLOAD $data_ar\n";
    return $data_ar;
}


#================================================================================================


sub find_node {

    #  Find a now
    #
    my ($data_ar, $node, $text_fg, $join)=@_;
    $node ||= $data_ar->[$NODE_IX];
    my @result;
    my $return=&find_node_search(\&find_node_search, \@result, $data_ar, $node, $text_fg, $join);
    return $join ? join($join, grep {!ref($_) } @result) : wantarray ? @result : $result[0];
}

sub find_node_text {
    my ($data_ar, $node, $join)=@_;
    $node ||= $data_ar->[$NODE_IX];
    return (wantarray || !$join) ? (&find_node($data_ar, $node, 1)) : &find_node($data_ar, $node, 1, $join);
}

sub find_node_search {

    my ($cr, $result_ar, $data_ar, $node, $text_fg, $join)=@_;
    if ($data_ar->[$NODE_IX] eq $node) {
        #delete $MISSING{$node};
        if ($text_fg) {
            push @{$result_ar}, grep {!ref($_) } @{$data_ar->[$CHLD_IX]}
        }
        else {
            push @{$result_ar}, $data_ar;
        }
    }
    else {
        foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
            if (my $ar=$cr->($cr, $result_ar, $data_child_ar, $node, $text_fg, $join)) {
                #delete $MISSING{$node};
                return $ar;
            }
        }
    }
    return undef;
}
