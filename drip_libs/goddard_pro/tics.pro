pro tics,min,max,numx,ticsize,incr,RA=ra
;+
; NAME:
;	TICS
; PURPOSE:
;	Compute a nice increment between tic marks for astronomical images.
; EXPLANATION:
;	For use in labelling a displayed image with right ascension
;	and declination axes.  An approximate distance between tic 
;	marks is input, and a new value is computed such that the 
;	distance between tic marks is in simple increments of the 
;	tic label values.
;
; CALLING SEQUENCE:
;	tics, min, max, numx, ticsize, incr, [RA = ]
;
; INPUTS:
;	min - minimum axis value (degrees)
;	max - maximum axis value (degrees)
;	numx  - number of pixels in x direction
;
; INPUT/OUTPUT  
;	ticsize - distance between tic marks (pixels)
;
; OUTPUTS:
;	incr    - incremental value for tic labels (in minutes of 
;		time for R.A., minutes of arc for dec.)
;
; REVISON HISTORY:
;	written by B. Pfarr, 4/14/87
;	Added some more tick precision (i.e. 1 & 2 seconds in case:) EWD May92
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
  On_error,2

  numtics = numx/ticsize                   ;initial number of tics

;     Convert total distance to arc minutes for dec. or to
;     minutes of time for r.a.

  if keyword_set( RA ) then mul = 4.0 else mul = 60.0
  mins = abs(min-max)*mul                  ;total distance in minutes
  rapix = numx/mins                        ;pixels per minute
  incr = mins/numtics                      ;minutes per tic

;                                        determine increment
  case 1 of 
    incr GE 120.0  : incr = 480.0       ; 4 hours
    incr GE  60.0  : incr = 120.0       ; 2 hours
    incr GE  30.0  : incr =  60.0       ; 1 hour
    incr GE  15.0  : incr =  30.0       ; 30 minutes 
    incr GE  10.0  : incr =  15.0       ; 15 minutes
    incr GE   5.0  : incr =  10.0       ; 10 minutes
    incr GE   2.0  : incr =   5.0       ;  5 minutes
    incr GE   1.0  : incr =   2.0       ;  2 minutes
    incr GE   0.5  : incr =   1.0       ;  1 minute
    incr GE   0.25 : incr =   0.5       ; 30 seconds
    incr GE   0.16 : incr =   0.25      ; 15 seconds
    incr GE   0.08 : incr =   0.16666667; 10 seconds
    incr GE   0.03 : incr =   0.08333333;  5 seconds
    incr GE   0.015: incr =   0.03333333;  2 seconds
    incr GE   0.00 : incr =   0.01666667;  1 seconds
  endcase

   ticsize = rapix*incr                 ;determine ticsize
   if ( min GT max ) then incr = -incr

   return 
  end
