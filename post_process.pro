FUNCTION GET_FITNESS_IMAGE, slope_image
  sh1 = SHIFT(slope_image, 1)
  sh2 = SHIFT(slope_image, 2)
  sh3 = SHIFT(slope_image, 3)
  
  fitness = sh1 + sh2 + sh3
 
  return, fitness
END

PRO POST_PROCESS_GUI
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Slope"
  slope_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="DEM"
  dem_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Binary"
  binary_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  
  output = POST_PROCESS(slope_image, dem_image, binary_image, 10)
  
  IMAGE_TO_ENVI, output
END

FUNCTION POST_PROCESS, slope_image, dem_image, binary_image, gap, d_and_t_size, dem_threshold, d_and_t_repeats, prune_length, do_collapse  
  IF do_collapse EQ 1 THEN BEGIN
    binary = RUN_COLLAPSE(binary_image, slope_image, gap)
    print, "-- Finished collapsing"
  ENDIF ELSE BEGIN
    binary = binary_image
  ENDELSE
  
  IMAGE_TO_ENVI, binary
  
  ; Do dilate and thin
  binary = DILATE_AND_THIN(binary, dem_image, d_and_t_size, dem_threshold, d_and_t_repeats)
  IMAGE_TO_ENVI, binary
  binary = PRUNE(binary, prune_length)
  IMAGE_TO_ENVI, binary
  binary = DILATE_AND_THIN(binary, dem_image, d_and_t_size, dem_threshold, d_and_t_repeats)  
  IMAGE_TO_ENVI, binary
  
  binary = PRUNE(binary, prune_length)
  print, "-- Finished dilating, thinning and pruning"
  
  return, binary
END