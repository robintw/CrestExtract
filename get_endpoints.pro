FUNCTION GET_ENDPOINTS, image
  ; Create the hit element
  hit = intarr(3, 3)
  hit[1,1] = 1
  
  
  miss1 = [ [1, 0, 0], [1, 0, 1], [1, 1, 1] ]
  miss2 = [ [1, 1, 0], [1, 0, 0], [1, 1, 1] ]
  miss3 = [ [1, 1, 1], [1, 0, 0], [1, 1, 0] ]
  miss4 = [ [1, 1, 1], [1, 0, 1], [1, 0, 0] ]
  miss5 = [ [1, 1, 1], [1, 0, 1], [0, 0, 1] ]
  miss6 = [ [1, 1, 1], [0, 0, 1], [0, 1, 1] ]
  miss7 = [ [0, 1, 1], [0, 0, 1], [1, 1, 1] ]
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