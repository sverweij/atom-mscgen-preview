canvg = null

exports.transform = (pSVG, pRasterType='png') ->
  canvg ?= require './canvg/canvg'

  # create an (undisplayed) canvas
  lCanvas = document.createElement 'canvas'
  lCanvas.setAttribute 'style', 'display:none'
  document.body.appendChild lCanvas

  # use canvg to render the svg
  canvg lCanvas, pSVG

  # smurf the data url of the canvas
  lDataURL = lCanvas.toDataURL pRasterType, 0.8

  # remove the canvas now it's not needed anymore
  document.body.removeChild lCanvas

  # extract the base64 encoded image, decode and return it
  new Buffer(lDataURL.replace('data:image/png;base64,', ''), 'base64')
