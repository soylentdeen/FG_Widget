PRO XMEDSKY, Image, Bkg, CLIP=clip
;+
; NAME:
;       XMEDSKY
;
; PURPOSE:
;       Subtract sky from an image as a 1-D function of X
; EXPLANATION:
;       The sky is the column-by-column median of pixels within 3
;       sigma of the image global median.  Default is [32, 1023, 12,
;       499], appropriate for STIS slitless spectra binned 1 X 2.
;       This procedure is called by the cosmic ray rejection routine
;       CR_REJECT
;
; CALLING SEQUENCE:
;       XMEDSKY, Image, Bkg, [ CLIP = ]
;
; INPUTS:
;       Image:  Input image for which sky vector is to be computed.
;	
; INPUT KEYWORD PARAMETERS:
;       CLIP:   [x0, x1, y0, y1]: region of image to be used for all
;               statistical computations.
;
; OUTPUT PARAMETER:
;       Bkg:    Vector of sky values.
;
; PROCEDURE CALLS:
;	STDEV() - In /obsolete directory of standard IDL distribution
;       If since V5.1 then the STDDEV function is used instead.
;
; MODIFICATION HISTORY:
; 	Written by:	R. S. Hill, Hughes STX, 20 Oct. 1997
;       Converted to V5.0, use STDDEV()   W. Landsman   June 1998
;-
 if N_params() LT 2 then begin
        print,'Syntax - Xmedsky, Image, Bkg, [CLIP = ]'
        return
 endif
 IF n_elements(clip) LT 1 THEN clip=[32,1012,12,499]
 sz = size(image)
 nbkg = sz[1]
 bkg = fltarr(nbkg)
 FOR i=0,nbkg-1 DO $
   bkg[i]=median(transpose(image[i,*]))
 tmpimg=image
 FOR i=0,sz[2]-1 DO tmpimg[0,i] = image[*,i] - bkg
 totmed = median(tmpimg[clip[0]:clip[1],clip[2]:clip[3]])
 if !VERSION.RELEASE GE '5.1' then $
         totsdv = stddev(tmpimg[clip[0]:clip[1],clip[2]:clip[3]]) $
    else totsdv = stdev(tmpimg[clip[0]:clip[1],clip[2]:clip[3]])
 mask = byte(0*image+1)
 nsig=3
 mask[where(abs(temporary(tmpimg)-totmed) GT (nsig*totsdv))] = 0
 FOR i=0,nbkg-1 DO $
   bkg[i]=median(transpose(image[i,clip[2]+where(mask[i,clip[2]:clip[3]])]))
 return
 END

