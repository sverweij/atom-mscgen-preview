exports.transform = (pSVG, pRasterType='png') ->
  # create an (undisplayed) image
  lImg = document.createElement 'img'

  # set the svg as the source attribute
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
