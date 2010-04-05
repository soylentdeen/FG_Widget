PRO ipac2fits,ipacfile,fitsfile

; 13 Nov 03 created
;
; reads in an IPAC table file of an IRS spectrum produced by the SSC
; writes it out as a spectral FITS file
;

; open the IPAC table file and parse the header and data portions
;   while parsing the header, add FITS keywords as they appear
; a FITS keyword must begin with "\char" and not be followed by:
;   HISTORY or spaces

close,1
openr,1,ipacfile

; initialize FITS header

hdr_raw='SIMPLE  =                    T /'
while (strlen(hdr_raw) lt 80) do hdr_raw=hdr_raw+' '

line=' '
acnt=0
hcnt=0
fcnt=1
while (not eof(1)) do begin

  readf,1,line
  if (strcmp(line,'\',1) eq 1 or strcmp(line,'|',1 eq 1)) then hcnt=hcnt+1

; if line begins with \char it may be a FITS keyword
; if not followed by HISTORY or '      ', add to header

  if (strcmp(line,'\char ',6,/fold_case) eq 1) then begin
    h_line=strmid(line,6)
    if (  (strcmp(h_line,'HISTORY',7) eq 0) $
      and (strcmp(h_line,'       ',7) eq 0) $
      and (strlen(h_line) ge 9)     ) then begin
      if (strlen(h_line) gt 80) then begin
        h_line=strmid(h_line,0,80)
      endif else begin
        while (strlen(h_line) lt 80) do h_line=h_line+' '
      endelse
      hdr_raw=hdr_raw+h_line
      fcnt=fcnt+1
    endif
  endif

; count number of columns

  if (strcmp(line,'|',1) eq 1) then begin 
    ncol=0
    spot=strpos(line,'|')
    while (spot ge 0) do begin
      line=strmid(line,spot+1)
      spot=strpos(line,'|')
      if (spot ge 0) then ncol=ncol+1
    endwhile
  endif

  acnt=acnt+1
endwhile

; add END keyword to FITS header

h_line='END'
while (strlen(h_line) lt 80) do h_line=h_line+' '
hdr_raw=hdr_raw+h_line
fcnt=fcnt+1

; pad FITS header to a multiple of 36 lines

;padcnt=fix((1 + fcnt/36 - fcnt/36.0) * 36 + 0.5)
;if (padcnt ne 36) then for i=0,padcnt*80-1 do hdr_raw=hdr_raw+' '

; read in data

nrow = acnt - hcnt              ; determine number of rows
raw=dblarr(ncol,nrow)           ; create double array raw
close,1                         ; close ipacfile
openr,1,ipacfile                ; re-open
for i=0,hcnt-1 do readf,1,line  ; parse through header
readf,1,raw                     ; read data into array raw
close,1

; convert raw into array a with data in following column order:
; wavelength, flux, error, order, flag

a=raw
a[0:2,*]=raw[1:3,*]
a[3,*]  =raw[0,*]
a[4,*]  =raw[4,*]

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
    idx=sort(b[istart:istop])
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
print,olen,total(olen),nrow

wr_spfits,fitsfile,a[0:2,*],olen,fits_hdr=header

END

