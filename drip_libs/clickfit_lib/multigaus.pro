Function multigaus,x,y,a,sigmaa,err=err,chi=chi,ngaus=ngaus,int=int,$
                   nobase=nobase
;+
; NAME:
;	multigaus
;
; PURPOSE:
; 	Fit the equation y=f(x) where:
;
; 		f(x) = a0 +  a1*exp(-z_i1^2/2) + a4*exp(-z_i2^2/2) + ... 
; 			and
;		z_i1=(x-a2)/a3    z_i2=(x-a5)/a6
;
;          a(0):  baseline
;          a(1+3*i): amplitude of ith gaussian
;          a(2+3*i): centroid of ith gaussian
;          a(3+3*i): FWHM/2.35 (sigma of gaussian) of ith gaussian
;
; 	The parameters A0, A1, ... are estimated and then CURVEFIT is 
;	called.
;
; CATEGORY:
;	?? - fitting
;
; CALLING SEQUENCE:
;	Result = multigaus(x, y [, a,sigmaa,err=err,chi=chi,ngaus=ngaus])
;
; INPUTS:
;	X:	The independent variable.  X must be a vector.
;	Y:	The dependent variable.  Y must have the same number of points
;		as X.
;
; OUTPUTS:
;	The fitted function is returned.
;
; OPTIONAL OUTPUT PARAMETERS:
;	A:	The coefficients of the fit.  A is a vector as 
;		described under PURPOSE.
;  sigmaa - error estimates for each parameter
;
;KEYWORDS:
;  ngaus=ngaus - specifies the number of gaussians to use (default is 1)
;  err=err - error estimates for weighting (default is 1)
;  chi=chi - the resulting reduced chi-square for the fit
;  /nobase - baseline set to 0
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; MODIFICATION HISTORY:
;mjr 6-July-94: create from MGFIT.PRO
;   

if n_params() lt 2 then begin
  print,'Result=MULTIGAUS(x,y[,a,sigmaa,err=err(def.=1),$'
  print,'                 chi=chi,/int,/nobase])'
  retall
endif

  nx = n_elements(x)
  if not(keyword_set(err)) then err=replicate(1.,nx)

  if n_elements(a) lt 4 or keyword_set(int) then begin
    a=median(y)		;baseline estimate
    yn=''
inloop:
    print,'enter parameters for gaussian'
    read,'height = ',h
    read,'centroid = ',c
    read,'width (FWHM/2.35) = ',w
    a=[a,float(h),float(c),float(w)]
again:
    read,'another gaussian (y/n)?',yn
    if yn eq 'y' then goto,inloop
    if yn ne 'n' then begin
      print,'please try again'
      goto,again
    endif
  endif
  wght=1/(float(err)>.0001)^2
  if keyword_set(nobase) then begin
    a=a(1:*)
    yfit =curvefit(x,y,wght,a,sigmaa,chisq=chi,function_name = "multigaus_fnb")
    a=[0.,a]
  endif else begin
    yfit = curvefit(x,y,wght,a,sigmaa,chisq=chi,function_name = "multigaus_f")
  endelse

  return,yfit
end
