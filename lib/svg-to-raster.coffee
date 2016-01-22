exports.transform = (pSVG, pRasterType='png') ->
  # create an (undisplayed) canvas
  lCanvas = document.createElement 'canvas'
  lCanvas.setAttribute 'style', 'display:none'
  document.body.appendChild lCanvas
  lCanvasContext = lCanvas.getContext("2d")

  # create an (undisplayed) image
  lImg = document.createElement 'img'
  lImg.setAttribute 'style', 'display:none'
  document.body.appendChild lImg

  # set the svg as the source attribute
  lImg.setAttribute 'src', 'data:image/svg+xml;charset=utf-8,' + pSVG

  # resize the canvas to the size of the image
  lCanvas.width  = lImg.width
  lCanvas.height = lImg.height

  # ... and draw it on the canvas
  lCanvasContext.drawImage lImg, 0, 0

  # smurf the data url of the canvas
  lDataURL = lCanvas.toDataURL pRasterType, 0.8

  # remove the canvas now it's not needed anymore
  document.body.removeChild lImg
  document.body.removeChild lCanvas

  # extract the base64 encoded image, decode and return it
  new Buffer(lDataURL.replace('data:image/png;base64,', ''), 'base64')
