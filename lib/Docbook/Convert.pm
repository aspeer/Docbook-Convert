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
$VERSION='0.005';


#===================================================================================================

sub data_ar {

    #  Container to hold node tree
    #
    my $self=shift();
    my @data=(
        shift() || undef,    # NODE_IX - tag name
        shift() || undef,    # CHLD_IX - array of child nodes
        shift() || undef,    # ATTR_IX - attributes
        shift() || undef,    # LINE_IX - line no this node was sourced from
        shift() || undef,    # COLM_IX - col no " "
        shift() || undef     # PRNT_IX - link to parent node
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
    if ((my $hr=$render_or->{'_autoload'}) && !$self->{'no_warn_unhandled'}) {
        my @data_ar=sort {($a->[$NODE_IX] cmp $b->[$NODE_IX]) or ($a->[$LINE_IX] <=> $b->[$LINE_IX])} grep {$_} values(%{$hr});
        foreach my $data_ar (@data_ar) {
            my ($tag, $line_no, $col_no)=@{$data_ar}[$NODE_IX, $LINE_IX, $COLM_IX];
            warn("warning - unrendered tag $tag at line $line_no, column $col_no\n");
        }
    }
    if ((my $hr=$render_or->{'_autotext'}) && !$self->{'no_warn_unhandled'}) {
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


sub pod_replace {

    #  Shortcut for convenience
    return Docbook::Convert::POD::Util::_pod_replace(@_);
    
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

sub DESTROY {
    
    #  Stub so not invoked by AUTOLOAD
    
}

1;
__END__

=pod

=head1 Docbook::Convert 3

=head1 NAME

Docbook::Convert - Convert Docbook articles and refentry's to other formats such as Markup and POD

=head1 SYNOPSIS

    # Use on file handle
    #
    use Docbook::Convert;
    open FILE, 'docbook.xml' or die $!;
    print Docbook::Convert->markdown(*FILE);
    print Docbook::Convert->pod(*FILE);
    
    # Use on existing file
    #
    print Docbook::Convert->markdown_file('docbook.xml');
    
    # Use on existing string
    #
    print Docbook::Convert->markdown($docbook);
    
    # Specify output options
    #
    print Docbook::Convert->markdown($docbook, { meta_display_top=>1 });

=head1 Description

Docbook::Convert Perl will convert between Docbook and other formats - currently Markdown and POD. It is intended to let authors write documentation in Docbook, and then output it to more easily publishable formats such as Markdown - or have it converted to POD and optionally merged into a perl programs or module.

It currently supports as subset of Docbook tags, and its intent is to convert Docbook 4+ article and refentry templates with common entites into manual pages or other documentation.

=head1 Methods

The following public methods are supplied:

=over

=item * B<<< process($xml, \%opt) >>>

Convert an XML string or file handle into a different format. Unless directed via the handler option the default conversion will be to Markdown

=item * B<<< process_file($filename, \%opt) >>>

Convert an XML file - specified in $filename - into a different format. As per the process method the default convertsion if not otherwise specified will be Markdown.

=item * B<<< markdown($xml, \%opt) >>>

A shortcut to the process method with the Markdown handler implied

=item * B<<< markdown_file >>>

A shortcut to the process_file method with the Markdown handler implied

=item * B<<< pod($xml, \%opt) >>>

A shortcut to the process method with the POD handler implied

=item * B<<< pod_file($xml, \%opt) >>>

A shortcut to the process_file method with the POD handler implied

=back

=head1 Options

The following options can be supplied to the process methods as a hash reference as per the synopsis example:

=over

=item * B<<< meta_display_top >>>

If the Docbook Refentry or Article contains metadata (author, publication date etc.) display it at the top of the file in "key: value" format. By default metadata is not displayed. Supply as boolean.

=item * B<<< meta_display_bottom >>>

As per meta_display_top but output at bottom.

=item * B<<< meta_display_title >>>

If the metadata is to be prefixed with a title supply as a string.

=item * B<<< meta_display_title_h_style >>>

If a title is supplied the option will set which heading style is used to generate it. By default output is the equivalent of "Heading 1". Supported values are 'h1' through to 'h4'

=item * B<<< no_html >>>

Do not comingle HTML with the generated output. For some output handlers where the desired output outcome is not available natively HTML may be supplied (e.g. Markdown). Setting this option to 1 will suppress any HTML output. Naturally this may limit the completeness of any conversion

=item * B<<< no_image_fetch >>>

For some Docbook image entities attributes that control the scaling of images may be supplied. If they are found in some cases the images may need to be fetched to generate the appropriate HTML width paramaters. Setting this option to 1 will suppress any remote image fetching and thus will disable any image scaling in conversions.

=item * B<<< no_warn_unhandled >>>

By default Docbook entites that are not handled in the conversion process (because the code does not yet cater for them) generate a warning. Setting this option to 1 will suppress any warnings.

=back

=head1 Environment

The following environment variables will alter the behaviour or the module as per their Option equivalent:

=over

=item * META_DISPLAY_TOP

=item * META_DISPLAY_BOTTOM

=item * META_DISPLAY_TITLE

=item * META_DISPLAY_TITLE_H_STYLE

=item * NO_HTML

=item * NO_IMAGE_FETCH

=item * NO_WARN_UNHANDLED

=back

=head1 Files

The file C<<<< <sitelibpath>/Docbook/Convert/Constants.pm >>>> contains global settings which influence the behaviour of the module. Whilst this file can be edited any changes will be overwritten if the module is updated. If a file named C<<<< <sitelibpath>/Docbook/Convert/Constants.pm.local >>>> exists, then any entries in that file will override the local globals. The file format should be that of an anoymous hash reference, e.g file contents of:

    {
        NO_HTML         => 1,
        NO_IMAGE_FETCH  => 1
    }

Will change the defaults for the named globals. The syntax needs to be perl correct - check file has no errors when run against C<<<< perl -c -w <dir>/Constants.pm.local >>>>

=head1 Caveats

This module does not puport to handle all Docbook entity tags or templates. It operates on a limited subset of entity tags commonly used for describing manual pages for Perl modules and other Unix utilities.

=head1 Author

Andrew Speer <aspeer@cpan.org>

=head1 LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2016 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it underthe same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=cut