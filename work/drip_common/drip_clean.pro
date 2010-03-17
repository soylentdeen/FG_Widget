; NAME:
;     DRIP_CLEAN - Version .7.0
;                  (former clean__define)
;
; PURPOSE:
;     Replaces bad pixels in an image with approximate values.
;
; CALLING SEQUENCE:
;     CLEANED=DRIP_CLEAN(DATA,BADMAP)
;
; INPUTS:
;     DATA - Array with bad pixels
;     BADMAP - Bad pixel map (bad pixels are zero)
;
; OUTPUTS:
;     CLEANED - see below
;
; SIDE EFFECTS:
;     None.
;
; RESTRICTIONS:
;     None
;
; PROCEDURE:
;     Uses sigma_filter procedure to clean the image
;
; MODIFICATION HISTORY:
;   Written by:  Alfred Lee, Cornell University, 2001
;     Modified:   Alfred Lee, CU, June 6, 2002
;                 changed CLEAN into an object.
;     Modified:   Alfred Lee, CU, June 24, 2002
;                 created a RUN method to run the code as needed after a single
;                 initialization.
;     Modified:   Alfred Lee, CU, June 27, 2002
;                 changed bad pixel criterion into 3 standard deviations above
;                 or below the mean value of the image.
;     Modified:   Alfred Lee, CU, July 18, 2002
;                 enhanced error checking.
;     Modified:   Alfred Lee, CU, August 1, 2002
;                 updated to new architecture.  data now stored in a Data
;                 Manager object.
;     Modified:   Alfred Lee, CU, September 9, 2002
;                 changed GOTO statement into a REPEAT...UNTIL statement.
;     Rewritten:  Marc Berthoud, CU, July 2004
;                 rewrote form object to a one-line command
;                 most code erased (see clean__define v.5.2)
;                 uses maskinterp
;     Modified:   Marc Berthoud, CU, February, 2005
;                 added automatic detection of bad pixels
;                 (but commented it out)

;******************************************************************************
;     RUN - Fills SELF structure pointer heap variables with proper values.
;******************************************************************************

function drip_clean, data, badmap

; error check
s=size(data)
if (s[0] lt 2) or (s[0] gt 3) then begin
    drip_message, 'drip_clean - Must provide valid data array',/fatal
    return, data
endif
if size(badmap,/n_dimen) ne 2 then begin
    drip_message, $
      'drip_clean - Must provide valid bad pixel map - returning data'
    return, data
endif
; set variables
meddist=3 ; distance for taking median
sigfac=100.0 ; threshold for how many sigmas until a pixel is considered bad
; get array, do correction
if s[0] eq 2 then begin
    ;** one data frame
    ; make mask
    badmask=(badmap eq 0)
    ; clean
    cleaned=maskinterp(data,badmask,1,6,"plsfit")
endif else begin
    ;** numerous frames
    cleaned=fltarr(s[1],s[2],s[3],/nozero)
    for i=0,s[3]-1 do begin
        ; SIGMA FILTER it
        ;cleaned[*,*,i]=sigma_filter(data[*,*,i],5, n_sigma=3)
        ; FIND BAD PIXELS
        ; find additional bad pixels
        datanow=data[*,*,i]
        ;datamed=median(datanow,meddist)
        ;sig=stdev(datanow-datamed)
        ;print,'  drip_clean: sig0=',sig
        ; get new sigma by eliminating really bad pixels
        ;badind=where((abs(datanow-datamed) gt sigfac*sig) or (badmap ne 0))
        ;if (size(badind))[0] gt 0 then begin
        ;    datamed[badind]=datanow[badind]
        ;    sig=stdev(datanow-datamed)
        ;endif
        ;print,'  drip_clean: sig1=',sig
        ; make mask
        ;badmask=(badmap eq 0)
        ;if (size(badind))[0] gt 0 then badmask[badind]=0
        ;badind=where(abs(datanow-datamed) gt sigfac*sig)
        ;if (size(badind))[0] gt 0 then badmask[badind]=0
        ; MASKINTERP it
        badmask=(badmap eq 0)
        ; clean
        cleaned[*,*,i]=maskinterp(datanow,badmask,1,6,"plsfit")
    endfor
endelse
return, cleaned
end
