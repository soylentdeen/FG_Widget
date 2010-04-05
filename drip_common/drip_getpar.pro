; NAME:
;     DRIP_GETPAR - Version 1.1
;
; PURPOSE:
;     Get a header parameter with error treatment. If the parameter is
;     in the drip config, then the keyword in drip config is retrieved
;     from the header or the parameter from drip config is returned.
;
; CALLING SEQUENCE:
;     PARAM=DRIP_GETPAR( HEADER, PARNAME )
;
; INPUTS:
;     HEADER - Fits file header (as given by readfits)
;     PARNAME - Fits keyword of the parameter
;
; OUTPUTS:
;     PARAM - resulting parameter in STRING format
;             'x' if the resulting parameter is not found
;
; RATIONALE: In order to check if the parameter has been found, a
;     variable of known type must be returned. (Because IDL crashes if
;     ( 'x' eq 1 ) or ( 'x' eq 1.0 ) is called. ) Both FIX() and
;     FLOAT() can be used to convert any string to integer and float,
;     as they both continue (with a warning) if the string doesn't
;     describe a value.
;
; COMMENT:
;     This works even is sxpar returns an array of values.
;
; CALLED ROUTINES AND OBJECTS:
;     SXPAR
;
; SIDE EFFECTS:
;     None
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, June, 2004
;     Modified: Marc Berthoud, Cornell University, September 2007
;               Added use of dripconf and drip_message
;     Modified: Marc Berthoud, Cornell University, March 2010
;               Dropped requirement to have keyword in drip config,
;               now keyword can be retrieved directly from header
;               ==>> Now Version 1.1
;

;****************************************************************************
;     DRIP_GETPAR - set data values
;****************************************************************************

function drip_getpar, header, parname, vital=vital

; check if parameter is vital (to pass to drip_message)

; check validity of inputs
s=size(parname)
if (s[0] ne 0) or (s[1] ne 7) then begin
    drip_message,'drip_getpar - invalid parname'
    return,'x'
endif
s=size(header)
if (s[0] ne 1) or (s[2] ne 7) then begin
    drip_message,'drip_getpar - invalid header'
    return,'x'
endif
; load drip configuration if necessary
common drip_config_info, dripconf
if total(size(dripconf)) eq 0 then drip_config_load
; get name of calling routine
help, calls=list
caller=strmid(list[1],0,strpos(list[1],' '))
; get parameter from dripconf
confn=size(dripconf,/n_elements)
confi=0
found=0
while not found and confi lt confn do begin
    ; get string before '='
    pos=strpos(dripconf[confi],'=')
    if pos gt 0 then begin
        ; check for keyword
        key=strtrim(strmid(dripconf[confi],0,pos),2)
        if strupcase(key) eq strupcase(parname) then begin
            found=1
            value=strtrim(strmid(dripconf[confi],pos+1),2)
        endif else confi++
    endif else confi++
endwhile
; if parameter not found, set value = parameter
print,confi,confn
if confi eq confn then begin
    value = parname
endif
; Get fits keyword if requested (i.e. if first character is alphabetic)
cval=(byte(strupcase(value)))[0]
if cval lt 91 and cval gt 64 then begin
    ; cut value at first space
    pos=strpos(value,' ')
    if pos gt 0 then value=strmid(value,0,pos)
    ; get parameter
    paramval=sxpar(header,value)
    ; error message if not found
    if !err eq -1 then begin
        msg=caller+' - requires '+parname+' keyword in header / drip config'
        if keyword_set(vital) then drip_message, msg, /fatal $
        else drip_message, msg
        return,'x'
    endif else return, strtrim(string(paramval),2)
endif
; Get string without quotes if 'string' is given
if strpos(value,'''') eq 0 then begin
    pos=strpos(value,'''',/reverse_search)
    value=strtrim(strmid(value,1,pos-1),2)
endif
; add / change value in fits header
sxaddpar,header,parname,value
; return value
return,value
end

