function drip_jbclean, data, header

; Remove "jailbar" array pattern noise using FFT and
; to create a spatial filter
jbcleaned = data
jbmethod= drip_getpar(header, 'JBCLEAN')
;jailbar=fltarr(s[1],s[2],/nozero)
;jcleaned=fltarr(s[1],s[2],/nozero)
;print,jbmethod
;if jbmethod eq 'FFT' then begin
;    drip_message,'FFT jailbar correction not available, using MEDIAN'
;    jbmethod='MEDIAN'
    ;jailbar=data
    ; Generate FFT of image
    ;fft_data = fft(jailbar)
    ; Create Mask in Fourier space that zeros out periods of 16 pixels
    ;indx = findgen(15)*16.0 + 16.0
    ;jbmask = complexarr(256,256) + 1.0
    ;jbmask[indx,*] = 0.0
    ; Apply Mask
    ;jbcleaned = fft(fft_data*jbmask,/INVERSE) ; abs(fft(fft_data*jbmask,/INVERSE))
;endif
if jbmethod eq 'MEDIAN' then begin
    ; Clean "jailbar" pattern noise from background-subtracted image using median
    ; of correlated columns (every 16)
    sm_box = 10 ; smoothing box in pixels
    jailbar=data-filter_image(data, median = sm_box,/all_pixels)  ; Smooth (median)
    index=indgen(256/16)*16  ;index every 16th pixel in a row
    for k=0,255 do begin
        for j=0,15 do begin
            jailbar(index+j,k)=median(jailbar(index+j,k))
        endfor
    endfor
    jbcleaned = data-jailbar
endif

return, jbcleaned

end
