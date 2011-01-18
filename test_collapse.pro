PRO TEST_COLLAPSE
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  slope = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  binary = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  horiz_binary = binary
  vert_binary = binary
  
  ; Get the fitness image by processing the slope image
  fitness = GET_FITNESS_IMAGE(slope)
  
  indices = WHERE(binary EQ 0, count)
  IF count THEN fitness[indices] = 0
  
  
  collapse, fitness, horiz_binary, 1, 0, xmax, ymax
  
  collapse, fitness, vert_binary, 0, 1, xmax, ymax
  
  binary = horiz_binary OR vert_binary
  
  print, "Done"
  b = binary
  ENVI_ENTER_DATA, b
END

FUNCTION GET_FITNESS_IMAGE, slope_image
  sh1 = SHIFT(slope_image, 1)
  sh2 = SHIFT(slope_image, 2)
  sh3 = SHIFT(slope_image, 3)
  
  fitness = sh1 + sh2 + sh3
  
  f = fitness
  ENVI_ENTER_DATA, f
  
  return, fitness
END