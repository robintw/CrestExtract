PRO TEST_PEAKFINDER
  ENVI_SELECT, fid=fid,dims=dims,pos=pos, /BAND_ONLY
  WholeBand = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  help, dims
  
  output = intarr(dims[2] + 1, dims[4] + 1)
  
  help, WholeBand[*, 0]
  
  ;tvscl, WholeBand
  
  FOR i = 0, dims[4] - 1 DO BEGIN
  res = PeakFinder(WholeBand[*,i], npeaks=npeaks, /OPTIMIZE, /SORT)
  output[res[0,0:npeaks-1], i] = 1
  help, res
  help, res[0]
  print, res[0]
  
  ENDFOR
  
  ENVI_ENTER_DATA, output
END