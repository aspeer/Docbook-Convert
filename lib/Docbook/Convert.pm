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
package Docbook::Convert;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);
sub BEGIN {local $^W=0}


#  External modules
#
use Docbook::Convert::Constant;
use Docbook::Convert::Util;


#  External modules
#
use IO::File;
use XML::Twig;
use Data::Dumper;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#===================================================================================================


sub data_ar {

    #  Container to hold node tree
    #
    my $self=shift();
    my @data=(
        shift() || undef,    # NODE_IX
        shift() || undef,    # CHLD_IX
        shift() || undef,    # ATTR_IX
        shift() || undef,    # LINE_IX
        shift() || undef,    # COLM_IX
        shift() || undef     # PRNT_IX
    );
    return \@data;

}


sub handler {


    #  Called by twig
    #
    my ($self, $data_ar, $twig_or, $elt_or)=@_;


    #  Don't process if not parent (i.e. until we have done all tags).
    #
    return if $elt_or->parent();


    #  Call parser now as we are on parent.
    #
    return $self->parse($data_ar, $elt_or);

}


sub parse {


    #  Parse and XML::Twig tree and produce a node tree
    #
    my ($self, $data_ar, $elt_or, $data_parent_ar)=@_;


    #  Get tag, any node attributes, line and col number
    #
    my $tag=$elt_or->tag();
    my $attr_hr=$elt_or->atts();
    my $line_no=delete $attr_hr->{'_line_no'};
    my $col_no=delete $attr_hr->{'_col_no'};
    $attr_hr=undef unless keys %{$attr_hr};


    #  Build array data
    #
    @{$data_ar}[$NODE_IX, $CHLD_IX, $ATTR_IX, $LINE_IX, $COLM_IX, $PRNT_IX]=
        ($tag, undef, $attr_hr, $line_no, $col_no, $data_parent_ar);    # Name, Child, Attr


    #  Go through children looking for any text nodes
    #
    foreach my $elt_child_or ($elt_or->children()) {

        #  Text ?
        #
        unless (($elt_child_or->tag() eq '#PCDATA') || ($elt_child_or->tag() eq '#CDATA')) {

            # No - recurse. Need new data container
            #
            my $data_child_ar=$self->data_ar();
            $self->parse($data_child_ar, $elt_child_or, $data_ar);
            push @{$data_ar->[$CHLD_IX]}, $data_child_ar;
        }
        else {

            # Yes - store as text node
            my $text=$elt_child_or->text();
            my $data_child_ar=
                $self->data_ar('text', [$text], undef, undef, undef, $data_ar);
            push @{$data_ar->[$CHLD_IX]}, $data_child_ar;
        }
    }


    #  Done - return OK
    #
    return \undef;

}


sub process_file {

    #  Open file we want to process
    #
    my ($self, $fn, $param_hr)=@_;
    my $fh=IO::File->new($fn, O_RDONLY) ||
        return err("unable to open file $fn, $!");
    return $self->process($fh, $param_hr);
    
}


sub process {


    #  Get self ref, file to process
    #
    my ($self, $xml, $param_hr)=@_;


    #  Create a hashed self ref to hold various info
    #
    ref($self) || do {
        $self=bless($param_hr ||= {handler => $HANDLER_DEFAULT}, ref($self) || $self)
    };


    #  Array to hold parsed data
    #
    my $data_ar=$self->data_ar();


    #  Load handler
    #
    my $handler=$param_hr->{'handler'} ||
        return err ('no handler supplied');
    my $handler_module=$HANDLER_HR->{$handler} ||
        return err ("unable to load handler: $handler, no module found");
    eval("use $handler_module") || do {
        return err ("unable to load handler module: $handler_module, $@")
            if $@
    };


    #  Get XML::Twig object
    #
    my $xml_or=XML::Twig->new(
        'twig_handlers' => {
            '_all_' => sub {$self->handler($data_ar, @_)}
        },
        'start_tag_handlers' => {
            '_all_' => sub {$self->start_tag_handler($data_ar, @_)}
        },
        discard_all_spaces => 1,
    );


    #  Parse file which will fill $data_ar;
    #
    $xml_or->parse($xml);


    #  If we are dumping clean up a bit then spit out
    #
    if ($param_hr->{'dump'}) {
        return Dumper(dump_ar($data_ar));
    }


    #  And render
    #
    my $output=$self->render($data_ar, $handler_module);


    #  Done
    #
    return $output;

}


sub render {


    #  Get self ref, node tree
    #
    my ($self, $data_ar, $handler)=@_;


    #  Get hander
    #
    my $render_or=$handler->new($self) ||
        return err ("unable to initialise handler $handler");


    #  Call recurive render routine
    #
    my $output=$self->render_recurse($data_ar, $render_or) ||
        return err ('unable to get ouput from render');


    #  Fix any anchors/links
    #
    $output=$render_or->_anchor_fix($output, $self->{'_id'});


    #  Any errors/warnings for unhandled tags ?
    #
    if ((my $hr=$render_or->{'_autoload'}) && !$NO_WARN_UNHANDLED) {
        my @data_ar=sort {($a->[$NODE_IX] cmp $b->[$NODE_IX]) or ($a->[$LINE_IX] <=> $b->[$LINE_IX])} grep {$_} values(%{$hr});
        foreach my $data_ar (@data_ar) {
            my ($tag, $line_no, $col_no)=@{$data_ar}[$NODE_IX, $LINE_IX, $COLM_IX];
            warn("warning - unrendered tag $tag at line $line_no, column $col_no\n");
        }
    }
    if ((my $hr=$render_or->{'_autotext'}) && !$NO_WARN_UNHANDLED) {
        my @data_ar=sort {($a->[$NODE_IX] cmp $b->[$NODE_IX]) or ($a->[$LINE_IX] <=> $b->[$LINE_IX])} grep {$_} values(%{$hr});
        foreach my $data_ar (@data_ar) {
            my ($tag, $line_no, $col_no)=@{$data_ar}[$NODE_IX, $LINE_IX, $COLM_IX];
            warn("warning - autotexted tag $tag at line $line_no, column $col_no\n");
        }
    }


    #  Done
    #
    return $output;

}


sub render_recurse {


    #  Get self ref, node
    #
    my ($self, $data_ar, $render_or)=@_;


    #  Render any children
    #
    if ($data_ar->[$CHLD_IX]) {
        foreach my $data_chld_ix (0..$#{$data_ar->[$CHLD_IX]}) {
            my $data_chld_ar=$data_ar->[$CHLD_IX][$data_chld_ix];
            if (ref($data_chld_ar)) {
                my $data=$self->render_recurse($data_chld_ar, $render_or);
                $data_ar->[$CHLD_IX][$data_chld_ix]=$data;
            }
        }
    }


    #  Now render tag
    #
    my $tag=$data_ar->[$NODE_IX];
    my $render=$render_or->$tag($data_ar);


    #  Done
    #
    return $render;

}


sub start_tag_handler {

    my ($self, $data_ar, $twig_or, $elt_or)=@_;
    $elt_or->set_att('_line_no', $twig_or->current_line());
    $elt_or->set_att('_col_no',  $twig_or->current_column());

}


sub AUTOLOAD {

    #  Catchall for handler shortcuts, e.g. Docbook::Convert->markdown();
    #
    my ($self, $xml, $param_hr)=@_;
    my ($handler)=($AUTOLOAD=~/::(\w+)$/);
    if ($handler=~s/_file$//) {
        return $self->process_file($xml, {%{$param_hr}, handler=>$handler});
    }
    else {
        return $self->process($xml, {%{$param_hr}, handler=>$handler});
    }
}

1;
__END__

=head1 NAME

Docbook::Convert - Module Synopsis/Abstract Here

=head1 LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2016 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:
L<http://dev.perl.org/licenses/>

