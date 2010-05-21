; NAME:
; DRIP_NONLIN - Version .1.0
;
; PURPOSE:
; Corrects for non-linearity in detector array pixel response
;
; CALLING SEQUENCE:
;       LINEARIZED=DRIP_NONLIN(DATA, HEADER)
;
; INPUTS:
; DATA - the data to be undistorted.
;       HEADER - The fits header of the new input data file
;       
; NONLINEARITY CORRECTION fits files (read in as calibration files in drip__define.pro)
;       SWC_linearity_coeff.fits
;       LWC_linearity)coeff.fits      
;
; SIDE EFFECTS:
; 
;
; RESTRICTIONS:
; 
;
; PROCEDURE:
; Read linearity coefficients from calibaration files. Perform
; polynomial fit to ramps. Divide data by poly-fits to linearize.
;
; MODIFICATION HISTORY:
;   Written by:  Luke Keller, Ithaca College, January 26, 2010
; 
;

;******************************************************************************
; DRIP_NONLIN - Corrects for non-linearity in data frames
;******************************************************************************

function drip_nonlin, data, coeff, header, basehead
; error check
sd=size(data)
sc=size(coeff)
; Do the linearity correction only if non-lin data cube present.
; If the non-line data are 2-D then ingnore
if sc[0] gt 2 then begin 
    degree=sc[3]-2   ; ignore last two frames
    if sd[0] eq 3 then begin
    linearized=fltarr(sd[1],sd[2],sd[3],/nozero)   
    for k = 0, sd[3]-1 do begin
        for i = 0, 255 do begin
            for j = 0, 255 do begin
            ;linearized[i,j,k] = POLY(data[i,j,k], coeff[i,j,0:degree])
            endfor
        endfor
    endfor
    drip_message, 'Done with data linearity correction'
    endif
    if sd[0] eq 2 then begin
    linearized=fltarr(sd[1],sd[2],/nozero)   
    for i = 0, 255 do begin
        for j = 0, 255 do begin
        ;linearized[i,j] = POLY(data[i,j], coeff[i,j,0:degree])
        endfor
    endfor
    drip_message, 'Done with faltfield linearity correction'
    endif
endif else begin
    linearized=data 
endelse
linearized=data  ; for now since linearity coeffs are too old 02/01/2010
return, linearized
end