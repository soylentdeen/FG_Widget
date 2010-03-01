; NAME:
;     DRIP_FLAT - Version .6.1
;                 (former flat__define)
;
; PURPOSE:
;	Flat field corrects data frames
;
; CALLING SEQUENCE:
;       FLATTED=DRIP_FLAT(DATA,MASTERFLAT)
;
; INPUTS:
;	MASTERFLAT - The reduced flatfield master image
;	DATA - image array to be corrected
;
; OUTPUTS:
;	FLATTED - Flatted image
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	A master flat field image has to be created beforehand by
;	cleaning and summing individual flat field images and dividing
;	the sum by its median.
;       Each member of the input data sets by this masterflat
;
; MODIFICATION HISTORY:
;   Written by:  Alfred Lee, Cornell University, 2001
;	Modified: Alfred Lee, CU, June 6, 2002
;			Changed into an object.
;	Modified: Alfred Lee, CU, June 18, 2002
;			fixed minor bug, added cleaning to the flat fields.
;	Modified: Alfred Lee, CU, June 24, 2002
;			Created RUN method to run the code as needed after a
;			single initialization.
;	Modified: Alfred Lee, CU, July 18, 2002
;			enhanced error checking
;	Modified: Alfred Lee, CU, August 2, 2002
;			updated to new architecture.  most data now stored in
;			a Data Manager object.
;       Rewritten: Marc Berthoud, CU, July 2004
;                  Rewrote from object to one-line command
;                  Most code erased (see flat__define v.5.0)
;                  Makemaster is now in drip::getcal
;

;******************************************************************************
;	DRIP_FLAT - Flattens frames using masterflat.
;******************************************************************************

function drip_flat, data, masterflat, darksum

; error check
s=size(data)
if (s[0] lt 2) or (s[0] gt 3) then begin
    drip_message, 'drip_flat - Must provide valid data array',/fatal
    return, data
endif
if size(masterflat,/n_dimen) ne 2 then begin
    drip_message, 'drip_flat - Must provide valid masterflat - returning data'
    return, data
endif
;make corrections
if s[0] eq 2 then begin
    ; one data frame
    flatted=(data-darksum)/masterflat
endif else begin
    ; numerous frames
    flatted=fltarr(s[1],s[2],s[3],/nozero)
    for i=0,s[3]-1 do $
      flatted[*,*,i] = (data[*,*,i]-darksum)/masterflat
endelse
return,flatted
end

