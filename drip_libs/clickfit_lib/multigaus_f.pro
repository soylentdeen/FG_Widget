pro multigaus_f,x,a,f,pder
;procdure to evaluate multiple gaussians and return
;partial derivatives.
;INPUTS:
;  x - independent variable 
;  a - parameters for gaussians:
;          a(0):  baseline
;          a(1+3*i): amplitude of ith gaussian
;          a(2+3*i): centroid of ith gaussian
;          a(3+3*i): FWHM/2.35 (sigma of gaussian) of ith gaussian
;OUTPUTS:
;  f - value of function at each x(i)
;  pder - (optional) (n_elements(x),n_elements(a)) array containing
;         partial derivatives.  PDER(i,j) is derivative at Ith point
;         w/respect to Jth parameter.
;mjr 6-May-94:adapted from GAUSSFIT
;
  on_error,2                        ;Return to caller if an error occurs
  
  sz=size(a)			;determine number of Gaussians
  ngaus=(sz(1)-1)/3.		;common baseline + width, height, centroid
  if fix(ngaus) ne ngaus then begin	;true: error in inputs
    print,'ERROR: number of parameters should include:'
    print,'       common baseline + '
    print,'       width, height, centroid for each gaussian'
    retall
  endif

  gind=indgen(ngaus)		;create index for parameters
  dchck=where(a(gind*3+3) le 0.,nchck)	;make sure width gt 0 
  if nchck gt 0 then a(gind(dchck)*3+1)=0d0 	;true: set amplitue to 0
  dchck=where(a(gind*3+1) lt 0.,nchck)	;make sure amplitude ge 0
  if nchck gt 0 then a(gind(dchck)*3+1)=0d0	;true set amplitude to 0

  z=fltarr(n_elements(x),ngaus)		;store intermediate values
  ez=fltarr(n_elements(x),ngaus)
  f=replicate(a(0),n_elements(x))	;evaluate funciton: baseline first
  for i=0,ngaus-1 do begin	;loop over gaussians and add
    temp=(x-a(i*3+2))/a(i*3+3)
    z(0,i)=temp
    ez(0,i)=exp(-(abs(temp) < 7.)^2/2.)
    f=f+a(i*3+1)*exp(-(abs(temp) < 7.)^2/2.)	
  endfor

  if n_params(0) le 3 then return ;need partial?
;
  pder = fltarr(n_elements(x),sz(1)) 	;yes, make array.
  pder(*,0) = 1.			;compute partials
  for i=0,ngaus-1 do begin		;loop over gaussians
    pder(*,i*3+1)=ez(*,i)
    pder(*,i*3+2)=a(gind(i)*3+1)*ez(*,i)*z(*,i)/a(gind(i)*3+3)
    pder(*,i*3+3)=pder(*,i*3+2)*z(*,i)
  endfor
  return
end
