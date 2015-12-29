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
package Docbook::Convert::Base;


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
$VERSION='0.001';


#  All done, init finished
#
1;


#===================================================================================================


sub find_parent {

    my ($self, $data_ar, $tag)=@_;
    if ((my $t=$data_ar->[$NODE_IX]) eq $tag) {
        return $data_ar;
    }
    elsif (my $data_parent_ar=$data_ar->[$PRNT_IX]) {
        return $self->find_parent($data_parent_ar, $tag);
    }
    return undef;
    
}


sub find_node {

    #  Find a node in the data tree
    #
    my ($self, $data_ar, $tag)=@_;
    $tag ||= $data_ar->[$NODE_IX];
    my @result;
    $self->find_node_recurse(\@result, $data_ar, $tag);
    return \@result;

}


sub find_node_recurse {

    #  Do the recursive searching. If we find remove tag from autoload hash - as we obviously knew
    #  enough about it to do the search for it.
    #
    my ($self, $result_ar, $data_ar, $tag)=@_;
    if ($data_ar->[$NODE_IX] eq $tag) {
        push @{$result_ar}, $data_ar;
        delete $self ->{'_autoload'}{$data_ar};
    }
    else {
        foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
            $self->find_node_recurse($result_ar, $data_child_ar, $tag);
        }
    }
    return undef;
}


sub find_node_text {

    my ($self, $data_ar, $join)=@_;
    my $tag = $data_ar->[$NODE_IX];
    return $self->find_node_tag_text($data_ar, $tag, $join);
    
}


sub find_node_tag_text {

    my ($self, $data_ar, $tag_ar, $join)=@_;
    $tag_ar ||= [$data_ar->[$NODE_IX]];
    unless (ref($tag_ar)) {
        $tag_ar=[split('\|', $tag_ar)];
    }
    my @text;
    foreach my $tag (@{$tag_ar}) {
        $self->find_node_tag_text_recurse($data_ar, $tag, \@text) ||
            return err();
    }
    if (ref($join) eq 'SCALAR') {
        return join(${$join}, @text);
    }
    elsif (ref($join) eq 'CODE') {
        return $join->(\@text);
    }
    elsif ($join) {
        return join($join, @text);
    }
    elsif (wantarray()) {
        return @text;
    }
    else {
        return \@text;
    }
    
}


sub find_node_tag_text_recurse {

    #  Do the recursive searching for all text and push into array
    #
    my ($self, $data_ar, $tag, $text_ar, $tag_found)=@_;
    if ($data_ar->[$NODE_IX] eq $tag) {
        $tag_found++;
        $self->{'_autotext'}{$data_ar}=undef;
        delete $self->{'_autoload'}{$data_ar};
    }
    foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
        if (ref($data_child_ar)) {
            $self->find_node_tag_text_recurse($data_child_ar, $tag, $text_ar, $tag_found);
        }
        elsif ($tag_found) {
            push @{$text_ar}, $data_child_ar;
        }
        if ($tag_found && ref($data_child_ar)) {
            delete $self->{'_autoload'}{$data_child_ar};
            $self->{'_autotext'}{$data_child_ar}=$data_child_ar unless  
                exists $self->{'_autotext'}{$data_child_ar}
        }
    }
    if ($tag_found) {
        delete $data_ar->[$CHLD_IX];
        #delete $self->{'_autoload'}{$data_ar};
    }
    return $text_ar;
}



sub find_node_tag_text_hashref {

    my ($self, $data_ar, $tag_ar, $join)=@_;
    unless (ref($tag_ar)) {
        $tag_ar=[split('\|', $tag_ar)];
    }
    my %text;
    foreach my $tag (@{$tag_ar}) {
        my $text=$self->find_node_tag_text($data_ar, $tag, $join);
        $text{$tag}=$text if $text;
    }
    return \%text;
    
}


sub find_node_tag_text_arrayref {

    my ($self, $data_ar, $tag_ar, $join)=@_;
    unless (ref($tag_ar)) {
        $tag_ar=[split('\|', $tag_ar)];
    }
    my @text;
    foreach my $tag (@{$tag_ar}) {
        my $text=$self->find_node_tag_text($data_ar, $tag, $join);
        push @text, $text
    }
    return \@text;
    
}






sub find_node_recurse0 {

    #  Do the recursive searching. If we find remove tag from autoload hash - as we obviously knew
    #  enough about it to do the search for it.
    #
    my ($self, $result_ar, $data_ar, $tag, $text_fg)=@_;
    if ($data_ar->[$NODE_IX] eq $tag) {
        delete $self->{'_autoload'}{$tag};
        if ($text_fg) {
            push @{$result_ar}, grep {!ref($_) } @{$data_ar->[$CHLD_IX]}
        }
        else {
            push @{$result_ar}, $data_ar;
        }
    }
    else {
        foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
            if (my $ar=$self->find_node_recurse($result_ar, $data_child_ar, $tag)) {
                delete $self->{'_autoload'}{$tag};
                return $ar;
            }
        }
    }
    return undef;
}

sub AUTOLOAD {

    #  Catch tags we are not rendering yet - output them as text only
    #
    my ($self, $data_ar)=@_;
    my ($tag)=($AUTOLOAD=~/::(\w+)$/);
    #print "AUTOLOAD $tag\n";
    $self->{'_autoload'}{$data_ar}=$data_ar;
    return $data_ar;
}



__END__





sub find_node_text_all0 {

    my ($self, $data_ar, $tag, $join)=@_;
    #@die Dumper(\@_) if ($tag eq 'listitem');
    $tag ||= $data_ar->[$NODE_IX];
    #$join ||= $SP;
    my @text;
    $self->find_node_text_all_recurse($data_ar, $tag, \@text) ||
        return err();
    die Dumper($data_ar, \@text) if ($tag eq 'listitem');
    if (ref($join)) {
        return join(${$join}, @text);
    }
    elsif ($join) {
        return join($join, @text);
    }
    elsif (wantarray()) {
        #die Dumper(\@text) if ($tag eq 'listitem');
        return @text;
    }
    else {
        return \@text;
    }
    
}



sub find_node_text_all_recurse1 {

    #  Do the recursive searching for all text and push into array
    #
    my ($self, $data_ar, $tag, $text_ar, $tag_found)=@_;
    if ($data_ar->[$NODE_IX] eq $tag) {
        $tag_found++;
    }
    #delete $self->{'_autoload'}{$tag} if $tag_found;
    delete $self->{'_autoload'}{$data_ar} if $tag_found;
    foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
        if (ref($data_child_ar)) {
            $self->find_node_text_all_recurse($data_child_ar, $tag, $text_ar, $tag_found);
        }
        else {
            push @{$text_ar}, $data_child_ar if $tag_found;
        }
        delete $self->{'_autoload'}{$data_child_ar} if $tag_found;
    }
    #$data_ar->[$CHLD_IX]=undef if $tag_found;
    #push @{$self->{'_unrender'}}, delete $data_ar->[$CHLD_IX] if $tag_found;
    #if ($tag_found) {
        #push @{$self->{'_unrender'}}, grep { ref($_) } @{delete $data_ar->[$CHLD_IX]}
        #push @{$self->{'_unrender'}}, @{delete $data_ar->[$CHLD_IX]}
    #}
    delete $data_ar->[$CHLD_IX] if $tag_found;
    return $text_ar;
}


sub find_node_text_all_recurse0 {

    #  Do the recursive searching for all text and push into array
    #
    my ($self, $data_ar, $tag, $text_ar, $tag_found)=@_;
    if ($data_ar->[$NODE_IX] eq $tag) {
        $tag_found++;
    }
    delete $self->{'_autoload'}{$tag} if $tag_found;
    foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
        if (ref($data_child_ar)) {
            $self->find_node_text_all_recurse($data_child_ar, $tag, $text_ar, $tag_found);
        }
        else {
            push @{$text_ar}, $data_child_ar if $tag_found;
        }
    }
    return $text_ar;
}
    

sub AUTOLOAD {

    #  Catch tags we are not rendering yet - output them as text only
    #
    my ($self, $data_ar)=@_;
    my ($tag)=($AUTOLOAD=~/::(\w+)$/);
    #print "self $self $AUTOLOAD\n";
    #push @{$self->{'_autoload'}{$tag}}, $data_ar;
    $self->{'_autoload'}{$data_ar}=$data_ar;
    #print Data::Dumper::Dumper($data_ar);
    #return $self->find_node_text($data_ar);
    return $data_ar;
}



1;