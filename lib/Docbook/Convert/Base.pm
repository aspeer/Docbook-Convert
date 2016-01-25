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
$VERSION='0.006';


#===================================================================================================


sub new {    ## no subsort

    #  New instance
    #
    my ($class, $param_hr)=@_;
    my %self=(
        meta_display_top           => $META_DISPLAY_TOP,
        meta_display_bottom        => $META_DISPLAY_BOTTOM,
        meta_display_title         => $META_DISPLAY_TITLE,
        meta_display_title_h_style => $META_DISPLAY_TITLE_H_STYLE,
        no_html                    => $NO_HTML,
        no_image_fetch             => $NO_IMAGE_FETCH,
        no_warn_unhandled          => $NO_WARN_UNHANDLED,
        %{$param_hr}
    );
    return bless(\%self, ref($class) || $class);

}


sub create_tag_synonym {

    #  Create tag equivalents
    #
    my ($tag_synonym_hr, $package)=@_;
    $package ||= (caller())[0];
    while (my ($tag, $tag_synonym_ar)=each %{$tag_synonym_hr}) {
        foreach my $tag_synonym (@{$tag_synonym_ar}) {
            *{"${package}::${tag_synonym}"}=sub {shift()->$tag(@_)}
        }
    }
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
        delete $self->{'_autoload'}{$data_ar};
    }
    else {
        foreach my $data_child_ar (@{$data_ar->[$CHLD_IX]}) {
            $self->find_node_recurse($result_ar, $data_child_ar, $tag);
        }
    }
    return undef;
}


sub find_node_tag_text {

    my ($self, $data_ar, $tag_ar, $join)=@_;
    $tag_ar ||= [$data_ar->[$NODE_IX]];
    unless (ref($tag_ar)) {
        $tag_ar=[split('\|', $tag_ar)];
    }
    my @text;
    foreach my $tag (@{$tag_ar}) {
        my @tag;

        #print "find tag $tag\n";
        $self->find_node_tag_text_recurse($data_ar, $tag, \@tag) ||
            return err ();
        if (@tag) {
            if (ref($join) eq 'SCALAR') {
                push @text, join(${$join}, @tag);
            }
            elsif (ref($join) eq 'CODE') {
                push @text, $join->(\@tag);
            }
            elsif ($join) {
                push @text, join($join, @tag);
            }
            else {
                push @text, \@tag
            }
        }
    }

    #elsif (wantarray() && (@{$tag_ar} > 1)) {
    #    return @text;
    #}
    #print Dumper(\@text);
    if (wantarray()) {
        return @text;
    }
    else {
        return $text[0];
    }

}


sub find_node_tag_text0 {

    my ($self, $data_ar, $tag_ar, $join)=@_;
    $tag_ar ||= [$data_ar->[$NODE_IX]];
    unless (ref($tag_ar)) {
        $tag_ar=[split('\|', $tag_ar)];
    }
    my @text;
    foreach my $tag (@{$tag_ar}) {

        #$self->find_node_tag_text_recurse($data_ar, $tag, \@text) ||
        #    return err ();
        my @tag;
        $self->find_node_tag_text_recurse($data_ar, $tag, \@tag) ||
            return err ();
        push @text, [@tag];
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
    elsif (wantarray() && (@{$tag_ar} > 1)) {
        return @text;
    }
    elsif (wantarray()) {
        return @{$text[0]};
    }
    else {
        return \@text;
    }

}


sub find_node_tag_text_recurse {

    #  Do the recursive searching for all text and push into array
    #
    my ($self, $data_ar, $tag, $text_ar, $tag_found)=@_;
    if ((my $node_tag=$data_ar->[$NODE_IX]) eq $tag) {

        #  Only return first hit. If already text in array just
        #  return;
        #
        return $text_ar if @{$text_ar};

        #  Else proceed
        #
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
    }
    return $text_ar;
}


sub find_node_text {

    my ($self, $data_ar, $join)=@_;
    my $tag=$data_ar->[$NODE_IX];
    return $self->find_node_tag_text($data_ar, $tag, $join);

}


sub find_parent {

    my ($self, $data_ar, $tag_ar)=@_;
    unless (ref($tag_ar)) {
        $tag_ar=[split('\|', $tag_ar)];
    }
    foreach my $tag (@{$tag_ar}) {

        #print "test $tag vs $data_ar->[$NODE_IX]\n";
        if ((my $t=$data_ar->[$NODE_IX]) eq $tag) {
            return $data_ar;
        }

        #elsif (my $data_parent_ar=$data_ar->[$PRNT_IX]) {
        #    return $self->find_parent($data_parent_ar, $tag_ar);
        #}
    }
    if (my $data_parent_ar=$data_ar->[$PRNT_IX]) {
        return $self->find_parent($data_parent_ar, $tag_ar);
    }
    return undef;

}


sub image_getwidth {

    my ($self, $url)=@_;
    $self->load_imagemagick() ||
        return err ();
    my $width;
    if (my $image=LWP::Simple::get($url)) {
        my $magick_or=Image::Magick->new(magick => 'jpg');
        $magick_or->BlobToImage($image);
        $width=$magick_or->Get('width');
    }
    return $width;

}


sub load_imagemagick {

    #  Load ImageMagic module
    #
    eval {
        require Image::Magick;
    } || do {
        return err ("unable to load Image::Magic module, $@");
    };
    eval {
        require LWP::Simple;
    } || do {
        return err ("unable to load LWP::Simple module, $@");
    };

}


sub AUTOLOAD {

    #  Catch tags we are not rendering yet - output them as text only
    #
    my ($self, $data_ar)=@_;
    my ($tag)=($AUTOLOAD=~/::(\w+)$/);
    $self->{'_autoload'}{$data_ar}=$data_ar;
    return $data_ar;
}


1;
__END__
