Function sdep, DS=ds, PS=ps, VF=vf, VS=vs, W=w

;+
; NAME:
; SDEP
;
; PURPOSE:
; Returns several System DEPendent parameters, like OS family (default), 
; directory separator, path separator, etc. 
;
; CATEGORY:
; General utilities
;
; CALLING SEQUENCE:
; 
; Result = SDEP()
;
; INPUTS:
; None
;
; KEYWORD PARAMETERS:
; DS: (Directory Separator) When set, SDEP returns the directory 
;   separator (i.e. 
;   / (slash) under Unix or \ (backslash) under Windows).
; PS: (Path Separator) When set, SDEP returns the path separator 
;   (i.e. :  under Unix or ; (backslash) under Windows).
; VS: (Version Short) returns the idl short-version (i.e. 
;   '5' for idl 5.0.2)
; VF: (Version Full) returns the idl full versiom (i.e. 
;   '5.0.2' for idl 5.0.2)
; W:  (Widget allowed?) Returns 1 when widget are allowed (i.e. 
;   !d.nane is 'WIN','X' or 'MAC') otherwise returns 0 (i.e. 'PS').
;
; OUTPUTS:
; This function returns (with no keywords) the !version.os_family
; value in uppercase. If any keyword is set, the returned value
; is changed to the one described below.
;
; RESTRICTIONS:
; Never used under Mac
;
; PROCEDURE:
; Straightforward
;
; EXAMPLE:
; print,sdep()
;
; MODIFICATION HISTORY:
;   Written by: srio@esrf.fr and dejus@aps.anl.gov
; Sept, 1997  
; 97/10/16 srio@esrf.fr adds /w keyword.
; 98/12/23 srio@esrf.fr tentative update for Mac
;-
; returns system dependent values
; returns osversion if no keywords are set, otherwise returns the
; requested separator (ds = directory separator, ps = path separator)
; srio@esrf.fr 97-09-15 and dejus@aps.anl.gov 09/15/97.

osversion = StrUpCase(!version.os_family)

if keyword_set(ds) then begin   ; directory separator
  CASE osversion OF
    'UNIX':   return,'/'
    'WINDOWS':  return,'\'
    'MACOS':  return,':'
    else:   return,''
  ENDCASE
endif

if keyword_set(ps) then begin   ; path separator
  CASE osversion OF
    'UNIX':   return,':'
    'WINDOWS':  return,';'
    'MACOS':  return,','
     else:    return,''
  ENDCASE
endif

if keyword_set(vf) then return,!version.release

if keyword_set(vs) then return,strmid(!version.release,0,1)

if keyword_set(w) then begin    ; path separator
  CASE !d.name OF
    'WIN':  return,1
    'X':  return,1
    'MAC':  return,1
     else:  return,0
  ENDCASE
endif

return, osversion
end ; sdep