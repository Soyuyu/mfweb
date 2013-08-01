# mfweb

These scripts are a subset of the scripts I use for building
martinfowler.com. They are here on github to help with collaborating
with people who are writing articles for martinfowler.com. I have
made no effort to document them, or package them, for general use. You
are welcome to give them a spin if you so wish, but they will need
considerable hacking on them to make them usable outside the context
of my own website. I'm happy for that to be done, but it's not one of my
likely priorities.

## How to use these scripts

To make use of these scripts you need to create a project folder, put
some XML sources for web content you want to create into that folder,
link the folder to the scripts in this repo, and then execute a build
command on that folder.

That all sounds rather laborious, so I've provided a script that will
build such a project folder for you, together with some sample sources
that you can build into further documentation. To get all this going,
execute these commands.

    git clone https://github.com/martinfowler/mfweb.git
    cd mfweb
    ruby make-sample.rb ../sample
    cd ../sample
    rake
    rake server

You should now be able to point your browser to <http://localhost:2929/>
and see a self professed crude web page. This page is served out of `sample/build`

There's a good chance that things went pear-shaped when you executed
the `rake` command. This will probably be due to missing some
prerequisites. I still need to sort out making it easier to get the
dependencies. Until then I can say that you will need ruby 1.9 (I
install it and control the install with rbenv.) The Gemfile in the
repo indicates the necessary gems you need. (I should sort out a
gemfile in the generated project folder too.) To build the infodecks
you will also need to install coffeescript. The default rake tasks
assume this is the case, let me know if this is an issue and I'll try
to do something clever to avoid the need for coffeescript if you are
only working on articles.

If all goes well you add your own articles and infodecks to the sample
repo. You should not modify any of the files in mfweb unless you are
experimenting with patching mfweb itself and sending me a pull
request.

## What's in this repo

The top level folders are:

- `lib/mfweb/core` scripts required for most parts of the web site
- `lib/mfweb/article` scripts build regular prose articles
- `lib/mfweb/infodeck` scripts to build infodecks
- `sample` files for the sample directory
- `css` css files used for these parts of the web site.
- `test` some unit tests (see below)

## Digging in the Code

(This material needs to be moved into the documentation in the sample
repo and expanded)

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
