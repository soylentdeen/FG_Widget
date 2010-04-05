PRO HELIO, JD, HMS, LIST, HRAD, HLONG, HLAT
;+
; NAME: 
;	HELIO
; PURPOSE: 
;	Compute (low-precision) Heliocentric coordinates for the planets.
; EXPLANATION:
;	Adapted from the book Celestial Basic
; CALLING SEQUENCE: 
;	HELIO, JD, HMS, LIST, HRAD, HLONG, HLAT
; INPUTS:
;	JD = Julian day to compute for, long scalar
;	HMS = hours, minutes, seconds array: H, M, S.  Universal time.
;	LIST = List of planets array.  May be a single number.
;		1 = merc, 2 = venus, ... 9 = pluto.
;
; OUTPUTS:
;	HRAD = array of Heliocentric radii (A.U).
;	HLONG = array of Heliocentric (ecliptic) longitudes (degrees).
;	HLAT = array of Heliocentric latitudes (degrees).
;		These values are scalars if LIST is a scalar.
;
; EXAMPLE:
;	To find the heliocentric positions of Jupiter and Saturn on 1-Jan-1989
;
;	JDCNV,1989,1,1,0,JD                   ;Convert to Julian Date 
;	HELIO,JD,[0,0,0],[5,6],hrad,hlong,hlat  ;Get radius, long, and lat
;
; COMMON BLOCKS: 
;	HELIOCOM --- stores parameters.
;
; ROUTINES USED: 
;	DATATYPE, ISARRAY,
; MODIFICATION HISTORY: 
;	R. Sterner.  20 Aug, 1986.
;	Code cleaned up a bit      W. Landsman             December 1992
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
  On_error,2

  common heliocom, heliodef, pd,jd0, pi2

  if N_params() lt 3 then begin
     print,'Syntax - Helio, jd, hms, list, hrad, hlong, hlat'
     return
  endif

;------------------  Initialize common  ----------------------
  if Datatype( heliodef ) EQ 'UND' then begin  

	  heliodef = 1	  				; common set up flag.
	  PD = [[0.071422, 3.8484, 0.388301, 1.34041, 0.3871,$	; merc.
                 0.07974, 2.73514, 0.122173, 0.836013],$
		[0.027962, 3.02812, 0.013195, 2.28638, 0.7233,$	; ven.
		 0.00506, 3.85017, 0.059341, 1.33168],$
		[0.017202, 1.74022, 0.032044, 1.78547, 1.,$	; earth
		 0.017, 3.33929, 0., 0.],$
		[0.009146, 4.51234, 0.175301, 5.85209, 1.5237,$	; mars
		 0.141704, 1.04656, 0.03142, 0.858702],$
		[0.00145, 4.53364, 0.090478, 0.23911, 5.2028,$	; jup.
		 0.249374, 1.76188, 0.01972, 1.74533],$
		[0.000584, 4.89884, 0.105558, 1.61094, 9.5385,$	; sat.
		 0.534156, 3.1257, 0.043633, 1.977458],$
		[0.000205, 2.46615, 0.088593, 2.96706, 19.182,$	; uran.
		 0.901554, 4.49084, 0.01396, 1.28805],$
		[0.000104, 3.78556, 0.016965, 0.773181, 30.06,$	; nep.
		 0.27054, 2.33498, 0.031416, 2.29162],$
		[0.000069, 3.16948, 0.471239, 3.91303, 39.44,$	; pluto
		 9.86, 5.23114, 0.300197, 1.91812]]
	  JD0 = 2436935		           ; Julian Date of 1-1-1960
	  PI2 = 2*!PI				; 2 pi.

  endif  

;-----------------  Make sure LIST is an array  ----------------
  aflag = ISARRAY( list )	 	; 0 = scalar, 1 = array.
  nl = N_elements( list )	  	; number of planets to process.

;-----------------  Days since Epoch  ---------------
  FRAC = HMS[0]/24. + HMS[1]/1440. + HMS[2]/86400.
  ND = JD - JD0 + FRAC

;-----------------  Loop thru planets  --------------
  hrad = fltarr(nl)
  hlong = fltarr(nl)
  hlat = fltarr(nl)
;
  for p = 0, nl-1 do begin

	ip = list[p] - 1
;-------  Heliocentric longitude  ---------
	x = nd*pd[0,ip] + pd[1,ip]
	x = x + pd[2,ip]*sin(x-pd[3,ip])
	x = x mod pi2
	hlong[p] = x*!radeg				; Degrees. 

;-------  Heliocentric distance  ----------
	HRAD[P] = PD[4,IP] + PD[5,IP]*SIN(X - PD[6,IP])  ; A.U.

;-------  Heliocentric latitude  ----------
	HLAT[P] = PD[7,IP]*SIN(X - PD[8,IP])*!RADEG	; degrees.
  
  endfor
;
;------------------  Return results  ------------------------
   if aflag EQ 0 then begin       ;Convert back to scalar?

	  hlong = hlong[0]
	  hlat = hlat[0]
	  hrad = hrad[0]

   endif

   return
   end
