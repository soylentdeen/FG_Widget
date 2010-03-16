PRO eco2fits,datfile,errfile,outfile,normarray,trimlam

; 25 Jan 06 created - for now, written to specific needs
;
; based on yar2fits.pro, last modified 14 Jun 04

; reads in ECO results - spectral extraction in YAAAR format
;   separate files for data and error
; combines writes it out in spectral FITS format
; NOTE - won't run in standard IDL, invoke smart as follows
; > smart com
;
; INPUT
;   datfile   - ECO YAAAR-format FITS file with mean in flux column
;   errfile   - ECO YAAAR-format FITS file with error in flux column
;   normarray - normalization factors for each aperture (SL1,2,LL1,2,SH,LH)
;   trimlam   - wavelength at which lores data stops and hires starts
;               if not included, no trimming performed

lcol=0 & fcol=1 & ecol=2 & ocol=3
; read in YAAAR data structures

statd=sap_rfits(datfile,sp_struct)
state=sap_rfits(errfile,err_struct)

; copy structure contents into a simple array

alam=sp_struct.data.wave
len=n_elements(alam)
a=dblarr(6,len)
a[lcol,*]=sp_struct.data.wave   ; wavelength
a[fcol,*]=sp_struct.data.flux   ; flux
a[ecol,*]=err_struct.data.flux  ; error in flux - FROM ERROR FILE, NOT MEAN FILE
a[ocol,*]=sp_struct.data.det    ; order (1,2,3 or 11-20)
a[4,*]=sp_struct.data.flag   ; flag (for errors etc.)
modu  =sp_struct.data.sdir   ; module (0,1=SL1,2, 2-3=LL1,2, 4=SH, 5=LH)
a[5,*]=sp_struct.data.sdir   ; aperture (SL1, SL2, LL1, LL2, SH, LH)

; increment order information to avoid conflicts between modules

; increment LL only if SL data present, increment by 3

sl_idx=where(modu eq 1 or modu eq 1)
ll_idx=where(modu eq 2 or modu eq 3)
if (max(ll_idx) gt -1 and max(sl_idx) gt -1) then $
  a[ocol,ll_idx] = a[ocol,ll_idx]+3  

; increment LH only if SH data present, increment by 10

sh_idx=where(modu eq 4)
lh_idx=where(modu eq 5)
if (max(lh_idx) gt -1 and max(sh_idx) gt -1) then $
  a[ocol,lh_idx] = a[ocol,lh_idx]+10  

; make sure errors are positive
a[ecol,*]=abs(a[ecol,*])

; normalize segments
if (n_elements(normarray) eq 6) then for i=0,5 do begin
  if (normarray[i] ne 0 and normarray[i] ne 1) then begin
    idx=where(modu eq i)
    if (idx gt -1) then begin
      a[fcol,*]=a[fcol,*]/normarray[i] ; flux
      a[ecol,*]=a[ecol,*]/normarray[i] ; error
    endif
  endif
endfor

; sort array for (1) order and (2) wavelength

b=a-a
minorder=min(a[3,*])
maxorder=max(a[3,*])
olen=intarr(maxorder-minorder+1)

; sort by order first, into array b

istart=0
for m=minorder,maxorder do begin
  idx=where(a[3,*] eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    b[*,istart:istop] = a[*,idx]
  endif
  istart=istop+1
endfor

; now sort each order by wavelength, back into array a

istart=0
for m=minorder,maxorder do begin
  idx=where(b[3,*] eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    idx=sort(b[0,istart:istop])
    a[*,istart:istop] = b[*,istart+idx]
  endif
  istart=istop+1
endfor

; trim data using trimlam - lores to blue, hires to red

if (keyword_set(trimlam) ne 0) then begin 
  print,n_elements(a[lcol,0]),' TRIMLAM = ',trimlam
  for i=1,6 do begin ; trim SL and LL
    idx=where(a[ocol,*] eq i)
    if (max(idx) gt -1) then begin
      minlam=min(a[lcol,idx]) & maxlam=max(a[lcol,idx])
      if (trimlam lt minlam) then a=spcut(a,0,trimlam,order=i,/all) $
                             else a=spcut(a,0,trimlam,order=i)
    endif
    print,i,n_elements(idx),minlam,maxlam,n_elements(a[lcol,*])
  endfor
  if (keyword_set(trimlam) ne 0) then for i=11,30 do begin ; trim SH and LH
    idx=where(a[ocol,*] eq i)
    if (max(idx) gt -1) then begin
      minlam=min(a[lcol,idx])& maxlam=max(a[lcol,idx])
      if (trimlam gt maxlam) then a=spcut(a,maxlam,trimlam,order=i,/all) $
                             else a=spcut(a,trimlam,maxlam,order=i)
    endif
    print,i,n_elements(idx),minlam,maxlam,n_elements(a[lcol,*])
  endfor
endif

; prepare FITS header to pass to wr_spfits

hdr_raw=sp_struct.header
hdr_lines=strlen(hdr_raw)/8
line_count=0
test=strmid(hdr_raw,0,8)
while (test ne 'END     ') do begin
  line_count=line_count+1
  test=strmid(hdr_raw,80*line_count,8)
endwhile

header=strarr(line_count+1)
for i=0,line_count do header[i]=strmid(hdr_raw,80*i,80)

; prepare olen array to pass to wr_spfits
for m=minorder,maxorder do begin
  index=where(a[3,*] eq m)
  if (max(index) gt -1) then olen[m-minorder]=n_elements(index) else $
  olen[m-minorder]=0
endfor

;column definitions
coldefs = ['wavelength', 'flux', 'flux_error', 'order', 'flag']

; write spectral FITS file
wr_spfits,outfile,a,olen,fits_hdr=header,collabels=coldefs

end
