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