
FUNCTION sortpeaks, x, y,chopdist, noddist,epsilon
  
  resarr = [-1]
  for i=0,n_elements(x)-1 do begin
    dist = sqrt((x[i]-x)^2+(y[i]-y)^2)
    deltachop = abs(dist-chopdist)
    deltanod = abs(dist-noddist)
    deltachopnod = abs(dist-sqrt(chopdist^2+noddist^2))

    kchop = where(deltachop lt epsilon)
    knod = where(deltanod lt epsilon)
    kchopnod = where(deltachopnod lt epsilon)
    
    Nmatch = 0
    if kchop(0) ne -1 then Nmatch = Nmatch+n_elements(kchop)
    if knod(0) ne -1 then Nmatch = Nmatch+n_elements(knod)
    if kchopnod(0) ne -1 then Nmatch = Nmatch+n_elements(kchopnod)

    if (Nmatch ge 2) then resarr = [resarr,i]
  endfor
  
  if (n_elements(resarr) eq 1) then return,[-1,-1]
  
  final_index = resarr(1:n_elements(resarr)-1)

  return,[[x[final_index]],[y[final_index]]]
END 


function drip_peakfind, coadded, newimage, XARR=xarr, YARR=yarr, NPEAKS=npeaks, FWHM=fwhm, THRESH=thresh, TSTEP=tstep, STARS=stars, CHOPNODDIST=chopnoddist

if not(keyword_set(THRESH)) then thresh = 12
if not(keyword_set(FWHM))   then fwhm   = 6.0
if not(keyword_set(TSTEP))  then tstep  = 0.35
if not(keyword_set(NPEAKS)) then npeaks = 4
; this is used when checking with sortpeaks if the 
; return values are coherent with chopnoddist
epsilon = 5

psf          = psf_gaussian(NPIX=50,FWHM=fwhm,/NORMALIZE)
coadd        = coadded
img          = newimage 

img_conv     = convolve(img, psf)
img_conv_abs = abs(img_conv)
bkgd         = median(img_conv_abs)
res          = moment(img_conv_abs)
sigma        = sqrt(res[1])
cutlev       = thresh*sigma

coadd_conv     = convolve(coadd, psf)
coadd_conv_abs = abs(coadd_conv)
c_bkgd         = median(coadd_conv_abs)
c_res          = moment(coadd_conv_abs)
c_sigma        = sqrt(c_res[1])
c_cutlev       = thresh*c_sigma
c_thresh       = thresh

sharplim     = [0.2,1.0]
roundlim     = [-0.75,0.75]

nfound = 0
nloop  = 0


while (nfound lt npeaks) do begin
       find, img_conv_abs, x, y, f, sharp, round, cutlev, fwhm, roundlim, sharplim, /SILENT 
       nfound = n_elements(x)
       thresh = thresh - tstep
       cutlev = thresh*sigma
       nloop  = nloop + 1
end

if keyword_set(chopnoddist) then begin
  if n_elements(chopnoddist) eq 2 then begin
    xysorted = sortpeaks(x, y, chopnoddist[0], chopnoddist[1], epsilon)
    if xysorted(0,0) ne -1 then begin
      x = xysorted(*,0)
      y = xysorted(*,1)
      nfound = n_elements(x)
    endif
  endif
endif

print, 'Number of loops run   = ',nloop
print, 'Number of peaks found = ',nfound
print, '      X            Y           F           Sharp         Round'

for j=0,nfound-1 do begin
    print, x[j],y[j],f[j],sharp[j],round[j]
endfor

;xarr=fltarr(2,n_elements(x))
;yarr=fltarr(2,n_elements(y))
;xarr[0,*] = x
;yarr[0,*] = y


nfound = 0
nloop  = 0

if (total(coadded) ne total(newimage)) THEN BEGIN
while (nfound lt npeaks) do begin
       find, coadd_conv_abs, cx, cy, f, sharp, round, c_cutlev, fwhm, roundlim, sharplim, /SILENT
       nfound = n_elements(cx)
       c_thresh = c_thresh - tstep
       c_cutlev = c_thresh*c_sigma
       nloop  = nloop + 1
end

if keyword_set(chopnoddist) then begin
  if n_elements(chopnoddist) eq 2 then begin
    xysorted = sortpeaks(cx, cy, chopnoddist[0], chopnoddist[1], epsilon)
    if xysorted(0,0) ne -1 then begin
      cx = xysorted(*,0)
      cy = xysorted(*,1)
      nfound = n_elements(x)
    endif
  endif
endif

; For coadd we need to match peaks from x,y and cx,cy

;xarr[1,*] = cx
;yarr[1,*] = cy

print, 'Number of loops run   = ',nloop
print, 'Number of peaks found = ',nfound
print, '      X            Y           F           Sharp         Round'

for j=0,nfound-1 do begin
    print, cx[j],cy[j],f[j],sharp[j],round[j]
endfor


shift_coordsx = cx - x 
shift_coordsy = cy - y 
return,[[shift_coordsx],[shift_coordsy]]
endif 

;ofile=shift(ifile,xarr,yarr)
;atv22, coadd
;atvplot, xarr, yarr, psym=4
;coords = [[xarr],[yarr]]

if keyword_set(STARS) then begin
  ;stars=coords[1,*]
  stars=transpose([[x],[y]]);changed from cx cy to add if statement for merge step
endif


;shift_coords = coords[1,*]-coords[0,*]
;shift_coordsx = cx - x 
;shift_coordsy = cy - y 
;return,[[shift_coordsx],[shift_coordsy]]

end
