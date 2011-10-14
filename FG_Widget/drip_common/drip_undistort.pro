; NAME:
;	DRIP_UNDISTORT - Version .7.0
;
; PURPOSE:
;	Corrects distortion due to camera optics.
;
; CALLING SEQUENCE:
;       UNDISTORTED=DRIP_UNDISTORT(DATA, BASEHEAD ,PINPOS=pinpos, /ROTATE)
;
; INPUTS:
;	DATA - the data to be undistorted.
;       BASEHEAD - output header of the pipelining. should contain the information
;                    for distortion correction. The information is writen at drip:getcal
;       PINPOS - Array defining the position of the modeled and measured pinhole mask
;                Format = [Number of pinholes,Xpos model, Ypos model, Xpos measure, Ypos measure]
;                If pinpos is not specified then default values are used
;       ROTATE - Specifies that we rotate the model by NODANGLE keyword.
;       
;
; SIDE EFFECTS: (not sure)
;	Leaves zeroed edges.
;       Data in the corners gets lost when rotating
;
; RESTRICTIONS:
;
; PROCEDURE:
;	setup arrays to define warping parameters.  Perform
;	polynomial warping. Perform rebining if requested.
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
;       Modified:       Miguel Charcos Llorens, USRA, March 2011
;                       The pinhole model is within the input parameters
;                       We assume that it is already rotated to the righ orientation
;                       Add order as an input parameter
;                       Add rebining based on distcorr.pro by W D Vacca (March-April 2010)
;                       Removed header from input parameters
;

;******************************************************************************
;	DRIP_UNDISTORT - Undistorts frames
;******************************************************************************

FUNCTION drip_undistort, data, basehead, PINPOS=pinpos, ROTATE=rotate
  
  ;--------------------------------
  ; error check
  s=size(data)
  if s[0] ne 2 then begin
      drip_message, 'drip_undistort - Must provide valid data array',/fatal
      return, data
  endif
  
  ; remap image into larger one (bottom left corner)
  ;datalg=fltarr(3*s[1],3*s[2])
  ;datalg[0:s[1]-1,0:s[2]-1]=data
  datalg=data
  
  dodefaultvalues = 1
  
  if keyword_set(pinpos) eq 1 then begin
    if n_elements(pinpos) eq 4*fix(pinpos(0))+1 then dodefaultvalues=0
  endif
  
  ;-------------------------------------------------------
  ; Use default values of initial and final x,y 
  ; if a they are not specified in the input parameters
  ; The   
  if dodefaultvalues eq 1 then begin
    print,"We use default pin positions"
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
  endif else begin
    xo = pinpos(1:pinpos(0))
    yo = pinpos(pinpos(0)+1:2*pinpos(0))
    xi = pinpos(2*pinpos(0)+1:3*pinpos(0))
    yi = pinpos(3*pinpos(0)+1:4*pinpos(0))
  endelse
  
  ;-------------------------------------------------------
  ; Adjust final coordinates for roatated and scaled image
  ; get rotation angle if the input header is specified
  if keyword_set(rotate) then begin
    angle=float(drip_getpar(basehead,'NODANGLE'))*!pi/180.0
    xm=float(s[1])/2.0-0.5
    ym=float(s[2])/2.0-0.5
    sina=sin(angle)
    cosa=cos(angle)
    ; rotate xo, yo arround center(xm,ym) -> x1,y1
    x1=xm-xm*cosa+ym*sina+xo*cosa-yo*sina
    y1=ym-xm*sina-ym*cosa+xo*sina+yo*cosa
    
    xo=x1*2.0+s[1]/2.0
    yo=y1*2.0+s[2]/2.0
  endif 
  
  if dodefaultvalues eq 1 then begin
    ; we could try to change pinpos in drip but I think it is too complex for what we gain
    ; it is feasible if we think it is necessary
    drip_message, 'Default values has been used for pinholes'
  endif
  
  
  ;-------------------------------------------------------
  ; Perform transformation
  pin_model_read = drip_getpar(basehead,'PIN_MOD')
  if pin_model_read eq 'x' then begin
    order=4
    ; there should be here some kind of error message and a variable indicating 
    ; no rebinning if we decide to keep processing.
  endif else begin
    pin_model = (float(strsplit(pin_model_read,'[],',/extract)))
    order = fix(pin_model[3])
  endelse
  
  ; perform polynomial warping to determine transformation coefficients
  drip_message, 'Distortion solution order: '+strtrim(order,1)
  polywarp, xi, yi, xo, yo, order, p, q, /DOUBLE 
  corrimg=poly_2d(datalg, p, q, 2, cubic=-.5, missing=0)

  ;--------------------------------------------------------
  ; Rebin image     
  ; Read dx and dy in pin_model obtained from input header
  dx = pin_model[0]
  dy = pin_model[1]
  
  nx = s[1]
  ny = s[2]
  
  
  ; Now rebin to square pixels
  ; If the pixels were square then, 11*dx = 11*dy or nx * dx = ny * dy
  ; The smaller the pixels, the larger the number of them across the
  ; array for the same angular distance.
  ; We can make the pixels square by re-binning such that the above equation 
  ; holds, but must assume one dimension is the reference with 256 pixels.
  ; We can adopt the principle that the re-binned array should be as close
  ; to 256x256 as possible. In that case nx' * ny' = 256*256, and nx' = ny'*(dy/dx)
     factor = dy/dx
     newny  = fix(round(sqrt(nx*ny/factor)))
     newnx  = fix(round(float(newny)*factor))

  ; Another way to do this, using the measured plate scale from astronomical
  ; observations:
  ; Measured pixel scales from Jim De Buizer

  ;   xpixsc = 0.787
  ;   ypixsc = 0.745

  ; Desired pixel scale

  ;   pixscal = 0.77

  ;   newnx = fix(round(nx*xpixsc/pixscal))
  ;   newny = fix(round(ny*ypixsc/pixscal))

     drip_message, 'New image size: '+strtrim(newnx,1)+' x '+strtrim(newny,1)


     rebinned = frebin(corrimg,newnx,newny,/TOTAL)
     
     rebinned_sized = replicate(0.,nx,ny)
     if nx lt newnx then begin
       framex = fix((newnx - nx)/2)
       if ny lt newny then begin
         framey = fix((newny - ny)/2)
         rebinned_sized[*,*] = rebinned[framex:framex+nx-1,framey:framey+ny-1]
       endif else begin
         framey = fix((ny - newny)/2)
         
         ;print,'FRAMEXY',framex,framey,nx,ny
	 
	       rebinned_sized[*,framey:ny-1-framey-1] = rebinned[framex:framex+nx-1,*]
       endelse       
     endif else begin
       framex = fix((nx - newnx)/2)
       if ny lt newny then begin
         framey = fix((newny - ny)/2)
         rebinned_sized[framex:nx-1-framex-1,*] = rebinned[*,framey:framey+ny-1]
       endif else begin
         framey = fix((ny - newny)/2)
         rebinned_sized[framex:nx-1-framex-1,framey:ny-1-framey] = rebinned[*,*]
       endelse            
     endelse
     
  ; Update header
  hrebin, corrimg, basehead, OUT=[newnx,newny]
  
  sxaddpar, basehead, 'NAXIS1', fix(nx)
  sxaddpar, basehead, 'NAXIS2', fix(ny)
  
  ;writefits,"pinhole_corrected.fits",rebinned_sized,basehead

  resize=2 ;2
  border=128 ;128
  ;undistorted=fltarr(resize*nx+border,resize*ny+border)
  undistorted=fltarr(nx+resize*border,ny+resize*border)
  undistorted[border:border+nx-1,border:border+ny-1]=rebinned_sized
  
  return, undistorted
  

END
