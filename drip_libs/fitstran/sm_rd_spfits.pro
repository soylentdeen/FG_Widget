;#> .dc1
;
; Identifier:     sm_rd_spfits
;
; Purpose:        sm_rd_spfits.pro reads in a spectral FITS file
;
; Synopsis:       sm_rd_spfits, infile, FITS_HDR=fhdr, SMART=smart
;
; Arguments:      Name      I/O Type:   Description:
;                 ----------------------------------------------------------
;                 infile    I           the spectral FITS file to be
;                                       read and processed
;                 fits_hdr  I           if this keyword is set, used
;                                       to return FITS header
;                 smart     I/O         setting this forces fuction to
;                                       return a SMART IRS structure 
;
; Returns:        if SMART keyword not set, data array is returned
;                 if SMART keyword set, SMART IRS structure is returned
;
; Description:    
;
; Dependencies    Calls:       sxaddpar
;                 Called from: N/A
;
; Comment:        sm_rd_spfits will load columns as follows
;                    0 wavelength
;                    1 flux
;                    2 flux_error
;                    3 order (also called segment)
;                    4 flag
;
;                 if the input file uses the keywords COL01DEF (etc.)
;                   these are used to identify the columns in the input file
;                 else missing columns are identified from unidentified
;                   input columns in the order wavelength, flux, flux_error
;
;                 if the order/segment column is not identified,
;                   rd_spfits will attempt to identify it, although
;                   the current algorithm could be led astray
;                 else an order/segment column is constructed from the
;                   NSEG keywords
;
;                 any additional columns follow the standard 5 initial columns
;
; Example:       result = sm_rd_fits('/home/me/test.fits', $
;                                 FITS_HDR = testheader, SMART = smart_irs)
;
; Category:      IDL / SMART
;
; Filename:      sm_rd_spfits.pro
;
; Author:        G.C. Sloan
;
; Version:       2.1
;
; History:
;                29 Jan 04 original version created by MJR - not used here
;                12 Feb 04 completely new version created by MJR
;                24 Feb 04 modified by GS to improve backwards
;                          compatibility
;                27 Jul 04 David Whelan, changed name from rd_spfits
;                          to sm_rdfits, and made appropriate syntax changes.
;                 6 Dec 04 GS changed some counters to long for SWS data
;
;##############################################################################
; 
; LICENSE
;
;  Copyright (C) 2004 Cornell University
;
;  This file is part of SMART.
;
;  SMART is free software; you can redistribute it and/or modify it
;  under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2, or (at your option)
;  any later version.
;  
;  SMART is distributed in the hope that it will be useful, but
;  WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;  General Public License for more details.
;  
;  You should have received a copy of the GNU General Public License
;  along with SMART; see the file COPYING.  If not, write to the Free
;  Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;  02111-1307, USA.
;
;##############################################################################
;#<


FUNCTION sm_rd_spfits,infile,FITS_HDR=fhdr,SMART=smart


; read the FITS file

a = readfits(infile,hdr,/silent)
dat = size(a)
ncols = dat(1)
nrows = dat(2)

; check the FITS header for the NSEG keyword
; if NSEG = 0 or NSEG not set, then this is NOT a spectral FITS file
; and a warning should be issued

nseg = sxpar(hdr,'NSEG')
if (nseg eq 0) then print,'Warning.  Not a spectral FITS file.'

; read the column labels in the FITS header (if any)
; keep track of undefined or nonstandard columns

labels       = strarr(ncols)
nonstd_col   = intarr(ncols)
undef_col    = intarr(ncols)
waveflag=0 & fluxflag=0 & fuflag=0 & ordflag=0 & flagflag=0

for i=0,ncols-1 do begin

   if (i lt 9) then val = string(format='("COL0",i1)',i+1) $
   else             val = string(format='("COL",i2)',i+1)
   val = val + 'DEF'
   labels[i] = sxpar(hdr,val)

   case strtrim(labels[i]) of
      'wavelength': waveflag=1
      'flux'      : fluxflag=1
      'flux_error': fuflag=1
      'order'     : ordflag=1
      'segment'   : ordflag=1
      'flag'      : flagflag=1
      0           : undef_col[i] = 1
      else        : nonstd_col[i] = 1
   endcase

endfor

; if they don't already exist, assume that unidentified columns are,
; in order:  wavelength, flux, flux_error

if (waveflag eq 0) then begin
  column=min(where(undef_col eq 1))
  if (column gt -1) then begin
    labels[column] = 'wavelength'
    undef_col[column] = 0
    waveflag = 1
  endif
endif

if (fluxflag eq 0) then begin
  column=min(where(undef_col eq 1))
  if (column gt -1) then begin
    labels[column] = 'flux'
    undef_col[column] = 0
    fluxflag = 1
  endif
endif

if (fuflag eq 0) then begin
  column=min(where(undef_col eq 1))
  if (column gt -1) then begin
    labels[column] = 'flux_error'
    undef_col[column] = 0
    fuflag = 1
  endif
endif

; if order column is not defined
; gather information using NSEG keywords and build an order column

if (ordflag eq 0) then begin

;  determine lengths of segments

   nseg = sxpar(hdr,'NSEG')
   seg_arr = lonarr(nseg)
   for i=0,nseg-1 do begin
      if (i lt 9) then val = string(format='("NSEG0",i1)',i+1) $
      else             val = string(format='("NSEG",i2)',i+1)
      seg_arr[i] = sxpar(hdr,val)
   endfor

;  generate a new order column and load with order information

   ordcol=fltarr(nrows)
   istart = long(0)
   istop = seg_arr[0]

   for i=0,nseg-1 do begin
      ordcol[istart:istop-1] = i+1
      istart = istop
      if (i lt nseg-1) then istop = istop + seg_arr[i+1]
   endfor

;  search undefined columns to see if an order column already exists

   for i=0,ncols-1 do begin
     if (undef_col[i] eq 1) then begin
       testorder=ordcol[0]
       ordidx=where(ordcol eq testorder)
       last=max(ordidx)
       if (min(a[i,ordidx]) eq max(a[i,ordidx]) and a[i,last] ne a[i,last+1]) $
         then begin
         labels[i] = 'order'
         ordflag = 1
         undef_col[i] = 0
       endif
     endif
   endfor

endif

; initialize reorganized array
; wish to retain all undefined and non-standard columns

colcount = 5 + total(undef_col) + total(nonstd_col)
b = fltarr(colcount,nrows)

; initialize array of output labels with first five (standard) columns

labelout = strarr(colcount)
labelout[0] = 'wavelength'
labelout[1] = 'flux'
labelout[2] = 'flux_error'
labelout[3] = 'order'
labelout[4] = 'flag'

; load columns in output array

col_idx = 5
for j=0,ncols-1 do begin

   case strtrim(labels[j]) of
      'wavelength': begin
                    b[0,*] = a[j,*]
                    sxaddpar,hdr,'COL01DEF','wavelength'
                    end
      'flux'      : begin
                    b[1,*] = a[j,*]
                    sxaddpar,hdr,'COL02DEF','flux'
                    end
      'flux_error': begin
                    b[2,*] = a[j,*]
                    sxaddpar,hdr,'COL03DEF','flux_error'
                    end
      'order'     : begin
                    b[3,*] = a[j,*]
                    sxaddpar,hdr,'COL04DEF','order'
                    end
      'segment'   : begin
                    b[3,*] = a[j,*]
                    sxaddpar,hdr,'COL04DEF','order'
                    end
      'flag'      : begin
                    b[4,*] = a[j,*]
                    sxaddpar,hdr,'COL05DEF','flag'
                    end
      else        : begin
                    b[col_idx,*] = a[j,*]
                    labelout[col_idx] = strtrim(labels[j])
                    col_idx = col_idx + 1
                    end
   endcase

endfor

if (ordflag eq 0) then b[3,*]=ordcol

; if called with keyword /SMART, then will need to return a
;   data structure instead of a data array

if (keyword_set(SMART)) then begin

   ; initialize data structure

   data={datum, wave:0.0, flux:0.0, stdev:0.0, order:0l,slitpos:0l, $
   module:0l,bcd:0l, status:0l,flag:0l}

   data_array = replicate(data,nrows)

   for i=0, nrows-1 do begin
      data_array[i].wave  = b[0,i]
      data_array[i].flux  = b[1,i]
      data_array[i].stdev = b[2,i]
      data_array[i].order = b[3,i]
      data_array[i].flag  = b[4,i]
   endfor

   ; manipulate header

   IRS_hdr=''
   sz=size(h)

   h_len=sz[1]
   for i=0,h_len-1 do IRS_hdr = IRS_hdr + hdr[i]
   for i=0,79 do      IRS_hdr = IRS_hdr + ' '

   ; initialize and create SMART structure

   outstruct = {type: 'IRS', header: '', history: strarr(1), data: data_array }
   outstruct.header = IRS_hdr
   outstruct.data   = data_array

   return,outstruct

endif else begin

; if SMART keyword not set load header into return variable and
;   return reorganized array

  fhdr = hdr ; return header
  return,b

endelse


END
