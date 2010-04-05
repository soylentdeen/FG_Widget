PRO wr_spfits,fits_file,sp_data,len_array,FITS_HDR=fits_hdr
;
; author:  G.C. Sloan
;
; version 1.2

; 20 Jan 04 1.2 modifying FITS header output slightly - need to do more
;  3 Dec 03 1.2 expand the number of possible columns
; 10 Oct 03 1.1 delete EXTEND keyword in original header
;  3 Oct 03 1.1 allow len_array to be zero
; 15 Jul 03 1.0 adapted from sws2fits.pro 
;  6 Apr 03     created as sws2fits.pro
;
; generates a spectral fits file in 3-column format
; col 1 = wavelength (um), col 2 = flux (Jy), col 3 = uncertainty in flux
; additional columns can be anything given
; there is not yet a means implemented to provide labels for these columns
; this format is designed for segmented spectra, which can have overlaps
;   between segments
;
; INPUT:
;   fits_file - the name of the FITS file to write
;   sp_data -   the data in 2-plus-column format
;   len_array - an array containing the length of each segment of the spectrum
;               the sum of the segment lengths must equal the no. of rows
;               in sp_data
;               if total(len_array)=0, then NSEG set to 1
;   fits_hdr -  the starting FITS header, which will be modified
;               the FITS header should include a DATE label
;               if not provided, a fresh FITS header will be generated
; OUTPUT:       1 FITS file to disk, nothing back to calling procedure

; check for two-dimensional data with at least two columns

  errcode=0
  sz_data=size(sp_data)
  ndim=sz_data[0]
  ncol=sz_data[1]
  if (ndim ge 2) then nrow=sz_data[2]
  if (ndim ne 2) then begin
    errcode=1
    print,'Error.  Spectral data array must have two dimensions.'
  endif
  if (ncol lt 2) then begin
    errcode=1
    print,'Error.  Spectral data must have at least two columns.'
  endif

; if len_array=0, then set it
; otherwise check to see if total(len_array) = no. of rows in sp_data

  if (total(len_array) eq 0) then len_array=nrow
  if (total(len_array) ne nrow) then begin
    errcode=1
    print,'Error.  Total of length array must match length of spectral data.'
  endif
  if (errcode eq 1) then begin
    print,'Stopping.'
    stop
  endif

; copy sp_data into out_data, creating an error column (of 0) if necessary

  if (ncol eq 2) then begin
    out_data=dblarr(3,nrow)
    out_data[0:1,*]=sp_data
  endif else begin
    out_data=dblarr(ncol,nrow)
    out_data=sp_data
  endelse

; generate header from fits_hdr

  if (n_elements(fits_hdr) eq 0) then mkhdr,h0,out_data $
  else h0=fits_hdr

; add fresh FITS keywords to header

  nseg=n_elements(len_array)
  sxaddpar,h0,'NSEG',nseg,' Number of spectral segments',before='DATE   '

  for i=0,nseg-1 do begin
    if (i lt 9) then label=string(format='("NSEG0",i1)',i+1) $
    else             label=string(format='("NSEG",i2)',i+1)
    comment=string(format='(" Length of segment ",i2)',i+1)
    sxaddpar,h0,label,len_array[i],comment,before='DATE   '
  endfor

  sxaddpar,h0,'COMMENT','Column 4 = order number','',after='DATE   '
  sxaddpar,h0,'COMMENT','Column 3 = uncertainty in flux (Jy)','',after='DATE   '
  sxaddpar,h0,'COMMENT','Column 2 = flux (Jy)','',after='DATE   '
  sxaddpar,h0,'COMMENT','Column 1 = wavelength (micron)','',after='DATE   '

; remove keywords which might be left from YAAAR or similar formats

  sxdelpar,h0,'EXTEND '

; write output fits file

  writefits,fits_file,out_data,h0

end
