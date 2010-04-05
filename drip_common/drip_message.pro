; NAME:
;     DRIP_MESSAGE - Version 1.0
;
; PURPOSE:
;     Display a message from the drip with variable outputs
;
; CALLING SEQUENCE:
;     DRIP_MESSAGE, MSG, /FATAL
;
; INPUTS:
;     MSG - message to display (can be string or string array)
;     FATAL - indicates need for strong message / program interuption
;
; PROCEDURE:
;     Checks if a errmsg record is available in common
;     drip_config_info. If yes it uses gui procedures for message,
;     otherwise it uses normal idl procedures.
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, 2007-9
;

;****************************************************************************
;     DRIP_MESSAGE - display message
;****************************************************************************
pro drip_message, msg, fatal=fatal
; get number of elements
n=size(msg,/n_elements)
common drip_config_info, dripconf, drip_errproc
if size(drip_errproc,/type) ne 8 then begin
    ; display decode fatal
    if keyword_set(fatal) then begin
        if n gt 1 then begin
            for i=0, n-2 do print, msg[i]
            message,msg[n-1]
        endif else message, msg
    endif else begin
        if n gt 1 then for i=0, n-1 do print, msg[i] $
        else print,msg
    endelse
endif else begin
    ; get object and function
    obj=drip_errproc.object
    funct=drip_errproc.funct
    ; display decode fatal
    if keyword_set(fatal) then begin
        call_method, funct, obj, 'DRIP FATAL ERROR:'
        if n gt 1 then begin
            for i=0, n-1 do call_method, funct, obj, msg[i]
            r=dialog_message(msg)
        endif else begin
            call_method, funct, obj, msg
            r=dialog_message(msg)
        endelse
    endif else begin
        if n gt 1 then for i=0, n-1 do call_method, funct, obj, msg[i] $
        else call_method, funct, obj, msg
    endelse
endelse
end
