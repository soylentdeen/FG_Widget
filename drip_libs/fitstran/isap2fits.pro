PRO isap2fits,infile,outfile

; 23 Jul 04 write out all components of YAAAR structure
;           call sm_wr_spfits with collabels but not order length array
; 22 Jun 04 renamed from yar2fits.pro to isap2fits.pro
; 14 Jun 04 fixed a potential bug in case an order is empty
;  8 Mar 04 bring into line with wr_spfits, avoid conflicts in order indices
; 26 Jan 04 lotsa stuff...
; 16 Jan 04 was writing only col 0-2.  Now writing all cols to FITS file
;           also found and fixed bug associated with header length
;  9 Oct 03 created
;
; reads in a spectral extraction in YAAAR-compatible FITS table format
; writes it out in spectral FITS format
; NOTE - won't run in standard IDL, invoke smart as follows
; > smart com
;
; subroutines needed
;   sap_rfits     in smart/isap/pro/ipac
;   wr_spfits     in /home/sloan/procs/fitstran

; read in YAAAR data structure

status=sap_rfits(infile,sp_struct)

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
; NOTE:  previously incrementing LL by 3 if SL present, LH by 10 if SH present

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
  index=where(a[ocol,*] eq m)
  if (max(index) gt -1) then begin
    a[ocol,index] = neworder
    neworder=neworder+1
  endif
endfor

; sort array for (1) order and (2) wavelength

b=a-a
minorder=min(a[ocol,*])
maxorder=max(a[ocol,*])
olen=intarr(maxorder-minorder+1)

; sort by order first, into array b

istart=0
for m=minorder,maxorder do begin
  idx=where(a[ocol,*] eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    b[*,istart:istop] = a[*,idx]
    istart=istop+1
  endif
endfor

; now sort each order by wavelength, back into array a

istart=0
for m=minorder,maxorder do begin
  idx=where(b[ocol,*] eq m)
  if (max(idx gt -1)) then begin
    istop=istart+n_elements(idx)-1
    idx=sort(b[lcol,istart:istop])
    a[*,istart:istop] = b[*,istart+idx]
    istart=istop+1
  endif
endfor

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

; prepare olen array to pass to wr_spfits - NOTE - olen array not passed now

for m=minorder,maxorder do begin
  index=where(a[ocol,*] eq m)
  if (max(index) gt -1) then olen[m-minorder]=n_elements(index) $
  else olen[m-minorder]=0
endfor

; column definitions

coldefs = ['wavelength', 'flux', 'flux_error', 'order', 'line',$
           'module','scnt','status','flag','IRS_order']

; write spectral FITS file

wr_spfits,outfile,a,-1,fits_hdr=header,collabels=coldefs

END
