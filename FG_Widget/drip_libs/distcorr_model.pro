; NAME:
;     DISTCORR_MODEL - Version 1.0
;
; PURPOSE:
;     Generate model array of pin holes based on input file containing the
;     observed pinhole position
;
; CALLING SEQUENCE:
;     POSARRAY = DISTCORR_MODEL(PINHOLE_FILE, VIEWPIN=filename, NXIMG=xsize_image, NYIMG=ysize_image,
;                                NXPTS=xsize_array, NYPTS=ysize_array,
;                                SPX=xpos_missed_array, SPY=ypos_missed_array,
;                                BASEHEAD=basehead)
;
; INPUTS:
;     PINHOLE_FILE - text file giving locations of pin holes
;     NXIMG, NYIMG - Size of the image (detector). Default values are 256x256
;     NXPTS, NYPTS - Size of the array of pinholes. Default values are 12x12
;     SPX, SPY - Coordinates of missing pins in the array. 
;                Default values are -1 which represents non missing pin.
;                First index of the pin hole array is 1.
;     VIEWPIN - set to see the synthetic pin hole file used in the code
;               If no value is entered (e.g. /VIEWPIN) or the value is not a string
;               then the default file name is pinhole_model.fits
;     BASEHEAD - Header to be updated with pin_model=[dx,dy,angle,order]
;                If the header already contain a pin_model only dx,dy and angle are updated
;                Otherwise, everything is updated with default order=4
;
; OUTPUTS:
;     PINPOS - 4xN+1 array containing the pinhole model and pinhole observed positions
;              PINPOS = [N,XMOD,YMOD,XPOS,YPOS]
;              N = n_elements(XPOS) = n_elements(YPOS) = number of pinholes
;              (XPOS[i],YPOS[i]) = position of the pinhole #i in the detector
;              N = n_elements(XMOD) = n_elements(YMOD) = number of pinholes in the model
;              (XMOD[i],YMOD[i]) = position of the pinhole #i in the detector for the model
;              Positions start at 0
;
; PROCEDURE:
;     Read the positions of the pinholes and create a model array
;     of pinholes based on the read positions. The function averages
;     the distance between positions and create a model where
;     the pinholes are regularly spaced. The model is also shifted and rotated
;     in order to match the observed pinhole mask
;
; MODIFICATION HISTORY:
;     Written by:  W D Vacca, USRA, 2010-3  (based on distcorr.pro)
;     modified by:  M. Charcos Llorens, USRA, 2011-3
;

FUNCTION distcorr_model, pinhole_file, $
         NXIMG=nximg, NYIMG=nyimg, NXPTS=nxpts, NYPTS=nypts, SPX=spx, SPY=spy, $
	 VIEWPIN=viewpin, BASEHEAD=basehead
    
    
  ;-------------------------------------------
  ; Initial checks and default values
  ; Check if input file exist
  if (FILE_TEST(pinhole_file) ne 1) then begin
    ;print,"ERROR: File "+pinhole_file+" does not exist"
    msgpos = strpos(fname,path_sep())
    if msgpos lt 0 then begin
      drip_message,'ERROR: distcorr_model - File '+pinhole_file+' does not exist'
    endif else begin
      drip_message,'ERROR: distcorr_model - File '+strmid(pinhole_file,msgpos+1,strlen(pinhole_file)-1)+' does not exist'
      drip_message,'       at strmid(pinhole_file,0,msgpos)'
    endelse
    return,-1
  endif
  
  
  ; If these parameters are not entered within the input parameters, we define default values
  if keyword_set(nxpts) eq 0 then begin
    nxpts = 12               ; number of pinholes in x direction
    ;print,"WARNING: Default nxpts is "+strtrim(nxpts,1)
    drip_message,'WARNING: Default nxpts is '+strtrim(nxpts,1)
  endif  
  if keyword_set(nypts) eq 0 then begin
    nypts = 12               ; number of pinholes in y direction
    ;print,"WARNING: Default nxpts is "+strtrim(nypts,1)
    drip_message,'WARNING: Default nxpts is '+strtrim(nypts,1)
  endif  
  if keyword_set(nximg) eq 0 then begin
    nximg = 256                      ; number of pixels of the image in x direction
    ;print,"WARNING: Default nximg is "+strtrim(nximg,1)
    drip_message,'WARNING: Default nximg is '+strtrim(nximg,1)
  endif  
  if keyword_set(nyimg) eq 0 then begin
    nyimg = 256                      ; number of pixels of the image in x direction
    ;print,"WARNING: Default nyimg is "+strtrim(nyimg,1)
    drip_message,'WARNING: Default nyimg is '+strtrim(nyimg,1)
  endif  
  if keyword_set(spx) eq 0 then begin
    spx = -1                      ; number of pixels of the image in x direction
    ;print,"WARNING: Default spx is "+strtrim(spx,1)
    drip_message,'WARNING: Default spx is '+strtrim(spx,1)
  endif  
  if keyword_set(spy) eq 0 then begin
    spy = -1                      ; number of pixels of the image in x direction
    ;print,"WARNING: Default spy is "+strtrim(spy,1)
    drip_message,'WARNING: Default spy is '+strtrim(spy,1)
  endif
  
  if n_elements(spx) ne n_elements(spy) then begin
    ;print,"ERROR: SPX (size="+strtrim(n_elements(spx),1)+") or SPY (size="+strtrim(n_elements(spy),1)+") arrays have wrong size"
    drip_message,'ERROR: SPX (size="+strtrim(n_elements(spx),1)+") or SPY (size="+strtrim(n_elements(spy),1)+") arrays have wrong size'
    return,-1
  endif
  
  
  ;-------------------------------------------
  ; Read xpos and ypos, and check that they are correct compared with the image size
  drip_message,'Opening pinhole file '+pinhole_file
  readcol, pinhole_file, id, w, ft, bias, fr, dich, epadu, siglev, pert, bkgd, ampl,xpos, ypos, SKIPLINE=1 
  
  ; Index positions from 0
  xpos  = xpos-1
  ypos  = ypos-1
  ;if spx(0) ne -1 then spx = spx-1
  ;if spy(0) ne -1 then spy = spy-1
  
  ; Check that the positions make sense (greater than 0 and lower than the image size)
  k = where(xpos lt 0)
  if k(0) ne -1 then begin
    ;print,"Error: X positions in "+pinhole_file+" are lower than 0"
    drip_message,'Error: X positions in "+pinhole_file+" are lower than 0'
    return,-1    
  endif
  k = where(ypos lt 0)
  if k(0) ne -1 then begin
    ;print,"Error: Y positions in "+pinhole_file+" are lower than 0"
    drip_message,'Error: Y positions in "+pinhole_file+" are lower than 0'
    return,-1    
  endif
  k = where(xpos ge nximg)
  if k(0) ne -1 then begin
    ;print,"Error: X positions in "+pinhole_file+" are greater than "+strtrim(nximg,1)
    drip_message,'Error: X positions in "+pinhole_file+" are greater than '+strtrim(nximg,1)
    return,-1    
  endif
  k = where(ypos ge nyimg)
  if k(0) ne -1 then begin
    ;print,"Error: Y positions in "+pinhole_file+" are greater than "+strtrim(nyimg,1)
    drip_message,'Error: Y positions in "+pinhole_file+" are greater than '+strtrim(nyimg,1)
    return,-1    
  endif
  
  ;-------------------------------------------
  ; Determine parameters of pinhole locations
  xcen  = nximg/2.
  ycen  = nyimg/2.
  npos  = n_elements(xpos)
  dxpos = xpos[npos-nxpts:npos-1] - xpos[0:nxpts-1]
  dypos = ypos[npos-nypts:npos-1] - ypos[0:nypts-1]
  theta = atan(dypos,dxpos)
  ang   = -1.0*mean(theta)

  ;-------------------------------------------
  ; Avg x separation of pin holes
  avgdx = mean(dxpos)/float(nxpts - 1)

  ; Avg y separation of pinholes - account for gaps
  ; ady contains the averaged y separation at x position
  ady   = fltarr(nypts)
  indx  = 0
  for i=0,nxpts-1 do begin    
    npts = nypts
    if spx(0) ne -1 then begin
      kspx = where(spx eq i)    
      if kspx(0) ne -1 then begin
	npts = npts - n_elements(kspx)
      endif 
    endif
    
    ; This assumes that the first and last pin of the column is not missed in the array  
    ymin = min(ypos[indx:indx+npts-1],MAX=ymax)
    ady[i] = (ymax-ymin)/float(nypts - 1)
        
    indx = indx + npts 
  endfor

  ; contains the averaged separation of y positions
  avgdy  = mean(ady)

  ;print, avgdx, avgdy, mean(theta)*!RADEG
  ;print,"Info: avgdx="+strtrim(avgdx,1)+", avgdy="+strtrim(avgdy,1)+", angle="+strtrim(mean(theta)*!RADEG,1)
  drip_message,'Info: avgdx='+strtrim(avgdx,1)+', avgdy='+strtrim(avgdy,1)+', angle='+strtrim(mean(theta)*!RADEG,1)


  ;-------------------------------------------
  ; Use previous values to generate model array of pinholes
  dx     = avgdx            ; approximate spacing of holes (in pixels) in x
  dy     = avgdy            ; approximate spacing of holes (in pixels) in y

  xpmod  = fltarr(nxpts*nypts) ; array to hold coordinates of pin holes
  ypmod  = fltarr(nxpts*nypts)

  ymin   = min(ypos,imin)
  xoff   = xpos[imin]
  yoff   = ypos[imin]
  for i=0,nypts-1 do begin
      for j=0,nxpts-1 do begin
             jx = j*dx + xoff
             iy = i*dy + yoff
             xpmod[i*nxpts + j] = jx
             ypmod[i*nxpts + j] = iy
      endfor    
  endfor

  ; Remove locations with no holes (gaps)

  idx = spy*nxpts + spx
  remove, idx, xpmod
  remove, idx, ypmod
  
  
  ; Add central hole

  ;xpmod = [xpmod,xcen]
  ;ypmod = [ypmod,ycen]
  npts  = n_elements(xpmod)

  ; Sort the pin hole coordinates to match Terry's input file

  xpsort = fltarr(npts)
  ypsort = fltarr(npts)

  for i=0,npts-1 do begin
      r = sqrt((xpos[i] - xpmod)^2 + (ypos[i] - ypmod)^2)
      rmin = min(r,irmin)
      xpsort[i] = xpmod[irmin]
      ypsort[i] = ypmod[irmin]
  endfor
  
  xpmod = xpsort
  ypmod = ypsort


  ; Rotate about the center of the array and calculate new locations of pin holes

  xp  = ((xpmod-xcen)*cos(ang) + (ypmod-ycen)*sin(ang) + xcen)
  yp  = (-1.*(xpmod-xcen)*sin(ang) + (ypmod-ycen)*cos(ang) + ycen)

  ; Offset pin hole array to match observed pin hole locations

  ypmin = min(yp,ipmin)
  xpmin = xp[ipmin]

  xp = xp - xpmin + xoff
  yp = yp - ypmin + yoff

  if keyword_set(VIEWPIN) then begin
     scale  = 10.0
     pinmod = fltarr(scale*nximg,scale*nyimg)
     pinmod[scale*xp,scale*yp] = 3000.0
     pinimg = frebin(pinmod,nximg,nyimg,/TOTAL)
     psf = psf_gaussian(NPIXEL=40,FWHM=1.5,/NORMALIZE)
     pincon = convolve(pinimg,psf)
     ;atv, pincon
     tv, pincon
     if size(viewpin,/type) ne 7 then begin
       writefits, 'pinhole_model.fits', pincon
     endif else begin
       writefits, viewpin, pincon
     endelse
  endif
  
  ;-----------------------
  ; Update header
  if keyword_set(BASEHEAD) then begin
    orderread=drip_getpar(basehead,'ORDER')  
    if orderread eq 'x' then pin_model=[dx,dy,ang*180./!pi,4] $
    else pin_model=[dx,dy,ang*180./!pi,float(orderread)]
    
    ;pin_model=drip_getpar(basehead,'PIN_MOD')  
    ;if pin_model eq 'x' then pin_model=[dx,dy,ang*180./!pi,4] $
    ;else pin_model=[dx,dy,ang*180./!pi,pin_model(3)]
    
    sxaddpar,basehead,'PIN_MOD',"["+strjoin(strtrim(pin_model,1),",")+"]"
  endif
  
  return, [n_elements(xp),xp,yp,xpos,ypos]
  
END
