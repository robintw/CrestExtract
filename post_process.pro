FUNCTION GET_FITNESS_IMAGE, slope_image
  sh1 = SHIFT(slope_image, 1)
  sh2 = SHIFT(slope_image, 2)
  sh3 = SHIFT(slope_image, 3)
  
  fitness = sh1 + sh2 + sh3
 
  print, "Generated slope fitness image"
  return, fitness
END

PRO POST_PROCESS_GUI
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  slope_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  binary_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  
  output = POST_PROCESS(slope_image, binary_image, 10)
  
  IMAGE_TO_ENVI, output
END

FUNCTION POST_PROCESS, slope_image, binary_image, gap
  ; Create two copies of the binary image to use in the processing below
  ; as the routine modifies the image provided to it
  horiz_binary = binary_image
  vert_binary = binary_image
  
  ; Get the fitness image by processing the slope image
  fitness = GET_FITNESS_IMAGE(slope_image)
  
  indices = WHERE(binary_image EQ 0, count)
  IF count GT 0 THEN fitness[indices] = 0
  
  ; Run the collapse routine in both directions
  collapse, fitness, horiz_binary, gap, 0, xmax, ymax
  
  collapse, fitness, vert_binary, 0, gap, xmax, ymax
  
  ; Combine the results
  binary = horiz_binary OR vert_binary
  
  print, "Finished collapsing"
  return, binary
END

