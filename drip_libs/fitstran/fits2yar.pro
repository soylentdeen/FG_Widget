PRO fits2yar,infile,outfile

;  4 Jun 04 comments updated
; 10 Oct 03 created
;
; spfits2yar converts a FITS file with spectral FITS keywords to
;   a FITS table file using the YAAAR format structure
; input
;   infile - name of the standard FITS file with spectral FITS keywords
;   outfile - name of the output FITS table file
;
; this procedure calls sap_wfits.pro,  which is located in the smart 
;   directory in isap/pro/ipac/sap_wfits.pro
; note that some of this code also resides in rd_spfits.pro

; define YAAAR structures

data = {datum, wave:0.0, flux:0.0, stdev:0.0, det:0L, line:0L, sdir:0L, $
        scnt:0L, sky:0.0, skye:0.0, status:0L, flag:0L}

; read input data file

a=readfits(infile,fits_hdr,/silent)

sz=size(a)
ncol=sz[1]
nrow=sz[2]

; pad input data array with additional columns
; col 3 = det = segment number
; segments will be numbered 1 to N, where N < 100
; get the NSEG information from FITS header
; and use this to loop through data, filling col 3

ncolb=max([4,ncol])
b=fltarr(ncolb,nrow)
b[0:ncol-1,*]=a[0:ncol-1,*]
sky=fltarr(nrow)

nseg=sxpar(fits_hdr,'NSEG    ',count=count)
;if (count ne 0) then sxdelpar(fits_hdr,'NSEG    ')
if (count eq 0) then nseg=1

if (nseg gt 1) then begin
  istart=0
  for i=0,nseg-1 do begin
    if (i lt 9) then label=string(format='("NSEG0",i1)',i+1) $
    else             label=string(format='("NSEG",i2)',i+1)
    nseglen=sxpar(fits_hdr,label,count=count)
;    if (count ne 0) then sxdelpar(fits_hdr,label)
    if (count eq 0) then begin
      istop = nrow-1
      i=nseg
    endif else begin
      istop = istart+nseglen-1
    endelse
    b[3,istart:istop] = float(i+1)
    istart=istop+1
  endfor
endif else begin
  b[3,*] = 1.0
endelse

; load padded input data array into a structure

data_array=replicate(data,nrow)
for i=0,nrow-1 do begin
;  data_array[i] = {datum, wave:a[0,i], flux:a[1,i], stdev:a[2,i], $
;                   det:0, line:0, sdir:0, scnt:0, status:0, flag:0}
  data_array[i].wave  = b[0,i]
  data_array[i].flux  = b[1,i]
  data_array[i].stdev = b[2,i]
  data_array[i].det   = long(b[3,i])
endfor

; modify primary FITS header

sxaddpar,fits_hdr,'BITPIX',8
sxaddpar,fits_hdr,'NAXIS',0
sxdelpar,fits_hdr,'NAXIS1'
sxdelpar,fits_hdr,'NAXIS2'
sxaddpar,fits_hdr,'EXTEND','T','FITS dataset may contain extension',$
  after='NAXIS'

; create and customize FITS extension header

f_ttype=['WAVE','FLUX','STDEV','DET','LINE','SDIR','SCNT','SKY',$
         'SKYE','STATUS','FLAG']
f_tunit=['um','Jy','Jy',' ',' ',' ',' ','Jy','Jy','  ','  ']
;f_tform=['1E','1E','1E','1J','1J','1J','1J','1E','1E','1J','1J']
fxbhmake,ext_hdr,nrow
for i=0,2 do fxbaddcol,index,ext_hdr,b[i,0],f_ttype[i],tunit=f_tunit[i]
for i=3,6 do fxbaddcol,index,ext_hdr,long(b[3,0]),f_ttype[i],tunit=f_tunit[i]
for i=7,8 do fxbaddcol,index,ext_hdr,sky[0],f_ttype[i],tunit=f_tunit[i]
for i=9,10 do fxbaddcol,index,ext_hdr,long(b[3,0]),f_ttype[i],tunit=f_tunit[i]
;for i=0,10 do begin
;  if (i lt 9) then label=string(format='("TFORM",i1)',i+1) $
;  else             label=string(format='("TFORM",i2)',i+1)
;  
;  fxaddpar,ext_hdr,label,f_tform[i]
;endfor

; combine FITS and FITS extension header into a single string for YAAAR file

yar_hdr=''
sz=size(fits_hdr)
hdr_len=sz[1]
for i=0,hdr_len-1 do yar_hdr = yar_hdr + fits_hdr[i]
for i=0,79 do        yar_hdr = yar_hdr + ' '
sz=size(ext_hdr)
hdr_len=sz[1]
for i=0,hdr_len-1 do yar_hdr = yar_hdr + ext_hdr[i]

; create the sp_struct structure, load header and data array

sp_struct = {type:'YAAAR', header:' ', history:strarr(1), data:data_array}
sp_struct.header=yar_hdr
sp_struct.data=data_array

; call sap_wfits to write the array out

z=sap_wfits(outfile,sp_struct)

end
