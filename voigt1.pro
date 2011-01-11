FUNCTION voigt1,x,a
;+
; NAME:
; VOIGT1 
; PURPOSE:
; Returns the value of a pseudo-voigt function (a combination of
; lorentzian and gaussian functions)
; CATEGORY:
; Mathematics.
; CALLING SEQUENCE:
; Result = voigt1(x,a)
; INPUTS:
; x: the argument for the function (number or array)
; a: array with the function coefficients:
;   a(0) Amplitud
;   a(1) Center
;   a(2) Full Width at Half Maximum
;   a(3) Ratio between lorentzian and Gaussisan (1=Pure
;     lorentzian, 0=Pure Gaussian, 0.5=half each)
; SIDE EFFECTS:
;   None.
; RESTRICTIONS:
; None.
; PROCEDURE:
; Easy (see source).
; MODOFICATION HISTORY:
; M. Sanchez del Rio. ESRF. Grenoble 26 May 1996
; 97/10/20 srio@esrf.fr corrects a bug in Gaussian width.
;
;-

; a(0) amplittud
; a(1) center
; a(2) FWHM
; a(3) ratio lorentian/gaussian

xx = x-a(1)
lor = 1.0 + (xx/(0.5*a(2)))^2
;gau = exp( - (xx/0.600561/a(2))^2 )
;bugged: gau = exp( - (xx*sqrt(alog(2.))/a(2))^2 )
gau = exp( - (xx*2.0*sqrt(alog(2.))/a(2))^2 )
res = (a(3)/lor + (1. - a(3))* gau )*a(0)
return,res
end
