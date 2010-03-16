; NAME:
;     MAKEPHOTO
;
; PURPOSE:
;     Takes pupil viewer image reduced with drip, cuts and rotates it
;
; MODIFICATION HISTORY:
;   Written by:   Marc Berthoud, CU, November 2006

;******************************************************************************
;     MAKEPHOTO - extract photo with center at x/ycenter
;                 reads file filename replaces old with new file
;******************************************************************************
pro makephoto,xcenter,ycenter,filename
; read file
photo=readfits(filename,header)
; crop, rotate
photo=rotate(photo[xcenter-69:xcenter+70,ycenter-69:ycenter+70],1)
tvscl,photo
; make new filename
writefits,filename,photo,header
end
; 133,149
