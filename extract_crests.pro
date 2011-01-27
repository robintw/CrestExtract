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

FUNCTION EXTRACT_CRESTS, dem_fid, aspect_fid, slope_fid, dem_threshold
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
  sizes = [20, 50, 100]
  aspect_weights = [4, 20, 40]
  maxima_weights = [2, 10, 20]
  
  t1 = SYSTIME(/seconds)
  
  FOR i = 0, N_ELEMENTS(sizes) - 1 DO BEGIN
    print, "Checking ", sizes[i]
    print, "Local maxima"
    output = output + (maxima_weights[i] * CHECK_LOCAL_MAXIMA(dem_image, ns, nl, sizes[i]))
    print, "Aspect change"
    output = output + (aspect_weights[i] * CHECK_ASPECT_CHANGE(aspect_image, ns, nl, sizes[i]))
  ENDFOR
  
  t2 = SYSTIME(/seconds)
  
  ; Remove anything that has crept in below the thresholds (eg. from aspect calcs)
  indices = WHERE(dem_image LT dem_threshold, count)
  IF count GT 0 THEN output[indices] = 0
  
  print, "Finished initial crest extraction"
  print, "Time taken (in seconds): ", t2 - t1
  return, output
END