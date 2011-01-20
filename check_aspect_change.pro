FUNCTION CHECK_ASPECT_CHANGE, aspect_image, ns, nl, distance
  output = intarr(ns+1, nl+1)
  
  FOR x = 0, ns DO BEGIN
    FOR y = 0, nl DO BEGIN
      ; For each pixel in image
      hline = GET_LOCAL_LINE_HORIZ(distance, x, y, aspect_image)
      vline = GET_LOCAL_LINE_VERT(distance, x, y, aspect_image)
      lines = [ [hline],[vline] ] 
      weights = [5, 1]
      
      FOR i = 0, 1 DO BEGIN
      line = lines[*,i]
      len = N_ELEMENTS(line)
      
      section_len = (len - 1) / 2
      
      LHS = line[0:section_len - 1]
      RHS = line[section_len + 1: len - 1]
      
      IF ARRAY_EQUAL(LHS GT 180, 0) && array_equal(RHS LT 180, 0) THEN output[x, y] += (1 * weights[i])
      
      IF ARRAY_EQUAL(RHS GT 180, 0) && array_equal(LHS LT 180, 0) THEN output[x, y] += (1 * weights[i])
      
;      res = WHERE(LHS GT 180, LHS_count)
;      res = WHERE(RHS LT 180, RHS_count)
;      
;      IF LHS_count EQ 0 AND RHS_count EQ 0 THEN output[x, y] += (1 * weights[i])
;      
;      res = WHERE(LHS LT 180, LHS_count)
;      res = WHERE(RHS GT 180, RHS_count)
;      
;      IF LHS_count EQ 0 AND RHS_count EQ 0 THEN output[x, y] += (1 * weights[i])
      ENDFOR
    ENDFOR
  ENDFOR
  
  return, output
END