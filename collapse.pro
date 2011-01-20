;+
; NOTE: Modified by Robin Wilson (robin@rtwilson.com) from routine below to
; accept two gap parameters, one for the x direction and one for the y
; direction. This gives a calling sequence of:
; 
; collapse, image, detect, xgap, ygap, xmax, ymax
; 
; -------------------------------
; Original routine header below
; 
; NAME:
;  collapse
; PURPOSE:   (one line only)
;  Take a detection image and collapse into a list of unique local maxima
; DESCRIPTION:
; CATEGORY:
;  CCD data processing
; CALLING SEQUENCE:
;  collapse,image,detect,gap,nx,ny,xmax,ymax
; INPUTS:
;  image  - Digital image that is being scanned for discrete sources
;  detect - Byte image of same size as image.  Each element of this array
;             indicates a level of detection of the corresponding image
;             pixel.  Zero would indicate that pixel is of no particular
;             interest.  In this routine, a non-zero value of detect is
;             taken to indicate that there is something interesting in the
;             image at that location.
;  gap    - Minimium distance allowed between any two sources when done.
;             Whenever there are two apparent detections closer than this,
;             the brightest one is recorded.
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
; OUTPUTS:
;  detect - This flag array is eroded to leave only those pixels at the
;             local maxima turned on.  All nearby points are eliminated.
;  xmax   - Array of x locations of local maxima in the image
;  ymax   - Array of y locations of local maxima in the image
;             These two arrays are an alternate form of detect and are
;             provided on output if you want them since they had to be
;             generated anyway.
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  Written by Marc W. Buie, Lowell Observatory, 2004/07/14
;    This routine was extracted from within findsrc.pro
;-
pro collapse,image, detect, xgap, ygap, xmax, ymax
   
   self = 'COLLAPSE: '
   if badpar(image,[1,2,3,4,5,12,13,14,15],2,caller=self+'(image) ') then return
   if badpar(detect,[1,2,3,12,13,14,15],2,caller=self+'(detect) ') then return

   arrsz=size(image)
   nx=arrsz[1]
   ny=arrsz[2]

   arrsz=size(detect)
   dnx=arrsz[1]
   dny=arrsz[2]

   if dnx ne nx or dny ne ny then begin
      print,self,' image and detect arrays must be the same size. Aborting!'
      return
   endif

   for j=0,ny-1 do begin
      z=where(detect[*,j],count)
      if count ne 0 then begin
         for i=0,count-1 do begin
            if detect[z[i],j] then begin
               xmax0 = z[i]
               ymax0 = j
               ; Order below is deltax THEN del
               boxm,image,xmax0,ymax0,xgap,ygap,xmax,ymax,/nocheck
               repeat begin
                  i0=max([0,xmax0-xgap])
                  i1=min([nx-1,xmax0+xgap])
                  j0=max([0,ymax0-ygap])
                  j1=min([ny-1,ymax0+ygap])
                  detect[i0:i1,j0:j1]=0B
                  xmax0=xmax
                  ymax0=ymax
                  boxm,image,xmax0,ymax0,xgap,ygap,xmax,ymax,/nocheck
               endrep until xmax0 eq xmax and ymax0 eq ymax
               detect[xmax,ymax]=1B
            endif
         endfor
      endif
   endfor

   z=where(detect ne 0,count)
   if count ne 0 then begin
      xmax = z mod nx
      ymax = z / nx
   endif

end

