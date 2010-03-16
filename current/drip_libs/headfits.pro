function HEADFITS, filename, EXTEN = exten
;+
; NAME:
;       HEADFITS
; PURPOSE:
;       Read a FITS (primary or extension) header into a string array.
; EXPLANATION:
;       Under Unix, HEADFITS() can also read gzip (.gz) or Unix compressed
;       (.Z) FITS files 
;
; CALLING SEQUENCE:
;       Result = HEADFITS( filename ,[ EXTEN = ])
;
; INPUTS:
;       FILENAME = String containing the name of the FITS file to be read.
;
; OPTIONAL INPUT KEYWORD:
;       EXTEN  = integer scalar, specifying which FITS extension to read.
;               For example, to read the header of the first extension set
;               EXTEN = 1.   Default is to read the primary FITS header 
;               (EXTEN = 0).
;
; OUTPUTS:
;       Result of function = FITS header, string array
;
; EXAMPLE:
;       Print the main FITS header of a file 'test.fits' into a string 
;       variable, h
;
;       IDL>  print, headfits( 'test.fits')
;
;       Print the second extension header of a gzip compressed FITS file
;       'test.fits.gz' (Unix only).  Use HPRINT for pretty format
;
;       IDL> hprint, headfits( 'test.fits.gz', 2)
;
; PROCEDURES CALLED
;       FXPOSIT(), MRD_HREAD
; MODIFICATION HISTORY:
;       adapted by Frank Varosi from READFITS by Jim Wofford, January, 24 1989
;       Keyword EXTEN added, K.Venkatakrishna, May 1992
;       Make sure first 8 characters are 'SIMPLE'  W. Landsman October 1993
;       Check PCOUNT and GCOUNT   W. Landsman    December 1994
;       Major rewrite, work for Unix gzip files,   W. Landsman  April 1996
;       Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2

 if N_params() LT 1 then begin
     print,'Sytax - header = headfits( filename, [ EXTEN = ])'
     return, -1
 endif

  if not keyword_set(exten) then exten = 0
  unit = fxposit( filename, exten, /READONLY)
  if unit EQ -1 then return,-1
  if eof(unit) then begin
        free_lun,unit
        message,'ERROR - Extension past EOF',/CON
        return,-1
  endif
  mrd_hread, unit, header, status
  free_lun, unit
 
  return, header
  end
