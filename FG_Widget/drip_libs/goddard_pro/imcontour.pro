pro imcontour, im, hdr, TYPE=type, PUTINFO=putinfo, XTITLE=xtitle,  $
      YTITLE=ytitle, SUBTITLE = subtitle, XDELTA = xdelta, YDELTA = ydelta, $
      ANONYMOUS_ = dummy_,_EXTRA = extra
;+
; NAME:
;	IMCONTOUR
; PURPOSE:
;	Make a contour plot labeled with astronomical coordinates.
; EXPLANATION:
;	The type of coordinate display is controlled by the keyword TYPE
;	Set TYPE=0 (default) to measure distances from the center of the image
;	(IMCONTOUR will decide whether the plotting units will be in
;	arc seconds, arc minutes, or degrees depending on image size.)
;	Set /TYPE for standard RA and Dec labeling
;
; CALLING SEQUENCE
;	IMCONTOUR, im, hdr,[ /TYPE, /PUTINFO, XDELTA = , YDELTA =, _EXTRA = ]
;
; INPUTS:
;	IM - 2-dimensional image array
;	HDR - FITS header associated with IM, string array, must include
;		astrometry keywords.   IMCONTOUR will also look for the
;		OBJECT and IMAGE keywords, and print these if found and the 
;		PUTINFO keyword is set.
;
; OPTIONAL PLOTTING KEYWORDS:
;	TYPE - the type of astronomical labeling to be displayed.   Either set
;		TYPE = 0 (default), distance to center of the image is
;		marked in units of Arc seconds, arc minutes, or degrees
;
;		TYPE = 1 astronomical labeling with Right ascension and 
;		declination.
;
;	PUTINFO - If set then IMCONTOUR will add information about the image
;		to the right of the contour plot.  Information includes image
;		name, object, image center, image center, contour levels, and
;		date plot was made
;
;	XDELTA, YDELTA - Integer scalars giving spacing of labels for TYPE=1.  
;		Default is to label every major tick (XDELTA=1) but if 
;		crowding occurs, then the user might wish to label every other
;		tick (XDELTA=2) or every third tick (XDELTA=3)
;
;	Any keyword accepted by CONTOUR may also be passed through IMCONTOUR
;	since IMCONTOUR uses the _EXTRA facility.     IMCONTOUR uses its own
;	defaults for the XTITLE, YTITLE XMINOR, YMINOR, and SUBTITLE keywords
;	but these may be overridden.
;
; NOTES:
;	(1) The contour plot will have the same dimensional ratio as the input
;		image array
;	(2) To contour a subimage, use HEXTRACT before calling IMCONTOUR
;
; EXAMPLE:
;	Overlay the contour of an image, im2, with FITS header, h2, on top
;	of the display of a different image, im1.   Use RA, Dec labeling, and
;	seven equally spaced contour levels.    Follow the method in Section
;	15-7 of the IDL manual to scale the image to fit the plot display.
;
;	IDL> imcontour,im2,h2      ;Do it once just to get the plot size
;	IDL> py = !y.window*!D.y_vsize
;	IDL> sx = px(1)-px(0)+1 & sy = py(1)-py(0)+1
;	IDL> erase
;	IDL> tv,congrid(im2,sx,sy),px(0),py(0)
;	IDL> imcontour,im2,h2,nlevels=7,/Noerase,/TYPE    ;Now do it for real
;
; PROCEDURES USED:
;	CHECK_FITS, EXTAST, GETROT, TICPOS, TICLABEL, TIC_ONE, TICS, XYAD
;	CONS_RA(), CONS_DEC(), ADSTRING()
;
; RESTRICTIONS:
;	V3.6a of IDL contained a serious bug, that would cause roundoff, even
;	with XSTYLE = 1.    IMCONTOUR may display incorrect coordinates under
;	IDL V3.6a.     Users should upgrade to at least IDL V3.6c to ensure 
;	the proper output of IMCONTOUR
; REVISION HISTORY:
;	Written   W. Landsman   STX                    May, 1989
;	Fixed RA,Dec labeling  W. Landsman             November, 1991
;	Fix plottting keywords  W.Landsman             July, 1992
;	Recognize GSSS headers  W. Landsman            July, 1994
;	Removed Channel keyword for V4.0 compatibility June, 1995
;	Add _EXTRA CONTOUR plotting keywords  W. Landsman  August, 1995
;	Add XDELTA, YDELTA keywords  W. Landsman   November, 1995
;	Use SYSTIME() instead of !STIME                August, 1997
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
  On_error,2                                 ;Return to caller

  if N_params() LT 2 then begin             ;Sufficient parameters?
      print,'Syntax - imcontour, im, hdr, [ /TYPE, /PUTINFO, XDELTA=, YDELT= ]'
      print,'         Any CONTOUR keyword is also accepted by IMCONTOUR'  
     return
  endif

  check_fits, im, hdr, dimen, /NOTYPE     ;Make sure header appropriate to image
  if !ERR EQ -1 then return

; Set defaults if keywords not set

 if not keyword_set( TYPE ) then type = 0
 if not keyword_set( XDELTA ) then xdelta = 1
 if not keyword_set( YDELTA ) then ydelta = 1
 
 if not keyword_set(XMINOR) then $
       if !X.MINOR EQ 0 then xminor = 5 else xminor = !X.MINOR

 if not keyword_set(YMINOR) then $
       if !Y.MINOR EQ 0 then yminor = 5 else yminor = !Y.MINOR

 extast, hdr, astr, noparams      ;Extract astrometry from header
 if noparams LT 0 then $                       ;Does astrometry exist?
      message,'FITS header does not contain astrometry'
 if strmid( astr.ctype[0], 5, 3) EQ 'GSS' then begin
	hdr1 = hdr
	gsss_STDAST, hdr1
	extast, hdr1, astr, noparams
 endif

; Adjust plotting window so that contour plot will have same dimensional 
; ratio as the image

  xlength = !D.X_VSIZE &  ylength = !D.Y_VSIZE
  xsize = fix( dimen[0] )  &   ysize = fix( dimen[1] )
  xsize1 = xsize-1 & ysize1 = ysize-1
  xratio = xsize / float(ysize)
  yratio = ysize / float(xsize)

  if ( ylength*xratio LT xlength ) then begin

    xmax = 0.15 + 0.8*ylength*xratio/xlength
    pos = [ 0.15, 0.15, xmax, 0.95 ]

 endif else begin


     xmax = 0.95
     pos = [ 0.15, 0.15, xmax, 0.15+ 0.8*xlength*yratio/ylength ]

 endelse

   if !X.TICKS GT 0 then xtics = abs(!X.TICKS) else xtics = 8
   if !Y.TICKS GT 0 then ytics = abs(!Y.TICKS) else ytics = 8

  pixx = xsize/xtics                ;Number of X pixels between tic marks
  pixy = ysize/ytics                ;Number of Y pixels between tic marks

  getrot,hdr,rot,cdelt               ;Get the rotation and plate scale

  xmid = xsize1/2.   &   ymid  = ysize1/2.
  xyad,hdr,xmid,ymid,ra_cen,dec_cen         ;Get Ra and Dec of image center
  ra_dec = adstring(ra_cen,dec_cen,1)       ;Make a nice string

; Determine tic positions and labels for the different type of contour plots

if type NE 0 then begin                  ;RA and Dec labeling

     xedge = [ 0, xsize1, 0]          ;X pixel values of the four corners
     yedge = [ 0, 0, ysize1]          ;Y pixel values of the four corners

     xy2ad, xedge, yedge, astr, a, d
 
     pixx = xsize/xtics                ;Number of X pixels between tic marks
     pixy = ysize/ytics                ;Number of Y pixels between tic marks

     tics, a[0], a[1], xsize, pixx, raincr,/ RA  ;Find an even increment for RA
     tics, d[0], d[2], ysize, pixy, decincr    ;Find an even increment for Dec

     tic_one, a[0], pixx, raincr, botmin, xtic1, /RA  ;Position of first RA tic
     tic_one, d[0], pixy, decincr,leftmin,ytic1       ;Position of first Dec tic

     nx = fix( (xsize1-xtic1-1)/pixx )             ;Number of X tic marks
     ny = fix( (ysize1-ytic1-1)/pixy )             ;Number of Y tic marks

     ra_grid = (botmin + findgen(nx+1)*raincr/4.)
     dec_grid = (leftmin + findgen(ny+1)*decincr/60.)

     ticlabels, botmin, nx+1, raincr, xlab, /RA, DELTA=xdelta
     ticlabels, leftmin, ny+1, decincr, ylab,DELTA=ydelta

     xpos = cons_ra( ra_grid,0,astr )     ;Line of constant RA
     ypos = cons_dec( dec_grid,0,astr)   ;Line of constant Dec
     xunits = 'RIGHT ASCENSION'
     yunits = 'DECLINATION'

  endif else begin                          ;Label with distance from center

     ticpos, xsize1*cdelt[0], xsize, pixx, incrx, xunits     
     numx = fix(xsize/(2.*pixx))  
     ticpos, ysize1*cdelt[0], ysize, pixy, incry, yunits
      numy = fix(ysize/(2.*pixy))
      nx = 2*numx & ny = 2*numy
      xpos = xmid + (findgen(nx+1)-numx)*pixx
      ypos = ymid + (findgen(ny+1)-numy)*pixy
      xlab = string(indgen(nx+1)*incrx - incrx*numx,'(I3)')
      ylab = string(indgen(ny+1)*incry - incry*numy,'(I3)')
  
   endelse

; Get default values of XTITLE, YTITLE, TITLE and SUBTITLE

  if not keyword_set(PUTINFO) then putinfo = 0

  if N_elements(xtitle) EQ 0 then $
  if !X.TITLE eq '' then xtitle = xunits else xtitle = !X.TITLE

  if N_elements(ytitle) EQ 0 then $
      if !Y.TITLE eq '' then ytitle = yunits else ytitle = !Y.TITLE

  if (not keyword_set( SUBTITLE) ) and (putinfo LT 1) then $
      subtitle = 'CENTER:  R.A. '+ strmid(ra_dec,1,13)+'  DEC ' + $
               strmid(ra_dec,13,13)
  if (not keyword_set( SUBTITLE) ) then subtitle = !P.SUBTITLE

  contour,im, $
         XTICKS = nx, YTICKS = ny, POSITION=pos, XSTYLE=1, YSTYLE=1,$
         XTICKV = xpos, YTICKV = ypos, XTITLE=xtitle, YTITLE=ytitle, $
         XTICKNAME = xlab, YTICKNAME = ylab, SUBTITLE = subtitle, $
	 XMINOR = xminor, YMINOR = yminor, _EXTRA = extra

;  Write info about the contour plot if desired

  if putinfo GE 1 then begin

     xmax = xmax + 0.01

     object = sxpar( hdr, 'OBJECT' )
     if !ERR ne -1 then xyouts, xmax, 0.95, object, /NORM

     name = sxpar( hdr, 'IMAGE' )
     if !ERR ne -1 then xyouts,xmax,0.90,name, /NORM

     xyouts, xmax, 0.85,'CENTER:',/NORM
     xyouts, xmax, 0.80, 'R.A. '+ strmid(ra_dec,1,13),/NORM
     xyouts, xmax, 0.75, 'DEC '+  strmid(ra_dec,13,13),/NORM
     xyouts, xmax, 0.70, 'IMAGE SIZE', /NORM
     xyouts, xmax, 0.65, 'X: ' + strtrim(xsize,2), /NORM
     xyouts, xmax, 0.60, 'Y: ' + strtrim(ysize,2), /NORM
     xyouts, xmax, 0.50, strmid(systime(),4,20),/NORM
     xyouts, xmax, 0.40, 'CONTOUR LEVELS:',/NORM

    sv = !D.NAME
    set_plot,'null'
    contour,im, _EXTRA = extra, PATH_INFO = info
    set_plot,sv

     nlevels = N_elements(info)
     for i = 0,(nlevels < 7)-1 do $
          xyouts,xmax,0.35-0.05*i,string(i,'(i2)') + ':' + $
                              string(info[i].value), /NORM

  endif
  
  return                                          
  end                                         
