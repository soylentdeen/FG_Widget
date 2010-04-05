pro t_getpsf,image,fitsfile,idpsf,psfrad,fitrad,psfname, $ 
             NEWTABLE = newtable, DEBUG = debug
;+
; NAME:
;	T_GETPSF
; PURPOSE:
;	Driver procedure (for GETPSF) to generate a PSF from isolate stars.
; EXPLANATION:
;	Generates a point-spread function from one or more isolated stars.
;	List of stars is read from the FITS ASCII table output of T_APER.
;	PSF is represented as a sum of a Gaussian plus residuals.
;	Ouput residuals are written to a FITS image file.
;
; CALLING SEQUENCE:
;	T_GETPSF, image, fitsfile, [ idpsf, psfrad, fitrad, psfname, 
;					/DEBUG, NEWTABLE =]
;
; INPUTS:
;	IMAGE - image array
;	FITSFILE  - scalar string giving name of disk FITS ASCII table.  Must 
;		contain the keywords 'X','Y' (from T_FIND) and 'AP1_MAG','SKY'
;		(from T_APER).
;
; OPTIONAL INPUTS:
;	IDPSF - vector of stellar ID indices indicating which stars are to be 
;		used to create the PSF.    Not that the PSF star should be 
;		specified *not* by its STAR_ID value, but rather by the its 
;		row number (starting with 0) in the FITS table
;	PSFRAD - the radius for which the PSF will be defined
;	FITRAD - fitting radius, always smaller than PSFRAD
;	PSFNAME - name of FITS image file to contain PSF residuals,
;		scalar string
;	GETPSF will prompt for all the above values if not supplied.
;
; OPTIONAL KEYWORD INPUT
;	NEWTABLE - scalar string specifying the name of the output FITS ASCII
;		table.   If not supplied, then the input table is updated with
;		the keyword PSF_CODE, specifying which stars were used for the
;		PSF.
;	DEBUG - if this keyword is set and non-zero, then the result of each
;		fitting iteration will be displayed.
;
; PROMPTS:
;	T_GETPSF will prompt for the readout noise (in data numbers), and
;	the gain (in photons or electrons per data number) so that pixels can
;	be weighted during the PSF fit.   To avoid the prompt, add the 
;	keywords RONOIS and PHPADU to the FITS ASCII table header.     
;
; PROCEDURES USED:
;	FTADDCOL, FTGET(), FTPUT, GETPSF, READFITS(), SXADDHIST, SXADDPAR, 
;	SXPAR(), WRITEFITS, ZPARCHECK
; REVISION HISTORY:
;	Written  W. Landsman     STX           May, 1988
;	Update PSF_CODE to indicate PSF stars in order used, W. Landsman Mar 96
;	I/O to FITS ASCII disk files  W. Landsman    May 96
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2

 if N_params() LT 2 then begin
	print,'Syntax - T_GETPSF, image, fitsfile, [ idpsf, psfrad, fitrad,'+ $ 
	      '/DEBUG, NEWTABLE = ]
        return
 endif 

 zparcheck,'T_GETPSF',image,1,[1,2,3,4,5],2,'image array'
 zparcheck,'T_GETPSF',fitsfile,2,7,0,'name of disk FITS ASCII table'
 if not keyword_set(newtable) then newtable = fitsfile

 dummy = readfits(fitsfile, hprimary,/SILENT)
 if !ERROR GT 0 then return
 tab = readfits(fitsfile,h,/ext)

 x = ftget(h,tab,'X') - 1.
 y = ftget(h,tab,'Y') - 1.
 apmag = ftget(h,tab,'AP1_MAG')
 sky = ftget(h,tab,'SKY')

 ronois = sxpar(hprimary,'RONOIS')     ;Try to get read-out noise from header
 if !ERR EQ -1 then begin
    read,'Enter the read-out noise in ADU per pixel: ',ronois
    print,'Storing readout noise  of ',strtrim(ronois,2),' in header'
    sxaddpar,hprimary,'RONOIS',ronois,'Read out noise (ADU/pixel)', $
	before = 'HISTORY'
 endif

 phpadu = sxpar(hprimary,'PHPADU')        ;Try to get photons per ADU
 if !ERR ne -1 then begin
       print,'Using photon/ADU value of ',phpadu
 endif else begin
       read,'Enter photons per ADU:  ',phpadu
       print,'Storing photon/ADU of ',strtrim(phpadu,2),' in header'
       sxaddpar,hprimary,'PHPADU',phpadu,'Photons Per ADU',before='HISTORY'
 endelse

 getpsf,image,x,y,apmag,sky,ronois,phpadu,gauss,psf,idpsf,psfrad,fitrad,psfname

 if psfname NE '' then begin
   code = bytarr(N_elements(apmag))
   code[idpsf] = indgen(N_elements(idpsf)) + 1
   ftinfo,h,'PSF_CODE'
   if !ERR eq -1 then ftaddcol,h,tab,'PSF_CODE',2,'I1'
   ftput,h,tab,'PSF_CODE',0,code
   sxaddpar,h,'EXTNAME','IDL DAOPHOT: GETPSF','DAOPHOT stage'
   sxaddpar,h,'PSF_NAME',psfname,'Name of PSF Image','TTYPE1'
   sxaddhist,'T_GETPSF: ' + systime(),h
   writefits, newtable, 0, hprimary
   writefits, newtable, tab,h,/append
 endif else print,'No PSF file created; Table not updated'

  return
 end
