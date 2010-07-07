function getpar, list, parname

; NAME:
;   GETPAR - Version 1.1
;
; PURPOSE:
;   Returning a named parameter in a list of the form
;     parameter=value
;   Can return string (starting with a ' ), float or integer values
;
; CALLING SEQUENCE:
;   VALUE = GETPAR( LIST, PARNAME )
;
; INPUTS:
;   LIST - List with the parameters in the form parameter=value
;          (array of strings)
;   PARNAME - Name of the parameter to be returned (string)
;
; OUTPUTS:
;   VALUE - The value found under parameter or zero if the parameter
;           is not found. In that case !ERR is set to -1.
;
; SIDE EFFECTS:
;   None Known
;
; RESTRICTIONS:
;
; PROCEDURE:
;   After uppercasing PARNAME the program searches the first string
;   starting with PARNAME. It then searches for the first non-space
;   character after an '=' sign. If that character is a ' the rest of
;   the string (without the last letter if it is a ' ) is returned as
;   string. Else the procedure searches for a '.', a 'e' or 'E'. If
;   any of these are found the procedure returns the rest of the string
;   as a float, if not as an integer.
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Cornell University 2003-11-10
;

  ; get name without leading/trailing blanks and upper case
  name=strtrim(strupcase(parname),2)
  ; check list
  s=size(list)
  if ( s[0] ne 1 ) or ( s[2] ne 7 ) then $
    message,'List must be a string array'
  ; search for name
  nfound=where((strpos(list,name) ge 0) and $
               (strpos(list,name) lt strpos(list,'=')), matches)
  if matches lt 1 then begin
    !ERR = -1
    return, long(-1)
  endif
  if matches gt 1 then begin
    message,/informational,'Warning: Keyword '+name+' located more than once'
  end
  nfound=nfound[0]
  ; put value in valstr
  valstr=strtrim(strmid(list[nfound],strpos(list[nfound],'=')+1),2)
  ; search for string
  if strpos(valstr,"'") eq 0 then $
    val=strmid(valstr,1,strlen(valstr)-2) $
  else if (strpos(valstr,'.') ge 0) or (strpos(valstr,'E') ge 0) then $
    val=float(valstr) else val=long(valstr)
  return, val
end
