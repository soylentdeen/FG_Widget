pro multigaus_fnb,x,a,f,pder
;same as MULTIGAUS_F but without baseline
  on_error,2                        ;Return to caller if an error occurs
  
  sz=size(a)			;determine number of Gaussians
  ngaus=sz(1)/3.		;common baseline + width, height, centroid
  if fix(ngaus) ne ngaus then begin	;true: error in inputs
    print,'ERROR: number of parameters should include:'
    print,'       width, height, centroid for each gaussian'
    retall
  endif

  gind=indgen(ngaus)		;create index for parameters
  dchck=where(a(gind*3+2) le 0.,nchck)	;make sure width gt 0 
  if nchck gt 0 then a(gind(dchck)*3)=0d0 	;true: set amplitue to 0
  dchck=where(a(gind*3) lt 0.,nchck)	;make sure amplitude ge 0
  if nchck gt 0 then a(gind(dchck)*3)=0d0	;true set amplitude to 0
  
  z=fltarr(n_elements(x),ngaus)		;store intermediate values
  ez=fltarr(n_elements(x),ngaus)
  f=replicate(0d0,n_elements(x))	;evaluate funciton: baseline first
  for i=0,ngaus-1 do begin	;loop over gaussians and add
    temp=(x-a(i*3+1))/a(i*3+2)
    z(0,i)=temp
    ez(0,i)=exp(-(abs(temp) < 7.)^2/2.)
    f=f+a(i*3)*exp(-(abs(temp) < 7.)^2/2.)	
  endfor

  if n_params(0) le 3 then return ;need partial?
;
  pder = fltarr(n_elements(x),sz(1)) 	;yes, make array.
  for i=0,ngaus-1 do begin		;loop over gaussians
    pder(*,i*3)=ez(*,i)
    pder(*,i*3+1)=a(gind(i)*3)*ez(*,i)*z(*,i)/a(gind(i)*3+2)
    pder(*,i*3+2)=pder(*,i*3+1)*z(*,i)
  endfor
  return
end

