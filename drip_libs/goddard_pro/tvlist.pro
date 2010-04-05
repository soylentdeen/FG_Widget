pro tvlist, image, dx, dy, TEXTOUT = textout, OFFSET = offset, ZOOM = ZOOM
;+
; NAME
;	TVLIST
; PURPOSE:
;	Cursor controlled listing of image pixel values in a window. 
;
; CALLING SEQUENCE:
;	TVLIST, [image, dx, dy, TEXTOUT =, OFFSET = , ZOOM = ]
;
; OPTIONAL INPUTS:
;	IMAGE - Array containing the image currently displayed on the TV.
;		If omitted, the byte pixel intensities are read from the TV
;		If the array does not start at position (0,0) on the window then
;		the OFFSET keyword should be supplied.
;
;	DX     -Integer scalar giving the number of pixels in the X direction 
;		to be displayed.  If omitted then DX = 18 for byte images, and 
;		DX = 14 for integer images.  TVLIST will display REAL data 
;		with more significant figures if more room is availble to 
;		print.  
;
;	DY    - Same as DX, but in Y direction.  If omitted, then DY = DX 
;
; OPTIONAL INPUT KEYWORDS:
;      OFFSET - 2 element vector giving the location of the image pixel (0,0) 
;		on the window display.   OFFSET can be positive (e.g if the 
;		image is centered in a larger window) or negative (e.g. if the
;		only the central region of an image much larger than the window
;		is being displayed. 
;		Default value is [0,0], or no offset.
;	ZOOM - Scalar specifying the magnification of the window with respect
;		to the image variable.    Use, for example, if image has been
;		REBINed before display.
;	TEXTOUT - Optional keyword that determines output device.
;		The following dev/file is opened for output.
;
;		textout=1	TERMINAL using /more option (default)
;		textout=2	TERMINAL without /more option
;		textout=3	<program>.prt  
;		textout=4	laser.tmp
;		textout=5       user must open file
;		textout=7	Append to an existing <program>.prt file if it
;				exists
;		textout = filename (default extension of .prt)
;
;	If TEXTOUT > 3 or set to a filename, then TVLIST will prompt for a 
;	brief description to be included in the output file
; OUTPUTS:
;	None.
; PROCEDURE:
;	Program prompts user to place cursor on region of interest in 
;	image display.  Corresponding region of image is then displayed at
;	the terminal.   A compression factor between the image array and the
;	displayed image is determined using the ratio of image sizes.  If 
;	necessary, TVLIST will divide all pixel values in a REAL*4 image by a 
;	(displayed) factor of 10^n (n=1,2,3...) to make a pretty format.
;
; SYSTEM VARIABLE:
;	The nonstandard system variable !TEXTOUT is used as an alternative to
;	the keyword TEXTOUT.   The procedure ASTROLIB can be used to define
;	!TEXTOUT (and !TEXTUNIT) if necessary.
;
; RESTRICTIONS:
;	TVLIST may not be able to correctly format all pixel values if the
;	dynamic range near the cursor position is very large.
;
; PROCEDURES CALLED:
;	F_FORMAT(), UNZOOM_XY
; REVISION HISTORY:
;	Written by rhc, SASC Tech, 3/14/86.
;	Added textout keyword option, J. Isensee, July, 1990
;	Check for readable pixels     W. Landsman   May 1992
;	Use integer format statement from F_FORMAT    W. Landsman   Feb 1994
;	Added OFFSET, ZOOM keywords  W. Landsman   Mar 1996
;	More intelligent formatting of longword, call TEXTOPEN with /STDOUT
;		W. Landsman  April, 1996
;	Added check for valid dx value  W. Landsman   Mar 1997
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2

 npar = N_params()

 if not keyword_set(TEXTOUT) then textout = !TEXTOUT ;Use default
 unzoom = (N_elements(offset) NE 0) or (N_elements(zoom) NE 0)

 if npar GE 2 then $
    if N_elements( dx) NE 1 then $
          message, 'ERROR - Second parameter (format width) must be a scalar'

 textopen,'TVLIST', TEXTOUT = textout, /STDOUT        ;Use standard output

 if npar EQ 0 then begin 	;Read pixel values from TV

        if (!D.FLAGS and 128) NE 128 then message, $
             'ERROR -- Unable to read pixels from current device ' + !D.NAME
	printf,!TEXTUNIT,'No image array supplied, pixel values read from TV' 
	type = 1		;Byte format

 endif else begin

	sz = size(image)
	if (sz[0] LT 2) or (sz[sz[0]+2] NE sz[1]*sz[2]) then $
		message,'Image array (first parameter) not 2-dimensional'
    	type = sz[sz[0]+1]	     ;Byte or Integer image?

 endelse 

 if textout GE 3 then begin   ;Direct output to a disk file
	printf,!TEXTUNIT,'TVLIST: '+strmid(systime(),4,20)
        descr = ''
	read,'Enter a brief description to be written to disk: ',descr
        printf,!TEXTUNIT,descr
	printf,!TEXTUNIT,' '
 endif                 

 if (!D.FLAGS AND 256) EQ 256 THEN wshow,!D.WINDOW

 if ( npar GT 0 ) then begin 	;get X and Y dimensions of the image
	xdim = sz[1] - 1 
	ydim = sz[2] - 1 
 endif else begin		;dimensions of TV display
	xdim = !d.x_vsize
	ydim = !d.y_vsize
 endelse

 if N_elements(dx) EQ 0 then  $  ;Use default print size? 
    if type EQ 1 then dx = 18 else dx = 15 else $
    if (dx GT 38) then begin 
	message, 'ERROR - X Pixel Width (second parameter) value of ' + $
		strtrim(dx,2) + ' is too large',/CON
    return
 endif

 tvcrs, 1                                    ;Make sure cursor is on
 print, 'Put the cursor on the area you want to list; press any mousse button'
 if (npar NE 0) and  (unzoom) then begin              ;Get image coordinates.
	cursor, xtv, ytv, /WAIT, /DEVICE
	unzoom_xy, xtv, ytv, xim, yim, OFFSET=offset, ZOOM=zoom 
	xim = fix(xim+0.5)
	yim = fix(yim+0.5)
 endif else cursor, xim, yim, /WAIT, /DEVICE


 if npar LT 3 then dy = dx
; Don't try to print outside the image
  xmax = (xim + dx/2) < xdim
  xmin = (xim - dx/2) > 0 
  ymax = (yim + dy/2) < ydim
  ymin = (yim - dy/2) > 0 

 dx = xmax - xmin + 1 & dy = ymax - ymin + 1

 if xmin GE xmax then $
    message,'ERROR - The cursor is off the image in the x-direction'
 if ymin GE ymax then $
    message,'ERROR - The cursor is off the image in the y-direction'

 fmtsz = (80-4)/dx
 sfmt = strtrim(fmtsz,2)
 cdx = string(dx,'(i2)')
 flt_to_int = 0                   ;Convert floating point to integer?

; For Integer and Byte datatypes we already know the best output format
; For other datatypes the function F_FORMAT is used to get the best format
; If all values of a LONG image can be expressed with 5 characters 
; (-9999 < IM < 99999) then treat as an integer image.

REDO:
 case 1 of                                    ;Get proper print format
	type EQ 1 or (npar EQ 0):  fmt = '(i4,' + cdx + 'i' + sfmt + ')'
	type EQ 2:  fmt = '(i4,1x,' + cdx + 'i' + sfmt + ')'
	(type EQ 4) or (type EQ 3) or (type EQ 5):  begin
		temp = image[xmin:xmax,ymin:ymax]
		minval = min(temp, max=maxval) 
		if type EQ 3 then if (maxval LT 99999) and (minval GT -9999) $
		then begin
			type = 2
			goto, REDO
		endif
		realfmt =  f_format(minval,maxval,factor,fmtsz)
	        if strmid(realfmt,0,1) EQ 'I' then flt_to_int = 1
                fmt = '(i4,1x,' + cdx + realfmt + ')'
		if factor NE 1 then $                                   
       printf,!TEXTUNIT,form='(/,A,E7.1,/)',' TVLIST: Scale Factor ',factor
      end
 endcase 
; Compute and print x-indices above array

 if npar EQ 0 then begin 
    xmin = xmin - (xmin mod 2)
    dx = dx - (dx mod 2)
 endif

 index = indgen(dx)+ xmin

 if type NE 1 then $
     printf,!TEXTUNIT,form='(A,'+ cdx + 'i' + sfmt + ')', ' col ', index  $
 else printf,!TEXTUNIT,form='(A,'+ cdx + 'i' + sfmt + ')', ' col', index 
 printf,!TEXTUNIT,' row'

 if npar EQ 0 then begin 
    row = fix( tvrd( xmin,ymin,dx,dy) )
    for i = dy-1,0,-1 do printf, !TEXTUNIT, FORM=fmt, i+ymin, row[*,i]

 endif else begin

 for i = ymax,ymin,-1 do begin	;list pixel values

        row = image[i*sz[1]+xmin:i*sz[1]+xmax]
	if type EQ 1 then row = fix(row)             ;Convert byte array
	if (type EQ 4) or (type EQ 3) or (type EQ 5) then row = row/factor
	if flt_to_int then row = round( row )
        printf,!TEXTUNIT, FORM=fmt, i, row
 endfor

 endelse

 textclose,TEXTOUT = textout

 return
 end
