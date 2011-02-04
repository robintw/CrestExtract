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

FUNCTION RUN_COLLAPSE, binary_image, slope_image, gap
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
    
    return, binary
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

FUNCTION PRUNE, binary_image, n
  binary_image = binary_image GT 0

  hit1 = [ [0, 0, 0], [1, 1, 0], [0, 0, 0] ]
  hit2 = [ [0, 1, 0], [0, 1, 0], [0, 0, 0] ]
  hit3 = [ [0, 0, 0], [0, 1, 1], [0, 0, 0] ]
  hit4 = [ [0, 0, 0], [0, 1, 0], [0, 1, 0] ]
  
  hit5 = [ [1, 0, 0], [0, 1, 0], [0, 0, 0] ]
  hit6 = [ [0, 0, 1], [0, 1, 0], [0, 0, 0] ]
  hit7 = [ [0, 0, 0], [0, 1, 0], [0, 0, 1] ]
  hit8 = [ [0, 0, 0], [0, 1, 0], [1, 0, 0] ]
  
  miss1 = [ [0, 1, 1], [0, 0, 1], [0, 1, 1] ]
  miss2 = [ [0, 0, 0], [1, 0, 1], [1, 1, 1] ]
  miss3 = [ [1, 1, 0], [1, 0, 0], [1, 1, 0] ]
  miss4 = [ [1, 1, 1], [1, 0, 1], [0, 0, 0] ]
  
  miss5 = [ [0, 1, 1], [1, 0, 1], [1, 1, 1] ]
  miss6 = [ [1, 1, 0], [1, 0, 1], [1, 1, 1] ]
  miss7 = [ [1, 1, 1], [1, 0, 1], [1, 1, 0] ]
  miss8 = [ [1, 1, 1], [1, 0, 1], [0, 1, 1] ]
  
  input = binary_image
  
  FOR i = 0, n - 1 DO BEGIN
    ; Thin with structuring elements
    thinned = MORPH_THIN(input, hit1, miss1)
    thinned AND= MORPH_THIN(input, hit2, miss2)
    thinned AND= MORPH_THIN(input, hit3, miss3)
    thinned AND= MORPH_THIN(input, hit4, miss4)
    thinned AND= MORPH_THIN(input, hit5, miss5)
    thinned AND= MORPH_THIN(input, hit6, miss6)
    thinned AND= MORPH_THIN(input, hit7, miss7)
    thinned AND= MORPH_THIN(input, hit8, miss8)
    
    input = thinned
  ENDFOR
  
  ; Get end points
  endpoints = MORPH_HITORMISS(thinned, hit1, miss1)
  endpoints OR= MORPH_HITORMISS(thinned, hit2, miss2)
  endpoints OR= MORPH_HITORMISS(thinned, hit3, miss3)
  endpoints OR= MORPH_HITORMISS(thinned, hit4, miss4)
  endpoints OR= MORPH_HITORMISS(thinned, hit5, miss5)
  endpoints OR= MORPH_HITORMISS(thinned, hit6, miss6)
  endpoints OR= MORPH_HITORMISS(thinned, hit7, miss7)
  endpoints OR= MORPH_HITORMISS(thinned, hit8, miss8)
  
  ; Conditionally dilate
  dilated = endpoints
  FOR i = 0, n - 1 DO BEGIN
    dilated OR= DILATE(dilated, intarr(3, 3) + 1)
  ENDFOR
  
  ; Conditionalise it
  dilated = dilated AND binary_image
  
  ; Get final result
  output = thinned OR dilated
  ;IMAGE_TO_ENVI, output
  return, output
END

FUNCTION DILATE_AND_THIN, binary_image, dem_image, n, threshold, reps
  FOR i = 0, reps - 1 DO BEGIN
  ;res = MORPH_CLOSE(image, indgen(n, n) + 1)
  binary_image = DILATE(binary_image, indgen(n,n) + 1)
  binary_image = DILATE(binary_image, indgen(n,n) + 1)
  binary_image = THIN(binary_image)
  
  ; Remove any pixels where the DEM is less than a certain value
  indices = WHERE(dem_image LT 2, count)
  IF count GT 0 THEN binary_image[indices] = 0
  ENDFOR
  
  return, binary_image
END

FUNCTION GET_ENDPOINTS, image
  ; Create the hit element
  hit = intarr(3, 3)
  hit[1,1] = 1
  
  
  miss1 = [ [1, 0, 0], [1, 0, 1], [1, 1, 1] ]
  miss2 = [ [1, 1, 0], [1, 0, 0], [1, 1, 1] ]
  miss3 = [ [1, 1, 1], [1, 0, 0], [1, 1, 0] ]
  miss4 = [ [1, 1, 1], [1, 0, 1], [1, 0, 0] ]
  miss5 = [ [1, 1, 1], [1, 0, 1], [0, 0, 1] ]
  miss6 = [ [1, 1, 1], [0, 0, 1], [0, 1, 1] ]
  miss7 = [ [0, 1, 1], [0, 0, 1], [1, 1, 1] ]
  miss8 = [ [0, 0, 1], [1, 0, 1], [1, 1, 1] ]
  
  
  output = MORPH_HITORMISS(image, hit, miss1)
  output OR= MORPH_HITORMISS(image, hit, miss2)
  output OR= MORPH_HITORMISS(image, hit, miss3)
  output OR= MORPH_HITORMISS(image, hit, miss4)
  output OR= MORPH_HITORMISS(image, hit, miss5)
  output OR= MORPH_HITORMISS(image, hit, miss6)
  output OR= MORPH_HITORMISS(image, hit, miss7)
  output OR= MORPH_HITORMISS(image, hit, miss8)

  return, output
END
