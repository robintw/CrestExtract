FUNCTION Make_Set,x,y1,y2,y3,y4,y5,y6,y7,y8, ToFile=tofile, group=group, $
  _Extra=extra

;+
; NAME:
; MAKE_SET
;
; PURPOSE:
;       This function returns a multicolumn array (array(ncols,npoints))
; build from separate arrays with the column data.
;
; CATEGORY:
; General utilities
;
; CALLING SEQUENCE:
;       Result = Make_Set(x,y1 [,y2,...,y8])
;
; INPUTS:
;       
; x: The array with abscissas
; y1: The array with ordinates (must be of the same type as x and
;   with the same number of points)
;
; OPTIONAL INPUTS:
; y2,...,y8 additional ordinates arrays 
; 
; KEYWORD PARAMETERS
; ToFile: a string cointaining a file name where to write
;   (optionally) the data. If this strinf is '?' then 
;   the Dialog_PickFile() window is started to receive
;   the file name.
; Group: The widget if of the caller.
; _Extra: any other keyword to ba passed to Dialog_PickFile()
;
; OUTPUTS:
;       This function return the global array and optionally writes 
; a disk file.
;
; PROCEDURE:
;       
;       Easy.
;
; EXAMPLE:
; help,Make_Set(FindGen(100),FindGen(100))
; <Expression>    FLOAT     = Array[2, 100]
;
; MODIFICATION HISTORY:
;   Written by: Manuel Sanchez del Rio (srio@esrf.fr), 98-12-21
;
;-

Catch, error_status
IF error_status NE 0 THEN BEGIN
   Message,/Info,'error caught: '+!err_string
   itmp = Dialog_Message(/Error,Dialog_Parent=group, $
     'MAKE_SET: error caught: '+!err_string)
   Catch, /Cancel
   On_Error,2
   IF N_Elements(out) NE 0 THEN RETURN,out ELSE RETURN,0
ENDIF

nn = N_Params()
nx = N_Elements(x)
IF nn LT 2 THEN Message,'Usage: result = Make_Set(x,y [,y2,y3,y4,y5,y6,y7,y8])'
CASE nn OF
 2: out = reform([x,y1],nx,nn)
 3: out = reform([x,y1,y2],nx,nn)
 4: out = reform([x,y1,y2,y3],nx,nn)
 5: out = reform([x,y1,y2,y3,y4],nx,nn)
 6: out = reform([x,y1,y2,y3,y4,y5],nx,nn)
 7: out = reform([x,y1,y2,y3,y4,y5,y6],nx,nn)
 8: out = reform([x,y1,y2,y3,y4,y5,y6,y7],nx,nn)
 9: out = reform([x,y1,y2,y3,y4,y5,y6,y7,y8],nx,nn)
 else: Message,'Bad inputs'
ENDCASE
out = Transpose(out)
IF Keyword_Set(tofile) THEN BEGIN
  IF StrCompress(tofile,/Rem) EQ '?' THEN BEGIN
    tofile = Dialog_PickFile(/Write,group=group,file='tmp.dat', $
  _Extra=extra)
    IF tofile EQ '' THEN RETURN,out
  ENDIF
  Openw,unit,tofile,/Get_Lun
  FOR i=0L,nx-1 DO PrintF,unit,out[*,i]
  Free_Lun,unit
  Message,/Info,'File '+tofile+' written to disk.'
  IF SDep(/W) THEN $
     itmp = Dialog_Message(Dialog_Parent=group, $
  /Info,'File '+tofile+' written to disk.')
ENDIF
RETURN,out
END