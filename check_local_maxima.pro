FUNCTION CHECK_LOCAL_MAXIMA, dem_image, ns, nl, length
  output = intarr(ns+1, nl+1)
  
  FOR x = 0, ns DO BEGIN
    FOR y = 0, nl DO BEGIN
      ; For each pixel in image
      ; Get the 5x5 local neighbourhood
      
      row = GET_LOCAL_LINE_HORIZ(length, x, y, dem_image)
      val = MAX(row, subscript)
      if subscript EQ ((length - 1) / 2) then output[x, y] += 5
      col = GET_LOCAL_LINE_VERT(length, x, y, dem_image)
      val = MAX(row, subscript)
      if subscript EQ ((length - 1) / 2) then output[x, y] += 1
    ENDFOR
  ENDFOR
  
  return, output
END