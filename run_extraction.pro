PRO RUN_EXTRACTION
  dem_threshold = 1
  output_threshold = 100
  output_filename = "D:\FinalOutput.tif"
  
  ; Get file using a GUI dialog
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  
  ; Prepare the data (threshold, calculate slope and aspect etc)
  fids = PREPARE_DATA(fid, dims, pos, dem_threshold)
  ; Get the FIDs of the prepared data
  dem_fid = fids[0]
  aspect_fid = fids[1]
  slope_fid = fids[2]
  
  crests_image = EXTRACT_CRESTS(dem_fid, aspect_fid, slope_fid)
  
  ; TESTING purposes only - put image in ENVI
  IMAGE_TO_ENVI, crests_image
  
 
  ; Create the output image
  ns = dims[2]
  nl = dims[4]
  output = intarr(ns + 1, nl + 1)
  
  print, "Created output image"
  
  output = crests_image GT output_threshold
  
  print, "Thresholded output image"
  
  ; TESTING purposes only
  IMAGE_TO_ENVI, output
  
  ; Get the slope image as an array
  slope_image = ENVI_GET_DATA(fid=slope_fid, dims=dims, pos=0)
  
  ; Do collapsing here
  final_output = POST_PROCESS(slope_image, output, 2)
  
  print, "Collapsed image"
  
  print, "Exporting to TIFF file at " + STRTRIM(output_filename)
  ENVI_ENTER_DATA, final_output, r_fid=final_fid
  ENVI_OUTPUT_TO_EXTERNAL_FORMAT, fid=final_fid, dims=dims, pos=0, out_name=output_filename
  print, "Finished"
END