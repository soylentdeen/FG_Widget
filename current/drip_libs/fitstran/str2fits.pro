PRO str2fits,sp_struct,outfile

; created by G. Sloan

; 23 Jul 04 changed call of wr_spfits to sm_wr_spfits
;           added col labels, no longer passing order length array
;           introduced code to eliminate degeneracy in order number
;           now writing out all components of YAAAR structure
; 20 Jan 04 eliminated a bug in sorting
; 16 Jan 04 modified as str2fits by eliminating call to read a file by GS
;  9 Oct 03 created as yar2fits.pro by GS
;
; sm_str2fits converts a SMART-compatible spectral IDL structure to a simple
; array and writes as a spectral FITS file to disk
;
; INPUT
;   sp_struct - a YAAAR/SMART-compatible spectral IDL structure
;   outfile - the name of the spectral FITS file to be written to disk
; OUTPUT
;   outfile written as a standard FITS image with NSEG keywords

; copy structure contents into a simple array

alam=sp_struct.data.wave
len=n_elements(alam)
a=dblarr(10,len)
lcol=0 ; setting wavelength column
ocol=3 ; setting order column 
mcol=5 ; setting module column

a[lcol,*]=sp_struct.data.wave   ; wavelength
a[1,*]   =sp_struct.data.flux   ; flux
a[2,*]   =sp_struct.data.stdev  ; flux_error 
a[ocol,*]=sp_struct.data.det    ; order (input:  1,2,3 or 11-20, but may change)
a[4,*]   =sp_struct.data.line   ; slit position (full=0, 1-5 hires, 1-30 lores)
a[mcol,*]=sp_struct.data.sdir   ; module (SL1,2=0,1 LL1,2=2,3, SH=4, LH=5)
a[6,*]   =sp_struct.data.scnt   ; BCD number (is this useful?)
a[7,*]   =sp_struct.data.status ; status (is this useful?)
a[8,*]   =sp_struct.data.flag   ; flag
a[9,*]   =sp_struct.data.det    ; IRS_order (left as input:  1,2,3 or 11-20)

; increment order numbers by adding 10 for SH and LL, 20 for LH
; will give 1-3 (SL), 11-13 (LL), 21-30 (SH), 41-50 (LH) 
; the IRS_order column is left alone

increment=[0,0,10,10,10,20]
for i=2,5 do begin
  index=where(a[mcol,*] eq i)
  if (max(index) gt -1) then a[ocol,index]=a[ocol,index]+increment[i]
endfor

; renumber orders into a continuous sequence with no gaps

minorder=min(a[ocol])
maxorder=max(a[ocol])
neworder=0

for m=minorder,maxorder do begin
  index=where(a[ocol] eq m)
  if (max(index) gt -1) then begin
    a[ocol,index] eq neworder
    neworder=neworder+1
  endif
endfor

; sort array for (1) order and (2) wavelength

b=a-a
minorder=min(a[ocol])
maxorder=max(a[ocol])
olen=intarr(maxorder-minorder+1)

; sort by order first, into array b

istart=0
for m=minorder,maxorder do begin
  idx=where(sp_struct.data.det eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    b[*,istart:istop] = a[*,idx]
  endif
  istart=istop+1
endfor

; now sort each order by wavelength, back into array a

istart=0
for m=minorder,maxorder do begin
  idx=where(b[ocol,*] eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    idx=sort(b[lcol,istart:istop])
    a[*,istart:istop] = b[*,istart+idx]
  endif
  istart=istop+1
endfor

; prepare FITS header to pass to wr_spfits

hdr_raw=sp_struct.header

line_count=where(strtrim(hdr_raw,2) eq 'END')
header=strarr(line_count[0]+1)
for i=0,line_count[0] do header[i]=hdr_raw[i]

; prepare olen array to pass to wr_spfits - NOTE - olen array not passed now

for m=minorder,maxorder do begin
  index=where(a[ocol,*] eq m)
  if (max(index gt -1) then olen[m-minorder]=n_elements(index) $
  else olen[m-minorder]=0
endfor

; column definitions

coldefs = ['wavelength', 'flux', 'flux_error', 'order', 'line',$
           'module','scnt','status','flag','IRS_order']

; write spectral FITS file

wr_spfits,outfile,a,-1,fits_hdr=header,collabels=coldefs

END
