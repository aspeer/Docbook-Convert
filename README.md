Docbook::Convert README

# 1 Docbook::Convert \- migrate Docbook article or refentry files to Markdown or POD #

This Perl module arose from the mixed results I had in migrating Docbook material to Markdown, and ftom there to POD using pandoc, rman and other existing tools. None of the toolchains produced the output I was after

# 2 Why ? #

I prefer to write documentation for man pages in Docbook using the XMLMind XXE editor. Its&#39; GUI interface for Docbook templates and formatting features work for me \- and I prefer editing documents in that environment rathet than native text file formats such as Markdown or POD.

However as rich as the Docbook toolset environment is there are no exitsting XSL stylesheets \- that I could find \- to convert Docbook to Markdown or POD. This module provides a facility to perform those conversions.

# 3 Why not write an XLS stylesheet and use XSLT ? #

After trying to get my head around the syntax of XSL stylesheets \- and failing miserably to produce any decent output using them \- I resorted to the &quot;if all you have is a hammer everything looks like a nail&quot; approach and do it with a Perl module \- which suited my competencies far better than XSL. 