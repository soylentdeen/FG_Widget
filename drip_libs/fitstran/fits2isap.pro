PRO fits2isap,infile,outfile

; 23 Jul 04 major rewrite
;           modified algorithm to use column labels to identify data columns
;           if no column labels, then assume col 0 = wavelength, 1 = flux
;           construct order column from (in order of priority):
;             IRS_order column, order column, from NSEG keyword in FITS header
;           corrected bug when length of a segment is zero
; 22 Jun 04 name changed from fits2yar to fits2isap
;  4 Jun 04 comments updated
; 10 Oct 03 created
;
; fits2isap converts a FITS file with spectral FITS keywords to
;   a FITS table file using the YAAAR format structure
; input
;   infile - name of the standard FITS file with spectral FITS keywords
;   outfile - name of the output FITS table file
;
; this procedure calls sap_wfits.pro,  which is located in the smart 
;   directory in isap/pro/ipac/sap_wfits.pro
; note that some of this code also resides in rd_spfits.pro

; define YAAAR structure

data = {datum, wave:0.0, flux:0.0, stdev:0.0, det:0L, line:0L, sdir:0L, $
        scnt:0L, sky:0.0, skye:0.0, status:0L, flag:0L}

; read input data file

a=readfits(infile,fits_hdr,/silent)

sz=size(a)
ncol=sz[1]
nrow=sz[2]

; load column definitions from FITS header into label array

label=strarr(ncol)
for i=0,ncol-1 do begin
  if (i lt 9) then val = string(format='("COL0",i1)',i+1) $
  else             val = string(format='("COL",i2)',i+1)
  val = val + 'DEF'
  label[i]=sxpar(fits_hdr,val)
endfor

; search label array to identify data columns, else use defaults
; YAAAR    spec. fits  variable  default
; wave     wavelength  lcol      0
; flux     flux        fcol      1
; stdev    flux_error  ecol       
; det      order       ocol      3        also segment or aperture
; line     line        pcol               slit position
; sdir     module      mcol
; scnt     scnt        scol
; status   status      stacol
; flag     flag        flacol
; det      IRS_order   irscol    3        overrides order if present

lcol=-1 & fcol=-1 & ecol=-1 & ocol=-1 & pcol=-1 & mcol=-1 & scol=-1 
stacol=-1         & flacol=-1         & irscol=-1 

for i=0,ncol-1 do if (strcmp(label[i],'wavelength',10)) then lcol=i
for i=0,ncol-1 do if (strcmp(label[i],'flux  ',6))      then fcol=i
for i=0,ncol-1 do if (strcmp(label[i],'flux_error',10)) then ecol=i
for i=0,ncol-1 do if (strcmp(label[i],'order  ',7))     then ocol=i
if (ocol eq -1) then $
  for i=0,ncol-1 do if (strcmp(label[i],'segment ',8))  then ocol=i
if (ocol eq -1) then $
  for i=0,ncol-1 do if (strcmp(label[i],'aperture',8))  then ocol=i
for i=0,ncol-1 do if (strcmp(label[i],'line  ',6))      then pcol=i
for i=0,ncol-1 do if (strcmp(label[i],'module  ',8))    then mcol=i
for i=0,ncol-1 do if (strcmp(label[i],'scnt  ',6))      then scol=i
for i=0,ncol-1 do if (strcmp(label[i],'status  ',7))    then stacol=i
for i=0,ncol-1 do if (strcmp(label[i],'flag  ',6))      then flacol=i
for i=0,ncol-1 do if (strcmp(label[i],'IRS_order',10))  then irscol=i

; set default column for wavelength, flux if undefined 
; replace ocol with irscol if it is defined

if (lcol eq -1) then lcol=0
if (fcol eq -1) then fcol=1
if (irscol ne -1) then ocol=irscol

; generate zero arrays and order array

zeroflt=fltarr(nrow)
zerolon=lonarr(nrow)
order  =lonarr(nrow)

; if ocol defined, then load into order array, else generate from NSEG keywords

if (ocol ne -1) then begin
  order=long(a[ocol,*])
endif else begin

  nseg=sxpar(fits_hdr,'NSEG    ',count=count)

; if (count ne 0) then sxdelpar(fits_hdr,'NSEG    ')
  if (count eq 0) then nseg=1

  if (nseg gt 1) then begin
    istart=0

    for i=0,nseg-1 do begin
      if (i lt 9) then label=string(format='("NSEG0",i1)',i+1) $
      else             label=string(format='("NSEG",i2)',i+1)
      nseglen=sxpar(fits_hdr,label,count=count)
;      if (count ne 0) then sxdelpar(fits_hdr,label)
      if (count eq 0) then begin
        istop = nrow-1
        i=nseg
      endif else begin
        istop = istart+nseglen-1
      endelse
      if (istop gt istart) then begin
        order[istart:istop] = long(i+1)
        istart=istop+1
      endif
    endfor

  endif else begin
    order[*] = 1
  endelse

endelse

; load input data into a structure

data_array=replicate(data,nrow)
for i=0,nrow-1 do begin
  data_array[i].wave  = double(a[lcol,i])
  data_array[i].flux  = double(a[fcol,i])
  if (ecol ne -1)   then data_array[i].stdev  = double(a[ecol,i])
  data_array[i].det   = order[i]
  if (pcol ne -1)   then data_array[i].line   = long(a[pcol,i])
  if (mcol ne -1)   then data_array[i].sdir   = long(a[mcol,i])
  if (scol ne -1)   then data_array[i].scnt   = long(a[scol,i])
  if (stacol ne -1) then data_array[i].status = long(a[stacol,i])
  if (flacol ne -1) then data_array[i].flag   = long(a[flacol,i])
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

fxbhmake,ext_hdr,nrow
for i=0,2 do fxbaddcol,index,ext_hdr,zeroflt[0],f_ttype[i],tunit=f_tunit[i]
for i=3,6 do fxbaddcol,index,ext_hdr,zerolon[0],f_ttype[i],tunit=f_tunit[i]
for i=7,8 do fxbaddcol,index,ext_hdr,zeroflt[0],f_ttype[i],tunit=f_tunit[i]
for i=9,10 do fxbaddcol,index,ext_hdr,zerolon[0],f_ttype[i],tunit=f_tunit[i]

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

; call sap_wfits to write the array out as a file

z=sap_wfits(outfile,sp_struct)

END
