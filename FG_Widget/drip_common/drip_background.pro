; NAME:
; DRIP_BACKGROUND - Version .1.0
;
; PURPOSE:
; Calculate the background of the image in a specific section and update header
;
; CALLING SEQUENCE:
;       SIGLEV = DRIP_BACKGROUND(DATA, SECTION, HEADER=HEADER)
;
; INPUTS:
;       SIGLEV - Array with the signal levels of the data
;       DATA - the data to be undistorted.
;       SECTION - [X0,Y0,XDIM,YDIM]      
;                   X0,Y0: Center of the section
;                   XDIM,YDIM: Dimension of the section
;       HEADER - header to be updated
;       
;
; SIDE EFFECTS:
; 
;
; RESTRICTIONS:
;       
;
; PROCEDURE:
; Read the the section to use in the configuratio file. Then, median of 
; pixel values of image in this section
;
; MODIFICATION HISTORY:
;   Written by:  Miguel Charcos Llorens, USRA, May 2011
; 
;

;******************************************************************************
; DRIP_BACKGROUND - Calculate the background of the image in a specific section
;******************************************************************************

FUNCTION drip_background, data, section, header=header
  
  
  sd = size(data)
  if (sd(0) ne 2) and (sd(0) ne 3) then return,0
  
  x0      = section(0)
  y0      = section(1)
  xboxsz      = section(2)
  yboxsz      = section(3)
  
  xminbox = x0 - xboxsz/2.
  xmaxbox = x0 + xboxsz/2.
  yminbox = y0 - yboxsz/2.
  ymaxbox = y0 + yboxsz/2.
  
  
  if (sd(0) eq 2) then begin
    siglev = median(data[xminbox:xmaxbox,yminbox:ymaxbox])
  endif else begin
    nplanes=sd[3]
    siglev = fltarr(nplanes)
    for i=0,nplanes-1 do begin
      siglev(i) = median(data[xminbox:xmaxbox,yminbox:ymaxbox,i])
    endfor
  endelse
  
  if keyword_set(header) then begin
    siglev_write = strtrim(siglev,1)
    sxaddpar,header,'NLINSLEV','['+strjoin(siglev_write,',')+']'
  endif 
  
  return,siglev
  
END
