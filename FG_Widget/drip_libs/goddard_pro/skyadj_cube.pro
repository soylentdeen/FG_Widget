PRO SKYADJ_CUBE,Datacube,Skyvals,Totsky, XMEDSKY=xmedsky, $
                REGION=region,VERBOSE=verbose,NOEDIT=noedit
;+
; NAME:                    
;       SKYADJ_CUBE
;
; PURPOSE:
;       Sky adjust the planes of a datacube.
;
; EXPLANATION:
;       When removing cosmic rays from a set of images, it is desirable that
;       all images have the same sky level.    This procedure (called by
;       CR_REJECT) removes the sky from each image in a data cube.    
;
; CALLING SEQUENCE:
;       SKYADJ_CUBE,Datacube, Skyvals,Totsky, [/XMEDSKY, /VERBOSE, /NOEDIT,
;                     REGION = ]
;
; MODIFIED ARGUMENT:
;       Datacube:  3-D array with one image of same field in each plane.
;                  Returned with sky in each plane adjusted to zero.
;
; OUTPUT ARGUMENTS:
;       Skyvals:   Array of sky values used on each plane of datacube.
;                  For a scalar sky, this parameter is a vector
;                  containing the sky value for each image plane.  For a
;                  vector sky, this parameter is a 2-D array where each
;                  line corresponds to one image plane.
;
; INPUT KEYWORD PARAMETERS:
;
;       REGION   - [X0,X1,Y0,Y1] to restrict area used for computation
;                  of sky.  Default is 0.1*Xdim, 0.9*Xdim, 0.1*Ydim, 0.9*Ydim
;       VERBOSE  - Flag.  If set, print information on skyvals.
;       NOEDIT   - Flag.  If set, return sky values without changing
;                  datacube.
;       XMEDSKY  - Flag.  If set, return vector sky as a function of X.
;
; PROCEDURE:
;       Uses astronomy library "sky" routine for scalar sky and
;       column-by-column median for vector sky.
; PROCEDURE CALLS:
;       SKY, XMEDSKY           ;in IDL Astronomy Library
; MODIFICATION HISTORY:
;      20 Oct. 1997   - Original Version, Robert Hill,  Raytheon STX
;       9 Apr 1998 - Added calling sequence, Wayne Landsman,  Raytheon STX
;         Jun 1998 - Converted to IDL V5.0, Wayne Landsman,   Raytheon STX
;-
 if N_params() LT 1 then begin
       print,'Syntax - SKYADJ_CUBE,Datacube, Skyvals,Totsky, [/XMEDSKY,' 
       print,'                      /VERBOSE, /NOEDIT, REGION = ]'
       return
 endif

 xmed = keyword_set(xmedsky)
 verbose=keyword_set(verbose)
 sz=size(datacube)
 xdim=sz[1]
 ydim=sz[2]
 zdim=sz[3]
 IF n_elements(region) LT 1 THEN BEGIN
    xmarg = xdim/10
    ymarg = ydim/10
    region = [xmarg,xdim-xmarg,ymarg,ydim-ymarg]
 ENDIF
 IF xmed THEN BEGIN
    skyvals = fltarr(xdim,zdim)
 ENDIF ELSE BEGIN
    skyvals = fltarr(zdim)
 ENDELSE 
 skyplane = fltarr(xdim,ydim)
 FOR i=0,zdim-1 DO BEGIN
    plane = datacube[*,*,i]
    IF xmed THEN BEGIN
        xmedsky, plane, bkg, clip=region
        skyvals[0,i] = bkg
        FOR j=0,ydim-1 DO BEGIN 
            skyplane[0,j] = bkg
        ENDFOR 
    ENDIF ELSE BEGIN 
        sky, plane[region[0]:region[1],region[2]:region[3]], $
          skymode, skysig, /silent
        skyvals[i] = skymode
        skyplane[*] = skymode
    ENDELSE 
    IF NOT keyword_set(noedit) THEN BEGIN
        IF verbose THEN print,'SKYADJ_CUBE:  Adjusting plane ',strn(i)
        datacube[0,0,i] = plane-skyplane
    ENDIF
 ENDFOR
 IF verbose THEN BEGIN
    IF xmed THEN BEGIN 
        print,'SKYADJ_CUBE:  1-D sky as function of X'
        print,'              Average values per image plane are'
        FOR i=0,zdim-1 DO $
          print,'             ',avg(skyvals[*,i])
    ENDIF ELSE BEGIN
        print,'SKYADJ_CUBE:  Scalar sky for each image plane'
        print,'              Values are '
        print,'              ',skyvals
    ENDELSE
 ENDIF 
 IF xmed THEN BEGIN
    totsky = total(skyvals,2)
 ENDIF ELSE begin
    totsky = total(skyvals)
 ENDELSE
 return
 END

