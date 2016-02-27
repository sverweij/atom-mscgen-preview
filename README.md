# Atom MscGen Preview package

Shows the rendered sequence chart of the MscGen to the right of the current editor when you press `ctrl-shift-G`. 

Enabled for `.mscgen`, `.msc`, `.mscin`, `.xu`, and `.msgenny` files

![animated gif demoing live preview of a simple sequence chart](https://raw.githubusercontent.com/sverweij/atom-mscgen-preview/master/assets/atom-mscgen-preview.gif)

## Features
- **syntax highlighting** from the [language-mscgen](https://atom.io/packages/language-mscgen) package - so no need to install that separately.
- **realtime rendering** of your sequence chart
- **SVG export** - to file or clipboard
- **PNG export** - to file
- Uses the pure javascript **[mscgen_js](https://github.com/sverweij/mscgen_js)** package for parsing and rendering, so apart from **MscGen** (`*.mscgen`, `*.mscin`, `*.msc`) it supports
  - **Xù** (`*.xu`)    
    A little language that adds things like `alt` and `loop` to MscGen.
    See the [Xù wiki page](https://github.com/sverweij/mscgen_js/blob/master/wikum/xu.md)
    for more information.
  - **MsGenny** (`*.msgenny`)    
    Xù with a simplified syntax. And a little less features. The
    [MsGenny wiki page](https://github.com/sverweij/mscgen_js/blob/master/wikum/msgenny.md)
    has more information.
- Frictionless conversion MscGen/ Xù <=> MsGenny    
  - Check the editor context menu for
    - `MsGenny -> MscGen/ Xù`,
    - `MscGen -> MsGenny` and
    - `Xù -> MsGenny`
  - or use `Mscgen Preview: Translate` in the command palette.


## License information
This software is free software [licensed under GPL-3.0](LICENSE.md). This means (a.o.) you _can_ use
it as part of other free software, but _not_ as part of non free software.

## Build status
[![Build Status](https://travis-ci.org/sverweij/atom-mscgen-preview.svg?branch=master)](https://travis-ci.org/sverweij/atom-mscgen-preview)
[![Code Climate](https://codeclimate.com/github/sverweij/atom-mscgen-preview/badges/gpa.svg)](https://codeclimate.com/github/sverweij/atom-mscgen-preview)
[![Dependency Status](https://david-dm.org/sverweij/atom-mscgen-preview.svg)](https://david-dm.org/sverweij/atom-mscgen-preview)
[![devDependency Status](https://david-dm.org/sverweij/atom-mscgen-preview/dev-status.svg)](https://david-dm.org/sverweij/atom-mscgen-preview#info=devDependencies)
