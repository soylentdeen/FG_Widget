PRO fits2txt,infile,outfile

; 19 Oct 06 created
;
; fits2txt converts a FITS file with spectral FITS keywords to
;   a simple text file
; input
;   infile - name of the standard FITS file with spectral FITS keywords
;   outfile - name of the output text file
;
; note that some of this code also resides in rd_spfits.pro

; read input data file

a=readfits(infile,fits_hdr,/silent)

ncol=n_elements(a[*,0])
nrow=n_elements(a[0,*])

; print output

openw,fo,outfile,/get_lun

for i=0,nrow-1 do printf,fo,a[*,i]

close,/all
END
