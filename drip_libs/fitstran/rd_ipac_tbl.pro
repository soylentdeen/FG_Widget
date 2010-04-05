FUNCTION rd_ipac_tbl,ipacfile,ipac_hdr

; 22 Apr 04 no actual changes
;  9 Mar 04 modified how code counts columns to use max possible
; 28 Nov 03 modified by copying the guts of ipac2fits.pro
; 13 Nov 03 created as part of ipac2fits.pro
;
; reads in an IPAC table file of an IRS spectrum produced by the SSC
;   all data read as double, no matter their original type

; INPUT
;   ipacfile - name of the IPAC file to be read
; OUTPUT
;   ipac_hdr - IPAC header converted to the format of a FITS header
; RETURNS
;   raw - the double array containing the data

; open the IPAC table file and parse the header and data portions
;   while parsing the header, add FITS keywords as they appear
; a FITS keyword must begin with "\char" and not be followed by:
;   HISTORY or spaces

openr,fn,ipacfile,/get_lun

; initialize FITS header

hdr_raw='SIMPLE  =                    T /'
while (strlen(hdr_raw) lt 80) do hdr_raw=hdr_raw+' '

line=' '
acnt=0
hcnt=0
fcnt=1
ncol=0
ncoltmp=0

while (not eof(fn)) do begin

  readf,fn,line
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
    ncoltmp=0
    spot=strpos(line,'|')
    while (spot ge 0) do begin
      line=strmid(line,spot+1)
      spot=strpos(line,'|')
      if (spot ge 0) then ncoltmp=ncoltmp+1
    endwhile
  endif
  if (ncoltmp gt ncol) then ncol=ncoltmp

  acnt=acnt+1

endwhile

; add END keyword to FITS header

h_line='END'
while (strlen(h_line) lt 80) do h_line=h_line+' '
hdr_raw=hdr_raw+h_line
fcnt=fcnt+1

; read in data
; set up data array, close and re-open IPAC table file
; note that ALL DATA WILL BE READ AS DOUBLE!

nrow = acnt - hcnt              ; determine number of rows
raw=dblarr(ncol,nrow)           ; create double array raw
close,fn                        ; close ipacfile
openr,fn,ipacfile               ; re-open
for i=0,hcnt-1 do readf,fn,line  ; parse through header
readf,fn,raw                    ; read data into array raw
close,fn

free_lun,fn
ipac_hdr=hdr_raw ; barring further processing of the header!
return,raw

END

