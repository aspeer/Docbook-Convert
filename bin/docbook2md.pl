#!/bin/perl
#
use strict qw(vars);
use lib qw(lib);
use vars qw($VERSION);



#  External modules
#
use IO::File;
use Getopt::Long;
use Pod::Usage;
use FindBin qw($RealBin $Script);
use File::Find;
use Cwd qw(cwd);
use Docbook::Convert;


#  Used for debugging only
#
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='0.001';


#  Run main routine
#
exit ${&main(&getopt(\@ARGV)) || die 'unknown error'};


#===================================================================================================

sub getopt {


    #  Parse options and dispatch to actual work routine below
    #
    my $argv_ar=shift();
    
    
    #  Get options
    #
    my %opt;


    #  Get command line options
    #
    GetOptions(
        \%opt,
        'help|?',
        'man',
        'version',
        'debug',
        'verbose',
        'dump',
        'dumprender',
        'warn_unknown_tag',
        'outfile|o=s',
        'infile=s@',
        'recurse|r',
        'recursedir|d=s',
        'xmlsuffix|x=s',
        'podsuffix|p=s',
        'markdown|md',
        'merge',
        'handler|h=s',
    ) || pod2usage(2);
    pod2usage(-verbose => 99, -sections => 'Synopsis|Options', -exitval => 1) if $opt{'help'};
    pod2usage(-verbose => 2) if $opt{'man'};
    $opt{'version'} && do {
        print "$Script version: $VERSION\n";
        exit 0
    };


    #  Get infile
    #
    unless (@{$opt{'infile'}}) {
        $opt{'infile'}=$argv_ar
    }


    #  Done
    #
    return \%opt;

}


sub main {

    #  Passed a list of options:
    #
    my $opt_hr=shift();
    $opt_hr->{'handler'} ||= 'markdown';
    foreach my $fn (@{$opt_hr->{'infile'}}) {
        print Docbook::Convert->process($fn, $opt_hr);
    }
    return \undef;
    
}

