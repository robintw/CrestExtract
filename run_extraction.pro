PRO RUN_EXTRACTION, config_filename
  print, "Reading configuration file from ", STRTRIM(config_filename, 2)
  params = pp_readpars(config_filename)
  
  dem_threshold = GET_TAG_OR_DEFAULT(params, "dem_threshold", 0)
  output_threshold = GET_TAG_OR_DEFAULT(params, "output_threshold", 0)
  gap = GET_TAG_OR_DEFAULT(params, "gap", 4)
  d_and_t_size = GET_TAG_OR_DEFAULT(params, "d_and_t_size", 3)
  d_and_t_repeats = GET_TAG_OR_DEFAULT(params, "d_and_t_repeats", 1)
  prune_length = GET_TAG_OR_DEFAULT(params, "prune_length", 2)
  do_collapse = GET_TAG_OR_DEFAULT(params, "do_collapse", 0)
  input_filename = GET_TAG_OR_DEFAULT(params, "input_filename", "")
  output_filename = GET_TAG_OR_DEFAULT(params, "output_filename", "D:\CrestsOutput_DEFAULT.tif")

  print, "Finished reading configuration file."
  
  ; Values below are good for our Maur test example
;  dem_threshold = 50
;  output_threshold = 40
;  gap = 4 ; Was 2
;  d_and_t_size = 5 ; was 3
;  d_and_t_repeats = 2 ; was 1
;  prune_length = 4 ; was 2
;  output_filename = "D:\CrestsOutput_MaurWhole_Params2.tif"

  ; Values below are good for our DECAL test example
;  dem_threshold = 5
;  output_threshold = 10
;  gap = 2
;  d_and_t_size = 5
;  dem_threshold = 3
;  d_and_t_repeats = 1
;  prune_length = 1
;  output_filename = "D:\CrestsOutputNew.tif"

  IF STRLEN(input_filename) EQ 0 OR STRLEN(output_filename) EQ 0 THEN BEGIN
    print, "No input or no output filename specified. Exiting."
  ENDIF
  
  ENVI_OPEN_FILE, input_filename, r_fid=fid

  IF fid EQ -1 THEN print, "File not found. Exiting."
  
  ENVI_FILE_QUERY, fid, dims=dims
  
  pos=0

  print, "Before prepare data"
  
  ; Prepare the data (threshold, calculate slope and aspect etc)
  print, "Preparing data."
  fids = PREPARE_DATA(fid, dims, pos, dem_threshold)
  
  ; Get the FIDs of the prepared data
  dem_fid = fids[0]
  aspect_fid = fids[1]
  slope_fid = fids[2]
  
  print, "Running crest extraction algorithm:"
  crests_image = EXTRACT_CRESTS(dem_fid, aspect_fid, slope_fid, dem_threshold)
  
  ; TESTING purposes only - put image in ENVI
  IMAGE_TO_ENVI, crests_image
 
  ; Create the output image
  ns = dims[2]
  nl = dims[4]
  output = intarr(ns + 1, nl + 1)
  
  output = crests_image GT output_threshold
  
  print, "Finished thresholding"
  
  
  ; Get the slope image as an array
  slope_image = ENVI_GET_DATA(fid=slope_fid, dims=dims, pos=0)
  dem_image = ENVI_GET_DATA(fid=dem_fid, dims=dims, pos=0)
 
  print, "Post processing data:"
  final_output = POST_PROCESS(slope_image, dem_image, output, gap, d_and_t_size, dem_threshold, d_and_t_repeats, prune_length, do_collapse)
  
  print, "Finished Post-Processing"
  
  ; Export output to TIFF file (for best compatability with all GIS/RS systems)
  print, "Exporting to TIFF file at " + STRTRIM(output_filename)
  
  IF FILE_TEST(output_filename) EQ 1 THEN BEGIN
    print, "!!! Output file exists - so deleting old version"
    FILE_DELETE, output_filename
  ENDIF
  
  ENVI_ENTER_DATA, final_output, r_fid=final_fid
  ENVI_OUTPUT_TO_EXTERNAL_FORMAT, fid=final_fid, dims=dims, pos=0, out_name=output_filename, /TIFF
  print, "Finished"
END
