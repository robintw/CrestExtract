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
  thresholded = REMOVE_LOW_VALUES(fid, dims, pos, 2)
  ENVI_ENTER_DATA, thresholded, r_fid=thresholded_fid

  ; Create aspect image
  envi_doit, 'topo_doit', fid=thresholded_fid, pos=pos, dims=dims, $
    bptr=[1], /IN_MEMORY, pixel_size=[1,1], r_fid=aspect_fid
    
  ; Run two low pass filters over the aspect image to remove noise
  envi_doit, 'conv_doit', fid=aspect_fid, dims=dims, pos=pos, kx=3, ky=3, method=3, $
    /IN_MEMORY, r_fid=LP1_fid
  envi_doit, 'conv_doit', fid=LP1_fid, dims=dims, pos=pos, kx=3, ky=3, method=3, $
    /IN_MEMORY, r_fid=LP2_fid
    
  crest_fid = EXTRACT_CRESTS(fid, LP2_fid)
  
  return, crest_fid
END

FUNCTION BINARY_COUNT, array
  dims = SIZE(array, /dimensions)
  
  indices = where(array GT 0)
  bin = intarr(dims[0], dims[1])
  bin[indices] = 1
  
  return, bin
END

FUNCTION ARRAY_SUBSET, array, x, y
  dims = SIZE(array, /dimensions)
  
  x += 1
  y += 1
  
  left = x - 1
  right = x + 1
  
  top = y - 1
  bottom = y + 1
  
;  if left LT 0 THEN left = 0
;  if right GT dims[0]-1 THEN right = dims[0]-1
;  
;  if top LT 0 THEN top = 0
;  if bottom GT dims[1]-1 THEN bottom = dims[1]-1

  col_zeros = intarr(1, dims[1])
  row_zeros = intarr(dims[0] + 2)

  mod_array = [ col_zeros, array, col_zeros ]
  mod_array = [ [row_zeros], [mod_array], [row_zeros] ]
  
  ;print, mod_array
  
  return, mod_array[left:right, top:bottom]
END

FUNCTION POST_PROCESS, output
  ; A  B  C
  ; D  E  F
  ; G  H  I
  A = DO_CONVOL(0, 0, output)
  B = DO_CONVOL(1, 0, output)
  C = DO_CONVOL(2, 0, output)
  D = DO_CONVOL(0, 1, output)
  E = DO_CONVOL(1, 1, output)
  F = DO_CONVOL(2, 1, output)
  G = DO_CONVOL(0, 2, output)
  H = DO_CONVOL(1, 2, output)
  I = DO_CONVOL(2, 2, output)
  
  count = BINARY_COUNT(A) + BINARY_COUNT(B) + BINARY_COUNT(C) + BINARY_COUNT(D) + BINARY_COUNT(F) + BINARY_COUNT(G) + BINARY_COUNT(H) + BINARY_COUNT(I)
  
  ; Rule 1: If there are zero neighbours then remove the point
  indices = WHERE(count EQ 0)
  output[indices] = 0
  
  ; Rule 2: If there is 1 neighbour then find the best pixel to fill the gap, and fill it
  indices = WHERE(count EQ 0)
  
  FOR i = long(0), N_ELEMENTS(indices) - 1 DO BEGIN
    ; For each index found with one neighbour
    
    ; Get the two array indices
    index = ARRAY_INDICES(A, indices[i])
    
    subset = ARRAY_SUBSET(output, index[0], index[1])
    
    print, subset
    
    help, subset
  ENDFOR
  
;;  ; For each row
;  FOR row = 0, nl - 1 DO BEGIN
;  ; For each column
;  FOR column = 0, ns - 1 DO BEGIN
;    ; A  B  C
;    ; D  E  F
;    ; G  H  I
;    if count_cardinals[column, row] EQ 1 THEN BEGIN
;      IF binB[column, row] EQ 1 THEN BEGIN
;        IF D[column, row] GT F[column,row] AND D[column, row] GT H[column,row] THEN output[column-1,row] = 100
;        IF H[column, row] GT F[column,row] AND H[column, row] GT D[column,row] THEN output[column,row-1] = 100
;        IF F[column, row] GT H[column,row] AND F[column, row] GT D[column,row] THEN output[column+1,row] = 100
;      ENDIF
;    ENDIF
;  ENDFOR
;  ENDFOR

  return, output
END

FUNCTION EXTRACT_CRESTS, dem_fid, aspect_fid
  ; Get the dims of the file
  ENVI_FILE_QUERY, aspect_fid, dims=dims
  
  ; Get the data into an array called image
  aspect_image = ENVI_GET_DATA(fid=aspect_fid, dims=dims, pos=0)
  dem_image = ENVI_GET_DATA(fid=dem_fid, dims=dims, pos=0)

  ns = dims[2]
  nl = dims[4]

  output = intarr(ns, nl)

; Get the individual cell from top left, top middle etc as below
  ; A  B  C
  ; D  E  F
  ; G  H  I

  A = DO_CONVOL(0, 0, aspect_image)
  B = DO_CONVOL(1, 0, aspect_image)
  C = DO_CONVOL(2, 0, aspect_image)
  D = DO_CONVOL(0, 1, aspect_image)
  E = DO_CONVOL(1, 1, aspect_image)
  F = DO_CONVOL(2, 1, aspect_image)
  G = DO_CONVOL(0, 2, aspect_image)
  H = DO_CONVOL(1, 2, aspect_image)
  I = DO_CONVOL(2, 2, aspect_image)
  
  DEM_A = DO_CONVOL(0, 0, dem_image)
  DEM_B = DO_CONVOL(1, 0, dem_image)
  DEM_C = DO_CONVOL(2, 0, dem_image)
  DEM_D = DO_CONVOL(0, 1, dem_image)
  DEM_E = DO_CONVOL(1, 1, dem_image)
  DEM_F = DO_CONVOL(2, 1, dem_image)
  DEM_G = DO_CONVOL(0, 2, dem_image)
  DEM_H = DO_CONVOL(1, 2, dem_image)
  DEM_I = DO_CONVOL(2, 2, dem_image)
  
  print, "Done first CONVOLS"
  
  ; For each row
  FOR row = 0, nl - 1 DO BEGIN
  ; For each column
  FOR column = 0, ns - 1 DO BEGIN
    ; A  B  C
    ; D  E  F
    ; G  H  I
  
  ;;;; Aspect-based
  
  ;Do cardinal directions first
  IF D[column, row] GT 180 AND F[column, row] LT 180 THEN output[column, row] += 1
  IF F[column, row] GT 180 AND D[column, row] LT 180 THEN output[column, row] += 1
   
  IF B[column, row] GT 180 AND H[column, row] LT 180 THEN output[column, row] += 1
  IF H[column, row] GT 180 AND B[column, row] LT 180 THEN output[column, row] += 1 
  
 
  ;;;; DEM-based
  
  dem_val = dem_image[column, row]
    ; A  B  C
    ; D  E  F
    ; G  H  I
    
  if DEM_D[column, row] LE dem_val AND DEM_F(column, row) LE dem_val THEN output[column,row] += 1
  if DEM_B[column, row] LE dem_val AND DEM_H(column, row) LE dem_val THEN output[column,row] += 1
  if DEM_A[column, row] LE dem_val AND DEM_I(column, row) LE dem_val THEN output[column,row] += 1
  if DEM_C[column, row] LE dem_val AND DEM_G(column, row) LE dem_val THEN output[column,row] += 1
  
  
  if dem_image[column, row] LE 2 THEN output[column, row] = 0
;    IF last_set EQ 1 THEN BEGIN
;      last_set = 0
;      second_set = 1
;      CONTINUE
;    ENDIF
    
;    IF second_set EQ 1 THEN BEGIN
;      second_set = 0
;      CONTINUE
;    ENDIF
;    
;  
;    ; Do cardinal directions first
;    IF D[c, r] GT 180 AND F[c, r] LT 180 THEN output[c, r] = 1
;    IF F[c, r] GT 180 AND D[c, r] LT 180 THEN output[c, r] = 1
;    
;    IF B[c, r] GT 180 AND H[c, r] LT 180 THEN output[c, r] = 1
;    IF H[c, r] GT 180 AND B[c, r] LT 180 THEN output[c, r] = 1
;    
;    IF output[c, r] EQ 1 THEN BEGIN
;      last_set = 1
;    ENDIF ELSE BEGIN
;      last_set = 0
;    ENDELSE
    
  ENDFOR
  ENDFOR
  
  image = 0
  
  d = output
  ENVI_ENTER_DATA, d
  
  print, "Done first bit"
  
  final_output = POST_PROCESS(output)
  
  d = final_output
  ENVI_ENTER_DATA, final_output
  return, output
END