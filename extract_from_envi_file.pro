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
    
  crest_fid = EXTRACT_CRESTS(thresholded_fid, LP2_fid, slope_fid)
  
  return, crest_fid
END
