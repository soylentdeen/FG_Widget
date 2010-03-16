function boxave, array, xsize, ysize
;+
; NAME:
;	BOXAVE
; PURPOSE:
;	Box-average a 1 or 2 dimensional array.  
; EXPLANATION:
;	This procedure differs from the intrinsic REBIN function in the 
;	following two ways: 
;
;	(1) the box size parameter is specified rather than the output 
;		array size
;	(2) for INTEGER arrays, BOXAVE computes intermediate steps using REAL*4 
;		arithmetic.   This is considerably slower than REBIN but avoids 
;		integer truncation
;
; CALLING SEQUENCE:
;	result = BOXAVE( Array, Xsize,[ Ysize ] )     
;
; INPUTS:
;	ARRAY - Two dimensional input Array to be box-averaged.  Array may be 
;		one or 2 dimensions and of any type except character.   
;
; OPTIONAL INPUTS:
;	XSIZE - Size of box in the X direction, over which the array is to
;		be averaged.  If omitted, program will prompt for this 
;		parameter.  
;	YSIZE - For 2 dimensional arrays, the box size in the Y direction.
;		If omitted, then the box size in the X and Y directions are 
;		assumed to be equal
;
; OUTPUT:
;	RESULT - Output array after box averaging.  If the input array has 
;		dimensions XDIM by YDIM, then RESULT has dimensions
;		XDIM/NBOX by YDIM/NBOX.  The type of RESULT is the same as
;		the input array.  However, the averaging is always computed
;		using REAL arithmetic, so that the calculation should be exact.
;		If the box size did not exactly divide the input array, then
;		then not all of the input array will be boxaveraged.
;
; PROCEDURE:
;	BOXAVE boxaverages all points simultaneously using vector subscripting
;
; NOTES:
;	If im_int is a 512 x 512 integer array, then the two statements
;
;		IDL> im = fix(round(rebin(float(im_int), 128, 128)))
;	        IDL> im  = boxave( im_int,4)
;
;	give equivalent results.   The use of REBIN is faster, but BOXAVE is
;	is less demanding on virtual memory, since one does not need to make
;	a floating point copy of the entire array.	
;
; REVISION HISTORY:
;	Written, W. Landsman, October 1986
;	Call REBIN for REAL*4 and REAL*8 input arrays, W. Landsman Jan, 1992
;	Removed /NOZERO in output array definition     W. Landsman 1995
;	Fixed occasional integer overflow problem      W. Landsman Sep. 1995
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2

 if N_params() EQ 0 then $
     message,'Syntax -   out =  BOXAVE( array, xsize, [ysize ])',/NoName

 s = size(array)
 if ( s[0] NE 1 ) and ( s[0] NE 2 ) then $
     message,'Input array (first parameter) must be 1 or 2 dimensional'

 if N_elements(xsize) EQ 0 then read,'BOXAVE: Enter box size: ',xsize 
 if N_elements(ysize) EQ 0 then ysize = xsize

 s = size(array)
 ninx = s[1]                                  
 noutx = ninx/xsize	
 type = s[ s[0] + 1]

 if s[0] EQ 1 then begin		; 1 dimension?

     if type LT 4  then begin 

	if xsize LT 2 then return, array
	counter = lindgen(noutx)*xsize
	output = array[counter]
	for i=1,xsize-1 do output = output + array[counter + i]
	nboxsq = float(xsize)

      endif else return, rebin( array, noutx)     ;Use REBIN if not integer

  endif else begin		; 2 dimensions

	niny = s[2]
	nouty = niny/ysize
        if type LT 4 then begin                        ;Byte, Integer, or Long

	   
	   nboxsq = float( xsize*ysize )
	   output = fltarr( noutx, nouty)     ;Create output array 
	   counter = lindgen( noutx*nouty )	
	   counter = xsize*(counter mod noutx) + $
                    (ysize*ninx)*long((counter/noutx))

	   for i = 0,xsize-1 do $
	   for j = 0,ysize-1 do $
	         output = output + array[counter + (i + j*ninx)]

        endif else $
           return, rebin( array, noutx, nouty)       ;Use REBIN if not integer
 endelse

 case type of 
  2:  return, fix( round( output/ nboxsq ))              ;Integer
  3:  return, round( output / nboxsq )                   ;Long
  1:  return, byte( round( output/nboxsq) )              ;Byte
 endcase

 end
