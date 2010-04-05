pro hcongrid, oldim, oldhd, newim, newhd, newx, newy, $
              INTERP=interp, OUTSIZE = outsize, CUBIC = cubic
;+
; NAME:
;	HCONGRID
; PURPOSE:
;	CONGRID an image and update astrometry in a FITS header
; EXPLANATION:
;	Expand or contract an image using CONGRID and update the 
;	associated FITS header array.
;
; CALLING SEQUENCE:
;	HCONGRID, oldhd                       ;Update FITS header only
;	HCONGRID, oldim, oldhd, [ newim, newhd, newx, newy, 
;				  CUBIC = , INTERP=, OUTSIZE =]
;
; INPUTS:
;	OLDIM - the original image array
;	OLDHD - the original image FITS header, string array
;
; OPTIONAL INPUTS:
;	NEWX - size of the new image in the X direction
;	NEWY - size of the new image in the Y direction
;		The OUTSIZE keyword can be used instead of the 
;		NEWX, NEWY parameters
;
; OPTIONAL OUTPUTS:
;	NEWIM - the image after expansion or contraction with CONGRID
;	NEWHD - header for newim containing updated astrometry info
;		If output parameters are not supplied, the program
;		will modify the input parameters OLDIM and OLDHD
;		to contain the new array and updated header.
;
; OPTIONAL KEYWORD INPUTS:
;	OUTSIZE - Two element integer vector which can be used instead of the
;		NEWX and NEWY parameters to specify the output image dimensions
;	INTERP   - 0 for nearest neighbor, 1 for bilinear interpolation
;		2 for cubic interpolation.   
;	CUBIC - If set and non-zero, then cubic interpolation is used
;		(equivalent to INTERP=2).  In IDL V5.0 and later, CUBIC can also
;		be a value between -1 and 0 (see ROT for more info).
; PROCEDURE:
;	Expansion or contraction is done using the CONGRID function.
;	neighbor. 
;	The parameters BSCALE, NAXIS1, NAXIS2, CRPIX1, and CRPIX2 and
;	the CD (or CDELT) parameters are updated for the new header.
;
; NOTES:
;	A FITS header can be supplied as the first parameter without having
;	to supply an image array.   The astrometry in the FITS header will be
;	updated to be appropriate to the specified image size.
;
; EXAMPLE:
;	Congrid an 512 x 512 image array IM and FITS header H to size 300 x 300
;	using cubic interpolation
;
;	IDL> hcongrid, IM ,H, OUT = [300, 300], INTERP = 2
;
;	The variables IM and H will be modified to the new image size.
;
; PROCEDURES CALLED:
;	CHECK_FITS, CONGRID(), EXTAST, GSSS_STDAST, SXADDHIST, SXADDPAR, 
;	SXPAR(), ZPARCHECK
; RESTRICTIONS:
;	Must be since IDL V3.5 so that the /CUBIC keyword to ROT is recognized
; MODIFICATION HISTORY:
;	Written, Aug. 1986 W. Landsman, STI Corp.
;	Added interp keywords, J. Isensee, July, 1990
;	Add cubic interpolation W. Landsman HSTX   January 1994
;	Recognize a GSSS FITS header   W. Landsman   June 1994
;	Fix case where header but not image supplied  W. Landsman  May 1995
;	Remove call to SINCE_VERSION()   W. Landsman   March 1996
;	Assume since IDL V3.5, add CUBIC keyword      W. Landsman   March 1997
;	Update BSCALE even if no astrometry present   W. Landsman   May 1997
;	Converted to IDL V5.0   W. Landsman   September 1997
;- 
 On_error,2
 Npar = N_params()	;Check # of parameters

 if Npar EQ 0  then begin 
     print,'    Syntax - HCONGRID, oldim, oldhd,[ newim, newhd, newx, newy
     print,'                                CUBIC = , INTERP =, OUTSIZE = ]'
     return
 endif

 if Npar EQ 1 then begin 

        zparcheck, 'HCONGRID', oldim, 1, 7, 1, 'Image header'
	oldhd = oldim
        xsize = sxpar( oldhd,'NAXIS1')
        ysize = sxpar( oldhd,'NAXIS2')

 endif else begin
;               ;                                    Check for valid 2-D image & header
  check_FITS, oldim, oldhd, dimen, /NOTYPE
  if !ERR EQ -1 then message,'ERROR - Invalid image or FITS header array'
  if N_elements(dimen) NE 2 then message, $
     'ERROR - Input image array must be 2-dimensional'
  xsize = dimen[0]  &  ysize = dimen[1]
 endelse
 
 if keyword_set(CUBIC) then interp = 2
 if N_elements(interp) EQ 0 then interp = 1

 case interp of 
 0:   type = ' Nearest Neighbor Approximation'
 1:   type = ' Bilinear Interpolation'
 2:   type = ' Cubic Interpolation'
 else: message,'ERROR - Illegal value of INTERP keyword, must be 0, 1, or 2'
 endcase

 if npar LT 6 then begin
    if ( N_elements(OUTSIZE) NE 2 ) then begin
      message, /INF, $
        'Original array size is '+ strn( xsize ) + ' by ' + strn(ysize)
      read,'Enter size of new image in the X direction: ',newx
      read,'Enter size of new image in the Y direction: ',newy
   endif else begin
      newx = outsize[0]
      newy = outsize[1]
   endelse 
 endif
 
 if ( xsize EQ newx ) and ( ysize EQ newy ) then message, $
            'ERROR - Output image size equals input image size'


 if ( npar GT 1 ) then begin

 if ( npar GT 2 ) then begin
	newim = congrid( oldim, newx, newy, INTERP = interp, CUBIC = cubic)
 endif else begin
	oldim = congrid( temporary(oldim), newx, newy, $
		CUBIC = cubic, INTERP=interp )
 endelse

 endif

 newhd = oldhd
 sxaddpar, newhd, 'NAXIS1', fix(newx)
 sxaddpar, newhd, 'NAXIS2', fix(newy)
 label = 'HCONGRID:' + strmid(systime(),4,20)
 history =   ' Original Image Size Was '+ strn(xsize) + ' by ' + strn(ysize)
 sxaddhist, label + history, newhd
 if npar GT 1 then sxaddhist, label+type, newhd

; Update astrometry info if it exists

 extast, newhd ,astr, noparams
 if noparams GE 0 then begin
 if strmid(astr.ctype[0],5,3) EQ 'GSS' then begin
	gsss_stdast, newhd
	extast, newhd, astr, noparams
 endif

 xratio = float(newx) / xsize	;Expansion or contraction in X
 yratio = float(newy) / ysize	;Expansion or contraction in Y
 pix_ratio = xratio*yratio	;Ratio of pixel areas
 
  crpix = astr.crpix
  sxaddpar, newhd, 'CRPIX1', (crpix[0]-0.5)*xratio + 0.5, FORMAT='(E14.7)'
  sxaddpar, newhd, 'CRPIX2', (crpix[1]-0.5)*yratio + 0.5, FORMAT='(E14.7)'

 if (noparams EQ 0) or ( noparams EQ 1) then begin 

    cdelt = astr.cdelt
    sxaddpar, newhd, 'CDELT1', CDELT[0]/xratio
    sxaddpar, newhd, 'CDELT2', CDELT[1]/yratio

 endif else if noparams EQ 2 then begin

    cd = astr.cd
    sxaddpar, newhd, 'CD1_1', cd[0,0]/xratio, FORMAT='(E14.7)'
    sxaddpar, newhd, 'CD1_2', cd[0,1]/yratio, FORMAT='(E14.7)'
    sxaddpar, newhd, 'CD2_1', cd[1,0]/xratio, FORMAT='(E14.7)'
    sxaddpar, newhd, 'CD2_2', cd[1,1]/yratio, FORMAT='(E14.7)'

 endif
 endif 

; Update BSCALE and BZERO if needed

 bscale = sxpar( oldhd,'BSCALE')
 if (!ERR NE -1) and ( bscale NE 1 ) then $
     sxaddpar, newhd, 'BSCALE', bscale/pix_ratio

 bzero = sxpar( oldhd,'BZERO')
 if (!ERR NE -1) and ( bzero NE 0) then $
       sxaddpar, newhd, 'BZERO', bzero/pix_ratio

 if npar EQ 2 then oldhd = newhd else $
       if npar EQ 1 then oldim = newhd

 return
 end
