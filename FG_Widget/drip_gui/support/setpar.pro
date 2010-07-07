pro setpar, list, parname, value

; NAME:
;   SETPAR - Version 1.1
;
; PURPOSE:
;   Setting a named parameter in a list of the form
;     parameter=value
;   Will write new line if parameter is not in list, else change
;   value
;
; CALLING SEQUENCE:
;   SETPAR LIST, PARNAME, VALUE
;
; INPUTS:
;   LIST - List with the parameters in the form parameter=value
;          (array of strings)
;   PARNAME - Name of the parameter to be set (string)
;   VALUE - value of the parameter to be set (int, float or string)
;
; OUTPUTS:
;
; SIDE EFFECTS:
;   None Known
;
; RESTRICTIONS:
;
; PROCEDURE:
;   After uppercasing PARNAME the program searches the first string
;   starting with PARNAME. If not found it appends a new string to
;   the array. Then the (new or existing) string is rewritten in the
;   form
;     PARNAME = VALUE
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
    list=[list,'']
    nfound=[s[1]]
  endif
  if matches gt 1 then begin
    message,/informational,'Warning: Keyword '+name+' located more than once'
  end
  nfound=nfound[0]
  s=size(value)
  if s[0] ne 0 then $
    message,'Value must not be an array'
  case s[1] of
    1: valstr=string(value)
    2: valstr=string(value)
    3: valstr=string(value)
    4: valstr=string(value)
    5: valstr=string(value)
    6: message,'Invalid value type'
    7: valstr="'"+value+"'"
    8: message,'Invalid value type'
    9: message,'Invalid value type'
    10: message,'Invalid value type'
    11: message,'Invalid value type'
    12: valstr=string(value)
    13: valstr=string(value)
    14: valstr=string(value)
    15: valstr=string(value)
  endcase
  list[nfound]=name+' = '+strtrim(valstr,2)
end
