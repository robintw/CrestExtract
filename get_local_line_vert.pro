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