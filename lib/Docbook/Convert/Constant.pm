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


#  Package Constants
#
package Docbook::Convert::Constant;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);    ## no critic
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(abs_path);
use Data::Dumper;


#  Data Dumper formatting
#
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#===================================================================================================


#  Get module file name and path, derive name of file where local constants stored. e.g.
#  <perl lib>/Package/Constant.local will override anything in Constant.pm
#
my $module_fn=abs_path(__FILE__);
my $constant_local_fn="${module_fn}.local";


#  Constants
#  <<<
%Constant=(

    #  XML Data array index locations
    #
    NODE_IX => 0,
    CHLD_IX => 1,
    ATTR_IX => 2,
    LINE_IX => 3,
    COLM_IX => 4,
    PRNT_IX => 5,


    #  Handler nicknames
    #
    HANDLER_HR => {

        markdown        => 'Docbook::Convert::Markdown',
        md              => 'Docbook::Convert::Markdown',
        pod             => 'Docbook::Convert::POD'

    },


    #  Default handler
    #
    HANDLER_DEFAULT => 'markdown',


    #  Markdown separators
    #
    CR   => $/,
    CR2  => $/ x 2,
    SP   => ' ',
    SP4  => ' ' x 4,
    SP8  => ' ' x 8,
    NULL => \undef,
    
    
    #  Don't escape the following Docbook tags in Markdown converter
    #
    MD_DONT_ESCAPE_AR => [qw(
        command
        screen
        arg
        markup
        programlisting
        term
    )],
    
    
    #  Adminition Text
    #
    ADMONITION_TEXT_HR  => {
        note            => 'NOTE',
        warning         => 'WARNING',
        caution         => 'CAUTION',
        tip             => 'TIP',
        important       => 'IMPORTANT'
    },
    
    
    #  Refentry Text
    #
    REFENTRY_TEXT_HR    => {
        synoposis       => 'SYNOPSIS',
        name            => 'NAME'
    },
    
    
    #  Tag synonyms for Markdown
    #
    MD_TAG_SYNONYM_HR => {
        _text   => [qw(replaceable)]
    },
    
    
    #  Tag synonym for POD
    #
    POD_TAG_SYNONYM_HR  => {
        screen => [qw(programlisting)],
        _text  => [qw(blockquote)],
    },
    
    
    #  Common tag synonyms
    #
    ALL_TAG_SYNONYM_HR   => {
        command    => [qw(classname parameter filename markup)],
        sect1      => [qw(section)],
        refsection => [qw(refsect1)],
        para       => [qw(simpara)],
        warning    => [qw(caution important note tip)],
        #figure     => [qw(screenshot)],
        article    => [qw(refentry)],
        _text      => [qw(literallayout orgname firstname surname)],
        _data      => [qw(imageobject)],
        _null      => [qw(refentryinfo articleinfo)],
        _meta      => [qw(author affiliation pubdate address copyright)]
    },
    
    
    #  Delay render of mediaobject tag if any of these in parent - potentially
    #  allows more info to be build into image
    #
    MEDIAOBJECT_DELAY_RENDER_AR => [
        qw(figure)
    ],
    
    
    #  Metadata render options
    #
    META_DISPLAY_TOP            => 0,
    META_DISPLAY_BOTTOM         => 0,
    META_DISPLAY_TITLE          => undef,
    META_DISPLAY_TITLE_H_STYLE  => 'h2',
    
    
    #  Default formatting/output options
    #
    NO_HTML             => 0,
    NO_IMAGE_FETCH      => 0,
    NO_WARN_UNHANDLED   => 0,
    XMLSUFFIX           => '.xml',
    VERBOSE             => 0,
    

    #  Constants that can be set via getopt
    #
    GETOPT_CONSTANT_HR          => {
        meta_display_top                => undef,
        meta_display_bottom             => undef,
        meta_display_title              => '=s',
        meta_disaply_title_h_style      => '=s',
        no_html                         => undef,
        no_image_fetch                  => undef,
        no_warn_unhandled               => undef,
        xmlsuffix                       => '|x=s',
        verbose                         => '|v',
    },
    
    
    #  Other options
    #
    GETOPT_AR                   => [(
        'help|?',
        'man',
        'version|V',
        'dump',
        'dumpopt',
        'outfile|out|o=s',
        'infile|in|f=s@',
        'recurse|r',
        'recursedir|d=s',
        'markdown|md',
        'pod|pod',
        'merge',
        'no_warn_unhandled|silent|quiet|s|q',
        'handler|h=s'
    )],


    #  Local constants override anything above
    #
    %{do($constant_local_fn)}

);

#  >>>


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA=qw(Exporter);
foreach (keys %Constant) {${$_}=defined $ENV{$_} ? $Constant{$_}=eval($ENV{$_}) || $ENV{$_} : $Constant{$_}}    ## no critic
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
1;

