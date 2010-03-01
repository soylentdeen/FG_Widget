function keyword_replace, header, changelist

; NAME:
;   KEYWORD_REPLACE - Version .1
;
; PURPOSE:
;   Replace / Add a list of keyword values in a fits header
;
; CALLING SEQUENCE:
;   NEW_HEADER=KEYWORD_REPLACE( HEADER, CHANGELIST)
;
; INPUTS:
;   HEADER - original header where keywords should be changed
;
;   CHANGELIST - array of strings with the following format:
;                ['keyword1=value1','keyword2=value2','keyword3=value3']
;
; OUTPUTS:
;   NEW_HEADER - A copy of HEADER with the keywords replaced / added
;
; SIDE EFFECTS:
;   None Known
;
; PROCEDURE:
;   After getting the size of the array the procedure replaces the
;   strings one by one. If the first value character is a ' the rest of
;   the string (without the last letter if it is a ' ) is set as
;   string. Else the procedure searches for a '.', a 'e' or 'E'. If
;   any of these are found the procedure returns sets a float, if not
;   an integer.
;   If keyword is equal '' no replacement is made
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Palomar 2005-6-23
;

; error check
s=size(changelist)
if (s[0] ne 1) or (s[2] ne 7) then $
  message, 'keyword_replace - must have valid changlist'
hs=size(header)
if (hs[0] ne 1) or (hs[2] ne 7) then $
  message, 'keyword_replace - must have valid header'
; get number of keywords to replace
n=s[1]
; replace them
for i=0,n-1 do begin
    pos=strpos(changelist[i],'=')
    key=strtrim(strmid(changelist[i],0,pos),2)
    valstr=strtrim(strmid(changelist[i],pos+1),2)
    if key ne '' then begin
        ; get real value
        if strpos(valstr,"'") eq 0 then $
          val=strmid(valstr,1,strlen(valstr)-2) $
        else if(strpos(valstr,'.') ge 0) or (strpos(valstr,'E') ge 0) then $
          val=float(valstr) else val=long(valstr)
        ; set value
        sxaddpar,header,key,val
    endif
endfor
return,header
end
