PRO RUN_EXTRACTION
  threshold = 1
  
  ; Get file using a GUI dialog
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  
  ; Prepare the data (threshold, calculate slope and aspect etc)
  fids = PREPARE_DATA(fid, dims, pos, threshold)
  ; Get the FIDs of the prepared data
  dem_fid = fids[0]
  aspect_fid = fids[1]
  slope_fid = fids[2]
  
  crests_image = EXTRACT_CRESTS(dem_fid, aspect_fid, slope_fid)
  
  ; Do thresholding here
  
  ; Do collapsing here
  
  ; Do export here
END