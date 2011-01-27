PRO RUN_EXTRACTION
  ; Values below are good for our Maur test example
  dem_threshold = 50
  output_threshold = 40
  gap = 2
  d_and_t_size = 3
  d_and_t_repeats = 1
  prune_length = 2
  output_filename = "D:\CrestsOutput_Maur.tif"

  ; Values below are good for our DECAL test example
;  dem_threshold = 5
;  output_threshold = 10
;  gap = 2
;  d_and_t_size = 5
;  dem_threshold = 3
;  d_and_t_repeats = 1
;  prune_length = 1
;  output_filename = "D:\CrestsOutputNew.tif"
  
  ; Get file using a GUI dialog
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  IF fid[0] EQ -1 THEN BEGIN
    print, "No file selected - exiting"
    return
  ENDIF
  
  print, dem_threshold
  
  ; Prepare the data (threshold, calculate slope and aspect etc)
  fids = PREPARE_DATA(fid, dims, pos, dem_threshold)
  ; Get the FIDs of the prepared data
  dem_fid = fids[0]
  aspect_fid = fids[1]
  slope_fid = fids[2]
  
  print, dem_threshold
  
  crests_image = EXTRACT_CRESTS(dem_fid, aspect_fid, slope_fid, dem_threshold)
  
  ; TESTING purposes only - put image in ENVI
  IMAGE_TO_ENVI, crests_image
 
  ; Create the output image
  ns = dims[2]
  nl = dims[4]
  output = intarr(ns + 1, nl + 1)
  
  output = crests_image GT output_threshold
  
  print, "Thresholded output image"
  
  
  ; Get the slope image as an array
  slope_image = ENVI_GET_DATA(fid=slope_fid, dims=dims, pos=0)
  dem_image = ENVI_GET_DATA(fid=dem_fid, dims=dims, pos=0)
  
  ; Post process the output
  ; The parameters are:
  ; 2, 5, 5, 1, )
  ; slope_image, dem_image, binary_image, gap, d_and_t_size, dem_threshold, d_and_t_repeats, prune_length
  final_output = POST_PROCESS(slope_image, dem_image, output, gap, d_and_t_size, dem_threshold, d_and_t_repeats, prune_length)
  
  print, "Finished Post-Processing"
  
  ; Export output to TIFF file (for best compatability with all GIS/RS systems)
  print, "Exporting to TIFF file at " + STRTRIM(output_filename)
  ENVI_ENTER_DATA, final_output, r_fid=final_fid
  ENVI_OUTPUT_TO_EXTERNAL_FORMAT, fid=final_fid, dims=dims, pos=0, out_name=output_filename, /TIFF
  print, "Finished"
END