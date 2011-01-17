PRO TEST_COLLAPSE
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  greyscale = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  binary = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  horiz_binary = binary
  vert_binary = binary
  
  
  collapse, greyscale, horiz_binary, 1, 0, xmax, ymax
  
  collapse, greyscale, vert_binary, 0, 1, xmax, ymax
  
  binary = horiz_binary OR vert_binary
  
  print, "Done"
  b = binary
  ENVI_ENTER_DATA, b
END