exports.transform = (pSVG, pRasterType='png') ->
  # create an (undisplayed) image
  lImg = document.createElement 'img'

  # set the svg as the source attribute
  # It seems this happens synchronously, so in theory the canvas creation
  # and drawing might have started before the image is loaded. However,
  # in chrome/ electron/ atom I've never seen problems with this.
  # When this happens the obvious approach is to use a callback or promise
  # approach. See https://github.com/sverweij/mscgen_js/blob/master/src/script/interpreter/raster-exporter.js
  # for an example.
  lImg.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent pSVG

  # create an (undisplayed) canvas
  lCanvas = document.createElement 'canvas'

  # resize the canvas to the size of the image
  lCanvas.width  = lImg.width
  lCanvas.height = lImg.height

  # ... and draw the image on there
  lCanvas.getContext('2d').drawImage lImg, 0, 0

  # smurf the data url of the canvas
  lDataURL = lCanvas.toDataURL pRasterType, 0.8

  # extract the base64 encoded image, decode and return it
  new Buffer(lDataURL.replace('data:image/png;base64,', ''), 'base64')
