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
  dims = SIZE(image, /DIMENSIONS)
  help, image
  output = intarr(dims[0], dims[1])
  help, output
  
  kernel = intarr(3, 3) + 1
  
  res = CONVOL(image, kernel, /center, /edge_truncate)
  
  indices = WHERE(image EQ 0, count)
  print, count
  IF count GT 0 THEN res[indices] = 0
  
 
  indices = WHERE(res EQ 4, count)
  IF count GT 0 THEN output[indices] = 1
  
  return, output
END

PRO PRUNE
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Binary Image"
  
  binary_image = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  help, binary_image
  
  endpoints = GET_ENDPOINTS(binary_image)
  regions = LABEL_REGION(binary_image, /ALL_NEIGHBORS)
  
  IMAGE_TO_ENVI, regions
  
  help, regions
  help, endpoints
  
  IMAGE_TO_ENVI, endpoints
  
  indices = WHERE(endpoints GT 0, count)
  selected_pixels = regions[indices]
  
  hist = HISTOGRAM(selected_pixels, locations=locs)
  print, MAX(hist)
  indices = WHERE(hist GT 2, count)
  IF count EQ 0 THEN RETURN
  regions_to_process = locs[indices]
  
  help, locs
  help, regions_to_process
  
  print, regions_to_process
END
