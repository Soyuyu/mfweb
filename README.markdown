# mfweb

These scripts are a subset of the scripts I use for building
martinfowler.com. They are here on github to help with collaborating
with people who are writing articles for martinfowler.com. I have
made no effort to document them, or package them, for general use. You
are welcome to give them a spin if you so wish, but they will need
considerable hacking on them to make them usable outside the context
of my own website. I'm happy for that to be done, but it's not one of my
likely priorities.

##Using the scripts

The top level folders are:

- `lib` contains the ruby scripts 
- `lib/mfweb/core` scripts required for various parts of the web site
- `lib/mfweb/article` scripts to turn article files into html
- `lib/mfweb/infodeck` scripts to build infodecks
- `sample` files to help build a sample directory (see below)
- `css` css files used for these parts of the web site.
- `test` some unit tests (see below)

My full web site contains many more scripts than this, I've just
pulled out those scripts required for collaboration.

You will need ruby 1.9 installed. The dependent gems
are all described with bundler and I use rbenv for the ruby version.
I run the scripts with ruby 1.9.3 and I don't think they will run any
more with 1.8.

To build the infodecks you will also need to install coffeescript. The
default rake tasks assume this is the case, let me know if this is an
issue and I'll try to do something clever to avoid the need for
coffeescript if you are only working on articles.

To make use of the files you'll need to create a sample directory that
links back to the mfweb libraries. I've included a script
`make-sample.rb` to make this easier. To use it run the command

    ruby make-sample.rb path/to/target

This will create a starting folder in the target directory. You can
then add new articles into the sample directory without worrying about
changes to the core files themselves. To build the web site use the
command `rake`, this will build the website into `target/build`. You
can use `rake server` to start a web server on this output directory.
The sample files include examples for simple articles, flexible
articles, and infodecks. The articles describe how to write articles using the
toolchain and are examples you can start with.

You can (and should) make a new repository for that folder which will
be independent of your clone of mfweb. You should not modify any of
the files in mfweb unless you are experimenting with patching mfweb
itself and sending me a pull request.

Note for code examples, the code can be auto-imported from any source
file. I find this very handy as I can put my actual source files, do
compiles and tests, and just use the comment annotations to mark bits
of code to incorporate into the text.

## Digging in the Code

If you want to dig around in the code that generates things, here's a
few signposts

The entry point for transforming an article xml file into html is
ArticleMaker (in `lib/mfweb/article`). Its task is to coordinate the various
objects that do most of the work. This is set up for each paper in the
rakefile.

First of these is the PageSkeleton, which you set up with the header,
footer, and css information. It writes these things out and hands over
to the PaperTransformer which actually does most of the work. (There
is also a PatternTransformer which is used for patterns done in my
template.)

The paper transformer is a subclass of transformer (in
`lib\mfweb\core`), which is a general class for transforming xml
documents into html. The transformer walks the tree of the xml
document. Most behavior is defined by creating methods named
handle_elementName for each element you want to do something with.
Handle methods usually do some specific things for that element and at
some point call `apply` which continues the walk down to the children.

Any html output is done through an instance of HtmlEmitter, present
through the instance variable `@html`. HtmlEmitter has a range of
methods to emit common html elements, together with general methods
`element_block` and `element_span` to spit out any named with elements
with or without surrounding newlines. You can also send raw output to
the HtmlEmitter with `<<`.

Although the handle_* methods give you the most control about
processing an XML element, there are some common cases that have short
cuts. The transformer parent class defines some lists `@ignore_set`,
`@copy_set`, `@p_set` and `@span_set` for these shortcut behaviors.

If you want to do some specialized transforming of some particular
element structure, it's often easiest to make your own transformer
subclass and call it during the tree walk. See how processing the
abstract in `handle_abstract` leads to calls into a separate
FrontMatterTransformer to print things like the table of contents and
author lists.

Various more complicated operations are done by separate service
objects which are defined on the PaperMaker which passes itself as a
service locator to the transformer. These include PatternServer (for
pattern reference lookups), CodeServer (for code extraction),
Bibliography (for citations), FootnoteServer (for footnotes).

There aren't many tests in here. These are limited since I have a fast and
simple functional test system (generate the entire web site, and diff
it with a known good output site.)
