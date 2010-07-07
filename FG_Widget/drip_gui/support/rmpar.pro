pro rmpar, list, parname

; NAME:
;   RMPAR - Version 1.1
;
; PURPOSE:
;   Removing a named parameter in a list of the form
;     parameter=value
;   Will remove the line if parameter is in list
;
; CALLING SEQUENCE:
;   RMPAR LIST, PARNAME
;
; INPUTS:
;   LIST - List with the parameters in the form parameter=value
;          (array of strings)
;   PARNAME - Name of the parameter to be set (string)
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
;   starting with PARNAME. If found it appends removes the string from
;   the array.
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Palomar 2005-6-26
;

  ; get name without leading/trailing blanks and upper case
  name=strtrim(strupcase(parname),2)
  ; check list
  s=size(list)
  if ( s[0] ne 1 ) or ( s[2] ne 7 ) then $
    message,'List must be a string array'
  ; search for not name
  nfound=where((strpos(list,name) lt 0) or $
               (strpos(list,name) gt strpos(list,'=')))
  list=list[nfound]
end
