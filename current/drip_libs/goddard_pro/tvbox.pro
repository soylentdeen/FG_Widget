pro tvbox,width,x,y,color,DATA = data,COLOR=thecolor,_EXTRA = _EXTRA
;+
; NAME:
;      TVBOX
; PURPOSE:
;      Draw a box(es) or rectangle(s) of specified width
; EXPLANATION: 
;      Positions can be specified either by the cursor position or by 
;      supplying a vector of X,Y positions.   
;
; CALLING SEQUENCE:
;      TVBOX, width, [ x, y, color, /DATA, COLOR =, _EXTRA =  ]
;
; INPUTS:
;      WIDTH -  either a scalar giving the width of a box, or a 2 element
;               vector giving the length and width of a rectangle.
;
; OPTIONAL INPUTS:           
;      X  -  x position for box center, scalar or vector, device coordinates
;      Y  -  y position for box center, scalar or vector.   If vector, then Y
;            must have the same number of elements as X
;            If X and Y are not specified, and device has a cursor, then 
;            TVBOX will draw a box at current cursor position
;      COLOR - intensity value(s) (0 - !D.N_COLORS) used to draw the circle(s)
;            If COLORS is a scalar then all circle are drawn with the same
;            color value.   Otherwise, the Nth circle is drawn with the
;            Nth value of color.    Default = !P.COLOR.    
; OUTPUTS:
;      None
;
; OPTIONAL KEYWORD INPUT:
;      COLOR - Scalar or vector, overrides the COLOR input parameter
;      DATA - if this keyword is set and non-zero, then the box width and
;             X,Y position center are interpreted as being in DATA 
;             coordinates.   Note that data coordinates must be previously
;             defined (e.g. with a PLOT or CONTOUR call).
;
;      Any keyword recognized by PLOTS (or POLYFILL if /FILL is set)
;      is also recognized by TVBOX.   In particular, the color,
;      linestyle, and thickness of the boxes is controlled by the 
;      COLOR, LINESTYLE, and THICK keywords.     
; SIDE EFFECTS:
;       A square or rectangle will be drawn on the device
;       For best results WIDTH should be odd.  (If WIDTH is even, the actual
;       size of the box will be WIDTH + 1, so that box remains centered.)
;
; EXAMPLE:
;       Draw a double thick box of width 13, centered at 221,256 in the
;       currently active window
;
;       IDL> tvbox, 13, 221, 256, thick=2
;
; RESTRICTIONS:
;       (1) TVBOX does not check whether box is off the edge of the screen
;       (2) Allows use of only device (default) or data (if /DATA is set) 
;           coordinates.   Normalized coordinates are not allowed
;
; REVISON HISTORY:
;       Written, W. Landsman   STX Co.           10-6-87
;       Modified to take vector arguments. Greg Hennessy Mar 1991
;       Fixed centering of odd width    W. Landsman    Sep. 1991
;       Let the user specify COLOR=0, accept vector color, W. Landsman Nov. 1995
;       Fixed typo in _EXTRA keyword  W. Landsman   August 1997
;       Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2

 npar = N_params()                         ;Get number of parameters

 if ( npar LT 1 ) then begin
     print,'Syntax - tvbox, width,[ x, y, color, THICK = ,/DATA, COLOR =  ]
     return
 endif

 zparcheck, 'TVBOX', width, 1, [1,2,3,4,5], [0,1], 'Box Width'

 if ( N_elements(width) EQ 2 ) then w = width/2. else w = [width,width]/2.

 if ( npar LT 3 ) then if  (!D.NAME NE 'PS') then begin 
    cursor,x,y,/DEVICE,/NOWAIT    ;Get unroamed,unzoomed position
    if (x LT 0) or (y LT 0) then begin
       message,'Position cursor in window ' + strtrim(!D.WINDOW,2) + $
              ' -- then hit mouse button',/INF
       cursor,x,y,/DEVICE,/WAIT
       message, 'Box is centered at (' + strtrim(x,2) + ',' + $
		 strtrim(y,2) + ')',/INF
    endif
 endif else message, $
     'ERROR - X,Y position must be specified for Postscript device'

  if N_elements(TheColor) EQ 0 then begin
      IF N_Elements( Color ) eq 0 THEN Color = !P.COLOR
  endif else color = TheColor

 nbox = N_elements(x)                      ;Number of boxes to draw
 if ( nbox NE N_elements(Y) ) then $
       message,'ERROR - X and Y positions must have same number of elements'

 xs = fix(x+0.5)  &  ys = fix(y+0.5)

 Ncol = N_elements(color)
 for i = 0l, nbox-1 do begin

  j = i < (Ncol-1)
  xt = xs[i] + fix( [1,1,-1,-1,1]*w[0] )      ;X edges of rectangle
  yt = ys[i] + fix( [-1,1,1,-1,-1]*w[1] )     ;Y edges of rectangle
  if keyword_set( DATA ) then $ 
  plots, xt, yt, /DATA,  COLOR=color[j], _EXTRA = _EXTRA  else $   ;Plot the box 
  plots, xt, yt, /DEVICE, COLOR=color[j], _EXTRA = _EXTRA

 endfor

 return
 end
