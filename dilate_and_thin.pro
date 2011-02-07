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