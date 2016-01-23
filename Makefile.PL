use 5.006;
use strict;
use ExtUtils::MakeMaker;
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}
my %WriteMakefile=(
    NAME                => 'Docbook::Convert',
    VERSION_FROM        => 'lib/Docbook/Convert.pm',
    ABSTRACT_FROM       => 'lib/Docbook/Convert.pm',,
    EXE_FILES           => [
        'bin/docbook-convert',
        'bin/docbook2md',
        'bin/docbook2pod'
    ],
    LICENSE             => 'perl',
    AUTHOR              => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION	=> '5.006',
    PREREQ_PM           =>  {
        'Test::Simple'  =>  0.44,
        'XML::Twig'     =>  0,
        'Pod::Usage'    =>  0,
        'Getopt::Long'  =>  0,
    },
    META_MERGE => { 
        'meta-spec'     => {
            version     => 2
        },
        resources       => {
            homepage    => 'https://github.com/aspeer/Docbook-Convert',
            repository  => {
                type    => 'git',
                url     => 'https://github.com/aspeer/Docbook-Convert.git',
                web     => 'https://github.com/aspeer/Docbook-Convert'
            }
        }
    },
    'depend'            => {
        Makefile        => '$(VERSION_FROM)',
    },
    'dist'		=> {
	COMPRESS        =>  'gzip -9f',
	SUFFIX		=>  '.gz'
    },
);
my %MM_Compat=(
    '6.31'              => [q(LICENSE)],
    '6.46'              => [q(META_MERGE)],
    '6.48'              => [q(MIN_PERL_VERSION)],
    '6.52'              => [q(CONFIGURE_REQUIRES)],
    '6.5503'            => [q(BUILD_REQUIRES)],
    '6.64'              => [q(TEST_REQUIRES)],
);
while (my($mm_ver_test, $ar)=each %MM_Compat) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete @WriteMakefile{@{$ar}};
    }
}
WriteMakefile(%WriteMakefile);
package MY;
sub post_initialize {
    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE';
    $mm_or->SUPER::post_initialize;
};
