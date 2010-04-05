function helio_jd,date,ra,dec
;+
; NAME:
;	HELIO_JD
; PURPOSE:
;	Convert geocentric (reduced) Julian date to heliocentric Julian date
; EXPLANATION:
;	This procedure is used to correct for extra light travel time between 
;	the Earth and the Sun.
;
; CALLING SEQUENCE:
;	jdhelio = HELIO_JD( date, ra, dec)
;
; INPUTS
;	date - reduced Julian date (= JD - 2400000), scalar or vector, MUST
;		be double precision
;	ra,dec - scalars giving right ascension and declination in DEGREES
;
; OUTPUTS:
;	jdhelio - heliocentric julian date.
;
; EXAMPLE:
;	What is heliocentric julian date of an observation of V402 Cygni
;	(RA = 20 7 15, Dec = 37 0.33) taken June 15, 1973 at 11:40 UT?
;
;	IDL> juldate, [1973,6,15,11,40], jd      ;Get Geocentric julian date
;	IDL> hjd = helio_jd( jd, ten(20,7,15)*15., ten(37,0.33) )  
;                                                            
;	==> hjd = 41848.9881
;
; PROCEDURES CALLED:
;	zparcheck, xyz
;
; REVISION HISTORY:
; 	Algorithm from the book Astronomical Photometry by Henden, p. 114
;	Written,   W. Landsman       STX     June, 1989 
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2
 If N_params() LT 3 then begin
    print,'Syntax -   jdhelio = HELIO_JD( date, ra, dec)'
    print,'NOTE - Ra and Dec must be in degrees
 endif
    
 zparcheck,'HELIO_JD',date,1,[3,4,5],[0,1],'Reduced Julian Date'

 epsilon = 23.45/!RADEG     ;Obliquity of the ecliptic
 ra_rad = ra/!RADEG
 dec_rad = dec/!RADEG

 xyz, date, x, y, z

 return, double(date) - 0.0057755D*( cos(dec_rad)*cos(ra_rad)*x + $
                 (tan(epsilon)*sin(dec_rad) + cos(dec_rad)*sin(ra_rad))*y)

 end
