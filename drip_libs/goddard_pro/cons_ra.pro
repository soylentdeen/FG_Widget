FUNCTION CONS_RA,RA,Y,ASTR	;Find line of constant RA
;+
; NAME:
;	CONS_RA
; PURPOSE:
;	Obtain the X and Y coordinates of a line of constant right ascension
; EXPLANATION:
;	Return a set of X pixel values given an image with astrometry, 
;	and either
;	(1) a set of Y pixel values, and a scalar right ascension, or
;	(2) a set of right ascension values, and a scalar Y value.
;
;	In usage (1), CONS_RA can be used to determine the (X,Y) values
;	of a line of constant right ascension.  In usage (2), CONS_RA can
;	used to determine the X positions of specified RA values, along a
;	line of constant Y.
;
; CALLING SEQUENCE:
;	X = CONS_RA( RA, Y, ASTR)
;
; INPUTS:         
;	RA -  Right Ascension value in DEGREES (0 < RA < 2*PI).  If Y is a
;		vector, then RA must be a scalar
;	Y -   Specified Y pixel value(s) for line of constant right ascension
;		If RA is a vector, then Y must be a scalar
;	ASTR - Astrometry structure as extracted from a FITS header by the 
;		procedure EXTAST
; OUTPUTS
;	X   - Computed set of X pixel values.   The number of elements of X
;		is the maximum of the number of elements of RA and Y.
;
; RESTRICTIONS:
;	Program will have difficulty converging for declination values near
;	90.    For tangent projection only.  
;
; REVISION HISTORY:
;	Written, Wayne Landsman  STX Co.	April, 1988
;	Algorithm adapted from AIPS memo No. 27 by Eric Griessen
;	New astrometry structure
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
  On_error,2

  if ( N_params() LT 3 ) then begin
	print,'Syntax - X = CONS_RA( RA, Y, ASTR)'
        return, 0
  endif

  radeg = 180.0/!DPI
  crpix = astr.crpix
  crval = astr.crval/RADEG
  yy = y - ( crpix[1]-1. )    ;New coordinate origin, Unit pixel offset in CRPIX
  cdelt = [ [ astr.cdelt[0], 0.],[0., astr.cdelt[1] ] ]
  cdi = invert( cdelt # astr.cd/RADEG )     ;Griesen uses invert of CD matrix
  delra = ra/RADEG - crval[0]
  cdelra = cos( delra )    &    sdelra = sin( delra )
  cdel0 = cos( crval[1] )  &    sdel0 = sin( crval[1] )

  delta = atan( sdel0*cdelra*cdi[1,1] - sin(delra)*cdi[1,0] + yy*cdelra*cdel0, $
              cdel0*cdi[1,1] - yy*sdel0)

  delta = delta*RADEG
  ad2xy, ra, delta, astr, x

  return, x
  end
