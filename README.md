Docbook::Convert README

# 1 Docbook::Convert \- migrate Docbook files to Markdown or POD #

This Perl module arose from the mixed results I had in migrating Docbook material to Markdown \- and from there to POD \- using pandoc, rman and other existing tools. None of the toolchains produced the output I was after.

# 2 Why use XML for documentation ? #

I prefer to write documentation for man pages in Docbook using the XMLMind XXE editor. It has Docbook templates and formatting features that allow for quick and easy creation of man pacges, articles etc. Additionally the XXE editor shows formatting in realtime allowing for a more complete sense of what the document will look like when finished.

However I could not find toolsets which gave satisfactory results when converting Docbook to Markdown or POD. This module provides a facility to perform those conversions.

# 3 Why not write an XLS stylesheet and use XSLT ? #

After trying to get my head around the syntax of XSL stylesheets \- and failing miserably to produce any decent output using them \- I resorted to the &quot;if all you have is a hammer everything looks like a nail&quot; approach and do it with a Perl module \- which suited my competencies far better than XSL.

# 4 Installation #

The latest code will always be on GitHub. Install via the following commands:

    git clone https://github.com/aspeer/pm-Docbook-Convert.git
    cd pm-Docbook-Convert
    
    # If on a modern system
    cpan .
    
    # Or
    cpanm .
    
    # Failing that
    perl Makefile.PL
    make
    make test
    make install

# 5 Usage #

For full usage instructions see the man page. A quick example:

    #  Convert to markdown
    #
    docbook2md manpage.xml > manpage.md
    
    #  Convert to POD
    #
    docbook2pod manpage.xml > manpage.pod

# 6 Dependencies #

Docbook::Convert depends heavily on XML::Twig and some other modules. All dependencies are listed in the Makefile.PL and will be installed automaticlly assuming Internet connectivity.

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2017 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

