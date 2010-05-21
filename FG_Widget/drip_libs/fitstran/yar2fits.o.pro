PRO yar2fits,infile,outfile

; 26 Jan 04 - lotsa stuff...
; 16 Jan 04 - was writing only col 0-2.  Now writing all cols to FITS file
;           - also found and fixed bug associated with header length
;  9 Oct 03 - created
;
; reads in a spectral extraction in YAAAR format
; writes it out in spectral FITS format
; NOTE - won't run in standard IDL, invoke smart as follows
; > smart com

; read in YAAAR data structure

status=sap_rfits(infile,sp_struct)

; copy structure contents into a simple array

alam=sp_struct.data.wave
len=n_elements(alam)
a=dblarr(5,len)

a[0,*]=sp_struct.data.wave   ; wavelength
a[1,*]=sp_struct.data.flux   ; flux
a[2,*]=sp_struct.data.stdev  ; error in flux
a[3,*]=sp_struct.data.det    ; order (1,2,3 or 11-20)
a[4,*]=sp_struct.data.flag   ; flag (for errors etc.)
;a[4,*]=sp_struct.data.sdir   ; aperture (SL1, SL2, LL1, LL2, SH, LH)

; sort array for (1) order and (2) wavelength

b=a-a
minorder=min(sp_struct.data.det)
maxorder=max(sp_struct.data.det)
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
  idx=where(b[3,*] eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    idx=sort(b[0,istart:istop])
    a[*,istart:istop] = b[*,istart+idx]
  endif
  istart=istop+1
endfor
;oplot,a[0,*],a[1,*]

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

for m=minorder,maxorder do olen[m-minorder]=n_elements(where(a[3,*] eq m))

; write spectral FITS file

wr_spfits,outfile,a,olen,fits_hdr=header

end
