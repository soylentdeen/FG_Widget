function rd_spfits,infile;fits_hdr=hdr

; 29 Jan 04 created by M. Russell

; reads in a spectral FITS file and if necessary, rearranges it so that
;   col 0 = wavelength
;   col 1 = flux
;   col 2 = flux_error
;   col 3 = order/aperture/segment
;   col 4 = flag
;   col 5+ = remaining columns
; INPUT - file name of spectral FITS file
; OUTPUT - returns the spectral data array
;        - if fits_hdr is defined in the call, this is also returned
;             NOT YET IMPLEMENTED

; read the FITS file

a = readfits(infile,h)
dat = size(a)
ncols = dat(1)
nrows = dat(2)
labels = strarr(ncols)
sum = 0

for i=0,ncols-1 do begin

   if (i lt 9) then val = string(format='("COL0",i1)',i+1) $
   else             val = string(format='("COL",i2)',i+1)
   val = val + 'DEF'
   labels(i) = sxpar(h,val)
   print,labels(i),'top',i
   case strtrim(labels(i)) of
      'wavelength': sum = sum 
      'flux'      : sum = sum
      'flux_error': sum = sum
      'order'     : sum = sum
      'flag'      : sum = sum
      else        : begin
                    sum = sum + 1
                    print,labels(i),'bottom',i
                    end
   endcase

endfor

finarr = fltarr(5+sum,nrows)
help,finarr
finarr(*,*) = -1
labelout = strarr(5+sum)
labelout(0) = 'wavelength'
labelout(1) = 'flux'
labelout(2) = 'flux_error'
labelout(3) = 'order'
labelout(4) = 'flag'
index = 5

for j=0,ncols-1 do begin
   
   case strtrim(labels(j)) of
      'wavelength': finarr(0,*) = a(j,*)
      'flux'      : finarr(1,*) = a(j,*)
      'flux_error': finarr(2,*) = a(j,*)
      'order'     : finarr(3,*) = a(j,*)
      'flag'      : finarr(4,*) = a(j,*)
      else        : begin
                    finarr(index,*) = a(j,*)
                    labelout(index) = strtrim(labels(j))
                    index = index + 1
                    end
   endcase
   
endfor

print, labelout
return,finarr

end
