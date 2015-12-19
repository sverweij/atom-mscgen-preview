# Some notes on the use of canvg in mscgen-preview
## What's this?
[canvg](https://github.com/gabelerner/canvg) is a javascript library that takes
care of rendering vector graphics on canvasses. That's useful because it enables
mscgen-preview to save the rendered sequence charts as raster graphics (png).

## Why is it here and not as a dependency in the package.json?
- canvg currently is not available as an npm module.
- Directly loading from GitHub in package.json is possible, but I'm not confident
  it'd work well enough with upgrades (e.g. npm outdated just reports 'git'
  as the version even when you've attached a tag or commit-hash...). Especially
  not on end-user machines, where atom is running.
- Loading it through bower is possible as well (install bower as a dependency
  & run  bower install as a post install step) but adds undue complexity.
- There's a little change needed to make it run in node / atom (see below).

## The png to svg conversion situation

### So why pick canvg?
Despite the drawbacks it is the only working, feature-complete-enough
svg -> png solution out there I could find.

### alternatives
- [kangax/fabric.js](https://github.com/kangax/fabric.js)    
  - `+`
    - looks promising (unit tests, modular)
    - decent sized community, low bus factor.
  - `-`
    -  Not ready to be used with sequence charts as mscgenjs
       produces them.  See [issue
       #214](https://github.com/sverweij/mscgen_js/issues/214) in the
       mscgen_js (on line interpreter) repo.
    -  The node module uses [Automattic/node-canvas](https://github.com/Automattic/node-canvas)
       which is probably excelent, but also needs cairo to be installed. Which
       is a bit much to ask if you're just installing an Atom package that's
       supposed to work out of the box.
- Take the phantomjs route  
  Either 'roll your own' or use one of the many svg -> png modules available
  on npm. It _is_ the route I will take when canvg dies.
  - `+`
    - Works
    - Proven
  - `-`
    - Performance: phantomjs has a fixed overhead. On my (admittedly old)
      machine it's more than a second.
    - Download size - phantom is about 10Mb
    - Atom already has a full fledged DOM at its disposal. Having a separate
      browser do rendering just doesn't feel right.


## Changes made to the canvg 1.4 distribution
In canvg lines 18-22 try to load the rgbcolor and StackBlur modules in a fashion
meant to work with browserify:

```javascript
// ...or as browserify
else if ( typeof module !== 'undefined' && module.exports ) {
    module.exports = factory( require( 'rgbcolor' ), require( 'StackBlur' ) );
}
```

This code also runs in CommonJS, but as the module names don't start with './'
CommonJS implementations will attempt to load them from   `node_modules` and/ or
some system location. Which fails because they ain't there. Adding './' fixes
that.

```javascript
// ...or as browserify
else if ( typeof module !== 'undefined' && module.exports ) {
    module.exports = factory( require( './rgbcolor' ), require( './StackBlur' ) );
}
```

### So why not issue PR's?
I might do that as well, but at this time (December 2015) the last commit in the
canvg repo is from July. Chances of PR's being integrated quick enough to
coincide with a next mscgen-preview release look slim...
