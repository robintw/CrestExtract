FUNCTION REMOVE_LOW_VALUES, fid, dims, pos, threshold
  WholeBand = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  indices = WHERE(WholeBand LT threshold)
  
  WholeBand[indices] = 0
  
  return, WholeBand
END

FUNCTION EXTRACT_FROM_ENVI_FILE
  ; Get file
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  
  ; Remove the low values from the input image to reduce noise
  thresholded = REMOVE_LOW_VALUES(fid, dims, pos, 1)
  ENVI_ENTER_DATA, thresholded, r_fid=thresholded_fid

  ; Create aspect image
  envi_doit, 'topo_doit', fid=thresholded_fid, pos=pos, dims=dims, $
    bptr=[1], /IN_MEMORY, pixel_size=[1,1], r_fid=aspect_fid
    
  ; Create slope image
  envi_doit, 'topo_doit', fid=thresholded_fid, pos=pos, dims=dims, $
    bptr=[0], /IN_MEMORY, pixel_size=[1,1], r_fid=slope_fid
    
  ; Run two low pass filters over the aspect image to remove noise
  envi_doit, 'conv_doit', fid=aspect_fid, dims=dims, pos=pos, kx=3, ky=3, method=3, $
    /IN_MEMORY, r_fid=LP1_fid
  envi_doit, 'conv_doit', fid=LP1_fid, dims=dims, pos=pos, kx=3, ky=3, method=3, $
    /IN_MEMORY, r_fid=LP2_fid
    
  crest_fid = EXTRACT_CRESTS_NEW(thresholded_fid, LP2_fid, slope_fid)
  
  return, crest_fid
END

FUNCTION EXTRACT_CRESTS_NEW, dem_fid, aspect_fid, slope_fid
  ; Get the dims of the file
  ENVI_FILE_QUERY, aspect_fid, dims=dims
  
  aspect_image = ENVI_GET_DATA(fid=aspect_fid, dims=dims, pos=0)
  slope_image = ENVI_GET_DATA(fid=slope_fid, dims=dims, pos=0)
  dem_image = ENVI_GET_DATA(fid=dem_fid, dims=dims, pos=0)
  
  ; Create the output image
  ns = dims[2]
  nl = dims[4]
  output = intarr(ns + 1, nl + 1)
  
  ; Set distances (in sizes variable) and weights for the local maxima and aspect change checking
  sizes = [10, 20, 50, 100]
  weights = [1, 2, 5, 10]

  FOR i = 0, N_ELEMENTS(sizes) - 1 DO BEGIN
    print, "Checking ", sizes[i]
    print, "Local maxima"
    output = output + (weights[i] * CHECK_LOCAL_MAXIMA(dem_image, ns, nl, sizes[i]))
    print, "Aspect change"
    output = output + (weights[i] * CHECK_ASPECT_CHANGE(aspect_image, ns, nl, sizes[i]))
  ENDFOR
    
  ; Remove anything that has crept in below the thresholds (eg. from aspect calcs)
  indices = WHERE(dem_image LT 1)
  output[indices] = 0
  
  print, "DONE!"
  o = output
  ENVI_ENTER_DATA, o
  return, output
END

FUNCTION GET_LOCAL_LINE_HORIZ, n, x, y, arr
  ; This gets the n long line around the given x and y values
  ; It will repeat edge values as needed to provide the correctly sized return array
  ; 
  ; Altered from http://michaelgalloy.com/2006/10/10/local-grid-points.html
  ; 
  ; Calculate the offsets
  offsets = lindgen(n) - (n - 1) / 2
  
  return, arr[x + offsets, y]
END

FUNCTION GET_LOCAL_LINE_VERT, n, x, y, arr
  ; This gets the n long line around the given x and y values
  ; It will repeat edge values as needed to provide the correctly sized return array
  ; 
  ; Altered from http://michaelgalloy.com/2006/10/10/local-grid-points.html
  ; 
  ; Calculate the offsets
  offsets = lindgen(n) - (n - 1) / 2
  
  return, reform(arr[x, y + offsets],n)
END

FUNCTION GET_LOCAL_SUBSET, n, x, y, arr
  ; This gets the local n x n window around the given x and y values
  ; It will repeat edge values as needed to provide the correctly sized return array
  ; 
  ; Altered from http://michaelgalloy.com/2006/10/10/local-grid-points.html
  ; 
  ; Calculate the offsets
  offsets = lindgen(n) - (n - 1) / 2
  
  ; Calculate the offsets from the given x and y values
  xoffsets = reform(rebin(offsets, n, n), n^2)
  yoffsets = reform(rebin(offsets, n^2), n^2)
  
  return, reform(arr[x + xoffsets, y + yoffsets],n,n)
END

FUNCTION CHECK_LOCAL_MAXIMA, dem_image, ns, nl, length
  output = intarr(ns+1, nl+1)
  
  FOR x = 0, ns DO BEGIN
    FOR y = 0, nl DO BEGIN
      ; For each pixel in image
      ; Get the 5x5 local neighbourhood
      
      row = GET_LOCAL_LINE_HORIZ(length, x, y, dem_image)
      val = MAX(row, subscript)
      if subscript EQ ((length - 1) / 2) then output[x, y] += 1
      col = GET_LOCAL_LINE_VERT(length, x, y, dem_image)
      val = MAX(row, subscript)
      if subscript EQ ((length - 1) / 2) then output[x, y] += 1
    ENDFOR
  ENDFOR
  
  return, output
END

FUNCTION CHECK_SLOPE_ANGLE, slope_image, ns, nl, distance
  output = intarr(ns+1, nl+1)
  
  FOR x = 0, ns DO BEGIN
    FOR y = 0, nl DO BEGIN
      ; For each pixel in image
      ; Get the local line of the specified size
      line = GET_LOCAL_LINE(distance, x, y, slope_image)
      
      len = N_ELEMENTS(line)
      
      section_len = (len - 1) / 2
      
      ; Get the left-hand-side of the line and the right-hand-side
      LHS = line[0:section_len - 1]
      RHS = line[section_len + 1: len - 1]
      
      res = WHERE(LHS GT 180, LHS_count)
      res = WHERE(RHS LT 180, RHS_count)
      
      IF LHS_count EQ 0 AND RHS_count EQ 0 THEN output[x, y] += 1
      
      res = WHERE(LHS LT 180, LHS_count)
      res = WHERE(RHS GT 180, RHS_count)
      
      IF LHS_count EQ 0 AND RHS_count EQ 0 THEN output[x, y] += 1
      
    ENDFOR
  ENDFOR
  
  return, output
END

FUNCTION CHECK_ASPECT_CHANGE, aspect_image, ns, nl, distance
  output = intarr(ns+1, nl+1)
  
  FOR x = 0, ns DO BEGIN
    FOR y = 0, nl DO BEGIN
      ; For each pixel in image
      hline = GET_LOCAL_LINE_HORIZ(distance, x, y, aspect_image)
      vline = GET_LOCAL_LINE_VERT(distance, x, y, aspect_image)
      
      lines = [ [hline],[vline] ] 
      
      FOR i = 0, 1 DO BEGIN
      line = lines[*,i]
      len = N_ELEMENTS(line)
      
      section_len = (len - 1) / 2
      
      ;LHS = line[0:section_len - 1]
      ;RHS = line[section_len + 1: len - 1]
      
      
      ; Faster (and more concise) way of doing:
      ; Split the line into a LHS and a RHS
      ; Check each side to make sure no values are greater than/less than the thresholds
      IF (MAX(line[0:section_len - 1]) LE 180) AND (MIN(line[section_len + 1: len - 1]) GE 180) THEN output[x,y] += 1
      IF (MAX(line[0:section_len - 1]) GE 180) AND (MIN(line[section_len + 1: len - 1]) LE 180) THEN output[x,y] += 1
      ENDFOR
    ENDFOR
  ENDFOR
  
  return, output
END

