FUNCTION REMOVE_LOW_VALUES, fid, dims, pos, threshold
  WholeBand = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  indices = WHERE(WholeBand LT threshold, count)
  IF count GT 0 THEN WholeBand[indices] = 0
  
  return, WholeBand
END