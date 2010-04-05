FUNCTION rd_sptxt,infile

; 21 Jan 05 created
;
; reads a text file into a spectral data array for use with sp software
; if no error or order column (assumed to be col 2 and 3), these are created
; each line of the text file must have the same number of space-delimited
;   columns

openr,fn,infile,/get_lun
inline=' '
count=long(0)

while (not eof(fn)) do begin

; for first line of file, determine number of columns 
; and create and load input array for a single line (dum_line)

  if (count eq 0) then begin
    readf,fn,inline
    spl_inline=strsplit(inline,' ',/extract)
    ncol=n_elements(spl_inline)
    dum_line=dblarr(ncol)
    for i=0,ncol-1 do dum_line[i]=double(spl_inline[i])
  endif

; for following lines, simply read data into dum_array
; copy to sp_array and pad with zeroes if ncol < 4

  if (count gt 0) then readf,fn,dum_line
  sp_line=dum_line
  while (n_elements(sp_line) lt 4) do sp_line=[sp_line,0]

; load sp_array

  if (count eq 0) then sp_array=sp_line else sp_array=[[sp_array],[sp_line]]

  count=count+1
endwhile

RETURN,sp_array
END
