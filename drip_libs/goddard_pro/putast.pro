 pro putast, hdr, astr, crpix, crval, crtype, EQUINOX=equinox, $
				CD_TYPE = cd_type
;+
; NAME:
;    PUTAST
; PURPOSE:
;    Put astrometry parameters into a given FITS header.
;
; CALLING SEQUENCE:
;     putast, hdr              ;Prompt for all values
;               or
;     putast, hdr, astr, [EQUINOX =, CD_TYPE = ]
;               or
;     putast, hdr, cd,[ crpix, crval], [ EQUINOX =, CD_TYPE = ]
;
; INPUTS:
;     HDR -  FITS header, string array.   HDR will be updated to contain
;             the supplied astrometry.
;     ASTR - IDL structure containing values of the astrometry parameters
;            CDELT, CRPIX, CRVAL, CTYPE, LONGPOLE, PROJP1, and PROJP2
;            See EXTAST.PRO for more info about the structure definition
;                            or
;     CD   - 2 x 2 array containing the astrometry parameters CD1_1 CD1_2
;                                                             CD2_1 CD2_2
;              in units of DEGREES/PIXEL
;     CRPIX - 2 element vector giving X and Y coord of reference pixel
;              BE SURE THE COORDINATES IN CRPIX ARE GIVEN IN FORTRAN STANDARD
;              (e.g. FIRST PIXEL IN IMAGE IS (1,1) )
;     CRVAL - 2 element vector giving R.A. and DEC of reference pixel 
;               in degrees
;
; OUTPUTS:
;      HDR - FITS header now contains the updated astrometry parameters
;               A brief HISTORY record is also added.
;
; OPTIONAL KEYWORD INPUTS:
;      EQUINOX - numeric scalar giving equinox (e.g. 2000) of the reference 
;                coordinates 
;
;       CD_TYPE - Scalar, either 0, 1 , or 2 specifying how the CD matrix
;                is to be written into the header
;               (0) as CD00n00m values 
;               (1) convert to rotation and write as a CROTA2 value
;               (2) as CDn_m value (as used by IRAF)
;
;               As of October 1998, the consensus is that form (2) will
;               become the FITS standard, but this has not yet received final
;               approval.      Form (0) is based on an early proposed standard
;               and will almost certainly not be used.    Since form
;               (2) is used for HST images, it almost certainly will be 
;               supported in the future.     The document "Representations of 
;               Celestial Coordinates in FITS" by Griesen and Calabretta at   
;               http://www.cv.nrao.edu/fits/documents/wcs/wcs.html discusses
;               these issues but note this is only a draft.
;               If CD_TYPE is not supplied, PUTAST will try to determine the 
;               type of astrometry already in the header.   If there is no 
;               astrometry in the header then the default is CD_TYPE = 2
; NOTES:
;       The recommended use of this procedure is to supply an astrometry
;       structure.    
;
; PROMPTS:
;       If only a header is supplied, the user will be prompted for a plate 
;       scale, the X and Y coordinates of a reference pixel, the RA and
;       DEC of the reference pixel, the equinox of the RA and Dec and a 
;       rotation angle.
;
; PROCEDURES USED:
;       DATATYPE(), GETOPT(), GET_COORDS, SXADDPAR, SXPAR(), ZPARCHECK
; REVISION HISTORY:
;       Written by W. Landsman 9-3-87
;       Major rewrite, use new astrometry structure   March, 1994
;       Use both CD and CDELT to get plate scale for CD_TYPE=1   September 1995
;       Use lower case for FITS keyword Comments  W.L.    March 1997
;       Fixed for CD_TYPE=1 and CDELT = [1.0,1.0]   W.L   September 1997
;       Default value of CD_TYPE is now 2, Use GET_COORDS to read coordinates
;       to correct -0 problem           W.L.  September 1997
;       Update CROTA1 if it already exists  W.L. October 1997
;       Convert rotation to degrees for CD_TYPE = 1  W. L.   June 1998
;       Convert to IDL V5.0    W.L. June 1998
;       Accept CD_TYPE = 0 keyword input   W.L   October 1998
;-
 npar = N_params()

 if ( npar EQ 0 ) then begin	;Was header supplied?
	print,'Syntax: PUTAST, astr, [ EQUINOX = , CD_TYPE = ]
	print,'       or
	print,'Syntax: PUTAST, Hdr, [ cd, crpix, crval, EQUINOX = , CD_TYPE =]   
	return
 end

 zparcheck, 'PUTAST', hdr, 1, 7, 1, 'FITS image header'

 if ( npar EQ 1 ) then begin            ;Prompt for astrometry parameters?
   read,'Enter plate scale in arc seconds/pixel: ',cdelt
   inp =''
   print,'Reference pixel position should be in FORTRAN convention'
   print,'(First pixel has coordinate (1,1) )'
   GETCRPIX: print, $
  'Enter X and Y position of a reference pixel ([RETURN] for plate center)'
   read, inp
   if ( inp EQ '' ) then $ 
          crpix = [ sxpar(hdr,'NAXIS1'), sxpar(hdr,'NAXIS2')] / 2. $
     else crpix = getopt( inp, 'F')

   if N_elements( crpix ) NE 2 then begin
      print,'PUTAST: INVALID INPUT - Enter 2 scalar values'
      goto, GETCRPIX     
   endif

RD_CEN:
   inp = ''
   read,'Enter RA (hrs) and Dec (degrees) of reference pixel:',inp
   GET_COORDS, crval,in=inp
   if crval[0] EQ -999 then goto, rd_cen

   crval[0] = crval[0]*15.
 
   inp = ''
   read,'Enter rotation angle in degrees, clockwise, from north [0.]: ',inp
   rotat = getopt(inp,'F')/!RADEG
   cd = (cdelt / 3600.)*[ [-cos(rotat),-sin(rotat)], [-sin(rotat), cos(rotat)] ]
   npar = 4
 endif else begin

   if datatype(astr) EQ 'STC' then begin       ;User supplied astrometry structure
	cd = astr.cd
	cdelt = astr.cdelt
	crval = astr.crval
	crpix = astr.crpix
	ctype = astr.ctype
   endif else  begin
	cd = astr
	zparcheck,'PUTAST', cd, 2, [4,5], 2, 'CD matrix'
   endelse
 endelse

;   Add CTYPE to FITS header

 if N_elements( ctype ) GE 2 then begin

 sxaddpar,hdr,'CTYPE1',ctype[0],' Coordinate Type','HISTORY'
 sxaddpar,hdr,'CTYPE2',ctype[1],' Coordinate Type','HISTORY'

 endif

;   Add EQUINOX keyword and value to FITS header

 if N_elements( equinox ) EQ 0 then begin
    equinox = sxpar( hdr, 'EQUINOX')            ;Is EQUINOX already in header?
    if !ERR eq -1 then begin
      read,'Enter equinox for reference pixel coordinates (e.g. 2000): ',equinox
    if (equinox LT 1850.) or (equinox GT 2100.) then message, $
     'Equinox value of '+ strtrim(equinox,2) + ' not added to header', /INFORM $
   else sxaddpar, hdr, 'EQUINOX', equinox, ' Equinox of Ref. Coord.', 'HISTORY'
   endif 

 endif else $
     sxaddpar,hdr, 'EQUINOX', equinox, 'Equinox of Ref. Coord.', 'HISTORY'

; Add coordinate description (CD) matrix to FITS header
; CD_TYPE = 0: CD001001 + CDELT   1. CROTA + CDELT     2: CD1_1 
  
 
 if (N_elements(cd_type) EQ 0) then begin
 cd_type = 2
 cd1_1 = sxpar( hdr, 'CD1_1', COUNT = N_CD)
 if N_CD EQ 0 then begin
	cd1_1 = sxpar( hdr, 'CD001001', COUNT = N_CD)
        if N_CD GE 1 then CD_TYPE = 0 else begin 
		CDELT1 = sxpar( hdr,'CDELT1', COUNT = N_CDELT1)
		if N_CDELT1 GE 1 then cd_type = 1
	endelse
 endif
 endif

 if cd_type EQ 0 then begin
    sxaddpar, hdr, 'CD001001', cd[0,0], ' Degrees / Pixel', 'HISTORY'
    sxaddpar, hdr, 'CD002001', cd[1,0], ' Degrees / Pixel', 'HISTORY'
    sxaddpar, hdr, 'CD001002', cd[0,1], ' Degrees / Pixel', 'HISTORY'
    sxaddpar, hdr, 'CD002002', cd[1,1], ' Degrees / Pixel', 'HISTORY'

 	if N_elements(CDELT) GE 2 then begin
		sxaddpar, hdr, 'CDELT1', cdelt[0]
		sxaddpar, hdr, 'CDELT2', cdelt[1]
	endif
 endif else if cd_type EQ 2 then begin

    if N_elements(CDELT) GE 2 then if (cdelt[0] NE 1.0) then begin
            cd[0,0] = cd[0,0]*cdelt[0] & cd[0,1] = cd[0,1]*cdelt[0]
            cd[1,1] = cd[1,1]*cdelt[1] & cd[1,0] = cd[1,0]*cdelt[1]
    endif

    sxaddpar, hdr, 'CD1_1', cd[0,0], ' Degrees / Pixel', 'HISTORY'
    sxaddpar, hdr, 'CD2_1', cd[1,0], ' Degrees / Pixel', 'HISTORY'
    sxaddpar, hdr, 'CD1_2', cd[0,1], ' Degrees / Pixel', 'HISTORY'
    sxaddpar, hdr, 'CD2_2', cd[1,1], ' Degrees / Pixel', 'HISTORY'

 endif else begin

	rot = float(atan( cd[0,1], cd[1,1] )*180.0d/!DPI)	

; Programs should only look for CROTA2, but we also update CROTA1 if it already
; exists.   Also keep existing comment field if it exists.

	crota2 = sxpar(hdr,'CROTA2', Count = N_crota2)
	if N_crota2 GT 0 then sxaddpar, hdr, 'CROTA2', rot else $
		sxaddpar, hdr, 'CROTA2', rot, ' Rotation Angle (Degrees)'
        crota1 = sxpar(hdr,'CROTA1', Count = N_crota1)
	if N_crota1 GT 0 then $
		 sxaddpar, hdr, 'CROTA1', rot       
 	if N_elements(CDELT) GE 2 then begin
                if cdelt[0] NE 1.0 then delt = cdelt else begin
			det = cd[0,0]*cd[1,1] - cd[0,1]*cd[1,0]
			if det LT 0 then sgn = -1 else sgn = 1
			delt = [sgn*sqrt(cd[0,0]^2 + cd[1,0]^2), $
				     sqrt(cd[0,1]^2 + cd[1,1]^2) ]
			endelse
		sxaddpar, hdr, 'CDELT1', delt[0]
		sxaddpar, hdr, 'CDELT2', delt[1]
	endif

 endelse

 hist = ' CD Matrix Written'

; Add CRPIX keyword to FITS header

 if N_elements( crpix ) GE 2  then begin		;Add CRPIX vector?

	zparcheck, 'PUTAST', crpix, 3, [1,2,4,3,5], 1, 'CRPIX vector'

        sxaddpar, hdr, 'CRPIX1',crpix[0], ' Reference Pixel in X','HISTORY'
        sxaddpar, hdr, 'CRPIX2',crpix[1], ' Reference Pixel in Y','HISTORY'

	hist = ' CD and CRPIX parameters written'
 endif

;  Add CRVAL keyword and values to FITS header.   Convert CRVAL to double
;  precision to ensure enough significant figures

 if N_elements( crval ) GE 2 then begin		

	zparcheck, 'PUTAST', crval, 3, [2,4,3,5], 1, 'CRVAL vector'
	sxaddpar, hdr, 'CRVAL1', double(crval[0]), ' R.A. (Degrees)', 'HISTORY'
	sxaddpar, hdr, 'CRVAL2', double(crval[1]), ' Dec  (Degrees)', 'HISTORY'
	hist = ' CD, CRPIX and CRVAL parameters written'

  endif
 
 sxaddhist,'PUTAST: ' + strmid(systime(),4,20) + hist,hdr

 return
 end
