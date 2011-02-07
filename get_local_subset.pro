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