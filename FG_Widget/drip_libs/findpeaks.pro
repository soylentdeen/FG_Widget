function findpeaks, ifile, XARR=xarr, YARR=yarr, NPEAKS=npeaks, FWHM=fwhm, THRESH=thresh, TSTEP=tstep

if not(keyword_set(THRESH)) then thresh = 20.0
if not(keyword_set(FWHM))   then fwhm   = 6.0
if not(keyword_set(TSTEP))  then tstep  = 0.5
if not(keyword_set(NPEAKS)) then npeaks = 1

psf          = psf_gaussian(NPIX=50,FWHM=fwhm,/NORMALIZE)

img          = ifile ;readfits(ifile,head)
img_conv     = convolve(img, psf)
img_conv_abs = abs(img_conv)
bkgd         = median(img_conv_abs)
res          = moment(img_conv_abs)
sigma        = sqrt(res[1])
cutlev       = thresh*sigma

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

print, 'Number of loops run   = ',nloop
print, 'Number of peaks found = ',nfound
print, '      X            Y           F           Sharp         Round'

for j=0,nfound-1 do begin
    print, x[j],y[j],f[j],sharp[j],round[j]
endfor

xarr = x
yarr = y

; MAKE THIS WORK ON TWO IMAGES: COADDED AND NEWREZ. SHIFT BY THE DIFFERENCE
; BETWEEN THEM...(ALTERED MERGE AND COADD SO FAR)
; NEED TO DO THIS IN MERGE ALSO...

;ofile=shift(ifile,xarr[0],yarr[0])
coords = [x,y]
;atv22, img
;atvplot, xarr[0], yarr[0], psym=4
return, coords
 end
