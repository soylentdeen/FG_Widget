PRO ipac2fits,ipacfile,fitsfile

; version 1.3

; 27 Jan 04 1.3 now including collabels in call to wr_spfits
;  3 Dec 03 1.2 now writing all data columns
; 28 Nov 03 1.1 separated section that reads IPAC file as rd_ipac_tbl.pro
; 13 Nov 03 1.1 created
;
; reads in an IPAC table file of an IRS spectrum produced by the SSC
; writes it out as a spectral FITS file

; open the IPAC table file and parse the header and data portions
;   while parsing the header, add FITS keywords as they appear
; a FITS keyword must begin with "\char" and not be followed by:
;   HISTORY or spaces

; read in IPAC table and header

raw=rd_ipac_tbl(ipacfile,hdr_raw)

; convert raw into array a with data in following column order:
; wavelength, flux, error, order, flag

a=raw
a[0:2,*]=raw[1:3,*]
a[3,*]  =raw[0,*]
a[4,*]  =raw[4,*]

collabels=['wavelength','flux','flux_error','order','flag']

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

; prepare FITS header to pass to wr_spfits

hdr_lines=strlen(hdr_raw)/80
header=strarr(hdr_lines)
for i=0,hdr_lines-1 do header[i]=strmid(hdr_raw,80*i,80)

; prepare olen array to pass to wr_spfits

for m=minorder,maxorder do olen[m-minorder]=n_elements(where(a[3,*] eq m))

; write the FITS file - note that we are now writing all columns
wr_spfits,fitsfile,a,olen,fits_hdr=header,collabels=collabels

END

