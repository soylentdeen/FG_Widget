function frac_pix_shift, image, x_shift, y_shift, SHIFT_XY=shift_xy, $
						RENORMALIZE=renorm
;+
; NAME:
;	frac_pix_shift
;
; PURPOSE:
;	Shift the image by fraction of a pixel in x and/or y directions
;	using the bilinear interp feature of intrinsic IDL routine poly_2d.
;	Minimum shift is one tenth of pixel, anything less is ignored.
;	Best to keep abs( x & y shifts ) &#60; 0.5, otherwise poly_2d extrapolates.
;
; CALLING:
;	imshift = frac_pix_shift( image, x_shift, y_shift )
;
; INPUTS:
;	image, x_shift, y_shift
;
; KEYWORDS:
;	SHIFT_XY =
;	/RENORMALIZE : shifted image is renormalized to conserve positive flux.
;
; OUTPUTS:
;	The image shifted is returned.
; PROCEDURE:
;
; HISTORY:
;	Written: Frank Varosi NASA/GSFC 1992.
;-
	if N_elements( shift_xy ) EQ 2 then begin
		x_shift = shift_xy(0)
		y_shift = shift_xy(1)
	   endif

	if (abs( x_shift ) LT 0.1) AND (abs( y_shift ) LT 0.1) then return,image

	cx = [ [-x_shift,0], [1,0] ]
	cy = [ [-y_shift,1], [0,0] ]


	if keyword_set( renorm ) then begin

		imshift = poly_2d( image, cx, cy, 1 )
		return, imshift * ( total( image>0 )/total( imshift>0 ) )

	  endif else return, poly_2d( image, cx, cy, 1 )
end
