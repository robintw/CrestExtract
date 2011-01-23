FUNCTION GET_FITNESS_IMAGE, slope_image
  sh1 = SHIFT(slope_image, 1)
  sh2 = SHIFT(slope_image, 2)
  sh3 = SHIFT(slope_image, 3)
  
  fitness = sh1 + sh2 + sh3
 
  print, "Generated slope fitness image"
  return, fitness
END

PRO POST_PROCESS_GUI
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Slope"
  slope_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Binary"
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
  
  
  ; Do dilate and thin
  print, "Doing DILATE and THIN"
  
  return, binary
END

PRO DILATE_AND_THIN, n
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Binary Image"
  
  binary_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="DEM"
  
  dem_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  ;res = MORPH_CLOSE(image, indgen(n, n) + 1)
  binary_image = DILATE(binary_image, indgen(n,n) + 1)
  binary_image = DILATE(binary_image, indgen(n,n) + 1)
  binary_image = THIN(binary_image)
  
  IMAGE_TO_ENVI, binary_image
  
  ; Remove any pixels where the DEM is less than a certain value
  indices = WHERE(dem_image LT 2, count)
  IF count GT 0 THEN binary_image[indices] = 0
  
  ENVI_ENTER_DATA, binary_image
  
END

FUNCTION GET_ENDPOINTS, image
  ; Create the hit element
  hit = intarr(3, 3)
  hit[1,1] = 1
  
  ; Create the miss elements
  miss1 = [ [1, 0, 0], [1, 0, 1], [1, 1, 1] ]
  miss2 = [ [1, 1, 1], [1, 0, 0], [1, 1, 0] ]
  miss3 = [ [1, 1, 1], [1, 0, 1], [0, 0, 1] ]
  miss4 = [ [0, 1, 1], [0, 0, 1], [1, 1, 1] ]
  
  
  miss5 = [ [1, 1, 0], [1, 0, 0], [1, 1, 1] ]
  miss6 = [ [1, 1, 1], [1, 0, 1], [1, 0, 0] ]
  miss7 = [ [1, 1, 1], [0, 0, 1], [0, 1, 1] ]
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

PRO PRUNE
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Binary Image"
  
  binary_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  final_output = intarr(dims[2] + 1, dims[4] + 1)
    
  endpoints = GET_ENDPOINTS(binary_image)
  regions = LABEL_REGION(binary_image, /ALL_NEIGHBORS)

  indices = WHERE(endpoints GT 0, count)
  selected_pixels = regions[indices]
  
  hist = HISTOGRAM(selected_pixels, locations=locs)
  print, MAX(hist)
  indices = WHERE(hist GT 2, count, COMPLEMENT=comp)
  
  ok_regions = locs[comp]
  
  FOR k = 0, N_ELEMENTS(ok_regions) - 1 DO BEGIN
    region = ok_regions[k]
    
    copying_indices = WHERE(regions EQ region)
    
    final_output[copying_indices] = 1
  END
  
  IF count EQ 0 THEN RETURN
  regions_to_process = locs[indices]
  
  temp = intarr(dims[2] + 1, dims[4] + 1)
  
  
  FOR i = 0, N_ELEMENTS(regions_to_process) - 1 DO BEGIN
    print, "Processing region " + STRTRIM(STRING(i)) + " of " + STRTRIM(STRING(N_ELEMENTS(regions_to_process) - 1))
    
  
  
    region = regions_to_process[i]
    
    ; Clear the temp array
    temp[*,*] = 0
    
    ; Copy just this region into the temp array
    region_points = WHERE(regions EQ region)
    temp[region_points] = 1
    
    orig_temp = temp
    
    ;tvscl, temp
    
    ; Get the endpoints and their indices
    endpoint_image = GET_ENDPOINTS(temp)
    ;tvscl, endpoint_image
    endpoint_indices = WHERE(endpoint_image)
    
    IF N_ELEMENTS(endpoint_indices) EQ 2 THEN BEGIN
      print, "Indices = 2"
      continue
    ENDIF
    
    n = 0
    ; While there are more than two endpoints
    WHILE N_ELEMENTS(endpoint_indices) GT 2 DO BEGIN
      ; Blank these endpoints in the temp image
      temp[endpoint_indices] = 0
      
      ; Get the endpoint indices again
      endpoint_image = GET_ENDPOINTS(temp)
      endpoint_indices = WHERE(endpoint_image)
      n += 1
    ENDWHILE
    
    add = endpoint_image
    FOR j = 0, n - 1 DO BEGIN
      add = DILATE(add, intarr(3, 3) + 1)
      add = add AND orig_temp
    ENDFOR
    
    temp = temp OR add
    
    
    ; We should now have a pruned region in temp
    ; OR this with the final output image to include it there
    final_output = final_output OR temp
  ENDFOR
  
  IMAGE_TO_ENVI, final_output
END
