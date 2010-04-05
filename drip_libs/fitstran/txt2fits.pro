PRO txt2fits,infile,outfile,ocol=OCOL

; 24 Mar 04 created
;
; adds order information
; generates a minimal FITS header

; open file, read first line to determine number of columns, then close

if (n_elements(ocol) eq 0) then ocol=-1

openr,fi,infile,/get_lun
line=' '
readf,fi,line
columns=strsplit(line,' ',/extract)
ncols=n_elements(columns)
row=dblarr(ncols)
bigrow=dblarr(max([ncols,4]))
close,fi

if (ocol ge ncols) then begin
  print,'Error.  Order column given is too large'
  stop
endif

; reopen file and read it into data array, which will be 4 or more columns

openr,fi,infile,/get_lun
count=0
while (not EOF(fi)) do begin
  readf,fi,row
  if (ncols lt 4) then bigrow[0:ncols-1]=row else bigrow=row
  if (count eq 0) then data=bigrow else data=[[data],[bigrow]]
  count=count+1
endwhile

; if ocol=-1 then parse wavelengths to generate order information
; this will go in col 3, even if it overwrites something already there

if (ocol eq -1) then begin
  testlam=data[0,0]
  order=1
  data[3,0:1]=order
  direction=data[0,1]-data[0,0]
  for i=2,count-1 do begin
    deltalam=data[0,i]-data[0,1]
    if (direction gt 0 and deltalam lt 0) then order=order+1
    data[3,i]=order
  endfor
endif else begin ; else move ocol to col 3 (overwriting if necessary)
  if (ocol ne 3) then begin
    ordercol=reform(data[ocol,*])
    data[3,*]=ordercol
    data[ocol,*]=0.0 ; zero old ocol
  endif
endelse

; generate olen array and column headers

minorder=min(data[3,*]) & maxorder=max(data[3,*])
olen=intarr(maxorder-minorder+1)
for m=minorder,maxorder do olen[m-minorder]=n_elements(where(data[3,*] eq m))
coldefs=['wavelength', 'flux', 'flux_error', 'order']

; write spectral FITS file

wr_spfits,outfile,data,olen,collabels=coldefs
free_lun,fi

end
