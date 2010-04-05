; NAME:
;	DRIP_UNDISTORT - Version .7.0
;
; PURPOSE:
;	Corrects distortion due to camera optics.
;
; CALLING SEQUENCE:
;       UNDISTORTED=DRIP_UNDISTORT(DATA, HEADER)
;
; INPUTS:
;	DATA - the data to be undistorted.
;       HEADER - The fits header of the new input data file
;
; SIDE EFFECTS:
;	Leaves zeroed edges.
;       Data in the corners gets lost when rotating
;
; RESTRICTIONS:
;	Warping parameters are not adjustable.
;
; PROCEDURE:
;	setup arrays to define warping parameters.  Perform
;	polynomial warping.
;
; MODIFICATION HISTORY:
;   Written by:  Alfred Lee, Cornell University, 2001
;	Modified:	Alfred Lee, CU, June 7, 2002
;			changed into an object.
;	Modified:	Alfred Lee, CU, June 24, 2002
;			Created RUN method to run the code as needed
;			after a single initialization.
;	Modified:	Alfred Lee, CU, July 18, 2002
;			enhanced error checking.
;	Modified:	Alfred Lee, CU, August 5, 2002
;			updated to new architecture.  data now stored
;			in a Data Manager object.
;       Modified:       Marc Berthoud, CU, July 2004
;                       Rewrote from object to one-line command
;                       Most code erased
;       Modified:       Marc Berthoud, CU, April 2005
;                       Expanded necessary input with header
;                       Include Sky rotation and image expansion
;

;******************************************************************************
;	DRIP_UNDISTORT - Undistorts frames
;******************************************************************************

function drip_undistort, data, header, basehead
; error check
s=size(data)
if s[0] ne 2 then begin
    drip_message, 'drip_undistort - Must provide valid data array',/fatal
    return, data
endif
; remap image into larger one (bottom left corner)
datalg=fltarr(3*s[1],3*s[2])
datalg[0:s[1]-1,0:s[2]-1]=data

;** setup arrays of points to be warped and fitted
; xi,yi - warped coor's, xo,yo - true coor's
xi=[6,54,102,150,198,247,5,54,102,150,198,247,5, $
  54,102,150,198,246,5,54,102,150,198,247,6,54, $
  102,150,199,247,7,55,103,151,199,248]
yi=[242,243,243,243,242,241,197,199,199,199,198, $
  196,151,152,152,152,151,151,105,106,106,106,106, $
  104,58,59,60,59,58,57,10,10,11,11,10,9]
xo=[13,58,104,149,194,239,13,58,104,149,194,239,13, $
  58,104,149,194,239,13,58,104,149,194,239,13,58, $
  104,149,194,239,13,58,104,149,194,239]
yo=[242,242,242,242,242,242,196,196,196,196,196,196, $
  151,151,151,151,151,151,106,106,106,106,106,106, $
  60,60,60,60,60,60,15,15,15,15,15,15]
;** adjust final coordinates for roatated and scaled image
; get rotation angle
baseangle=float(drip_getpar(basehead,'NODANGLE'))*!pi/180.0
angle=float(drip_getpar(header,'NODANGLE'))*!pi/180.0
; create rotation matrix to rotate by angle around [s[1]/2-0.5,s[2]/2-0.5]
; use formula
;   x1 = xm - xm cosa - ym sina + x0 cosa + y0 sina
;   y1 = ym + xm sina - ym cosa - x0 sina + y0 cosa
; xm,ym is center of array i.e. 127.5,127.5
xm=float(s[1])/2.0-0.5
ym=float(s[2])/2.0-0.5
sina=sin(angle)
cosa=cos(angle)
; rotate xo, yo arround center(xm,ym) -> x1,y1
x1=xm-xm*cosa+ym*sina+xo*cosa-yo*sina
y1=ym-xm*sina-ym*cosa+xo*sina+yo*cosa

;CHANGED for the DATA SIMULATOR
;x1=xm-xm*cosa+ym*sina+xi*cosa-yi*sina
;y1=ym-xm*sina-ym*cosa+xi*sina+yi*cosa

;p=[[xm-xm*cosa-ym*sina,sina],[cosa,0]] ; in case I need it with poly_2d
;q=[[ym+xm*sina-ym*cosa,cosa],[-sina,0]]
;rotated=poly_2d(undistorted,p,q,2, cubic=-.5, missing=0)
; adjust final coordinates for larger image (i.e. blow up and move to middle)
; -> new value of xo,yo
xo=x1*2.0+s[1]/2.0
yo=y1*2.0+s[2]/2.0
; perform polynomial warping (3. degree)
polywarp, xi, yi, xo, yo, 3, p, q

;print,'p: min=',min(p),' max=',max(p),' mean=',mean(p)
;print,p
;print,'q: min=',min(q),' max=',max(q),' mean=',mean(q)
;print,q

undistorted=poly_2d(datalg, p, q, 2, cubic=-.5, missing=0)


return, undistorted
end

