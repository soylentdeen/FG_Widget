pro precess_xyz,x,y,z,equinox1,equinox2
;+
;NAME
;	PRECESS_XYZ
;
;PURPOSE:
;	Precess equatorial geocentric rectangular coordinates. 
;
;CALLING SEQUENCE:
;	precess_xyz, x, y, z, equinox1, equinox2
;
;INPUT/OUTPUT:
;	x,y,z: scalars or vectors giving heliocentric rectangular coordinates
;              THESE ARE CHANGED UPON RETURNING.
; INPUT:
;	EQUINOX1: equinox of input coordinates
;       EQUINOX2: equinox of output coordinates
;
;OUTPUT:
;	x,y,z are changed upon return
;
;NOTES:
;   The equatorial geocentric rectangular coords are converted
;      to RA and Dec, precessed in the normal way, then changed
;      back to x, y and z using unit vectors.
;
;EXAMPLE:
;	Precess 1950 equinox coords x, y and z to 2000.
;	IDL> precess_xyz,x,y,z, 1950, 2000
;
;HISTORY:
;	Written by P. Plait/ACC March 24 1999 
;	   (unit vectors provided by D. Lindler)
;
;-

;check inputs
   if N_params() NE 5 then begin
      print,'Syntax - precess_xyz,x,y,z,equinox1,equinox2
      retall
   endif

; make a double precision radian to degree converter
   dtor = !dpi / 180.d0

;take input coords and convert to ra and dec. Note PRECESS
;   routine takes input in decimal degrees.

   ra = atan(y/x) / dtor
   del = sqrt(x*x + y*y + z*z)  ;magnitude of distance to Sun
   dec = asin(z/del)  / dtor

;   precess the ra and dec
    precess, ra, dec, equinox1, equinox2

;convert back to x, y, z
   xunit = cos(ra*dtor)*cos(dec*dtor)
   yunit = sin(ra*dtor)*cos(dec*dtor)
   zunit = sin(dec*dtor)

   x = xunit * del
   y = yunit * del
   z = zunit * del

   return
   end

