pro ftsort,h,tab,hnew,tabnew,field
;+
; NAME:
;	FTSORT
; PURPOSE:
;	Sort a FITS ASCII table according to a specified field
;
; CALLING SEQUENCE:
;	FTSORT,H,TAB,[FIELD]	       ;Sort original table header and array
;		or
;	FTSORT,H,TAB,HNEW,TABNEW,[FIELD]   ;Create new sorted header
;
; INPUTS:
;	H - FITS header (string array)
;	TAB - FITS table (byte array) associated with H.  If less than 4
;		parameters are supplied, then H and TAB will be updated to 
;		contain the sorted table
;
; OPTIONAL INPUTS:
;	FIELD - Field name used to sort the entire table.  Character fields
;		are sorted using the ASCII collating sequence.  If omitted,
;		the user will be prompted for the field name.
;
; OPTIONAL OUTPUTS:
;	HNEW,TABNEW - Header and table containing the sorted tables
;
; RESTRICTIONS:
;	FTSORT always sorts in order of increasing magnitude.  To sort
;	in decreasing magnitude, type TAB = REVERSE(TAB,2) after running
;	FTSORT.
;
; SIDE EFFECTS:
;	A HISTORY record is added to the table header.
; REVISION HISTORY:
;	Written W. Landsman                         June, 1988
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2 
 npar = N_params()
 if npar lt 2 then begin
	print,'Syntax:  ftsort, h, tab, [ field ]'
        print,'    OR:  ftsort,h,tab,hnew,tabnew,[field]'
        return
 endif

 if npar eq 3 then field = hnew 

 if (npar eq 2) or (npar eq 4) then begin
	field  = ''
	read,'Enter field name to be used to sort table: ',field
 endif

 ftinfo,h,field,tbcol,width,idltype,tunit,tscal,tzero,tnull,tform,ttype

 if !ERR eq -1 then begin
	print,string(7B),'FTSORT: ERROR - Unidentified field ',field
        print,'Field name must be chosen from the following'
        print,ttype
        return
 endif

 key = ftget(h,tab,field)
 index = sort(key)
 if npar ge 4 then begin
	hnew = h
	tabnew = string(tab)
	tabnew = byte(tabnew[index])
        sxaddhist,'FTSORT: '+ systime() +' SORT KEYWORD - '+ttype,hnew
 endif else begin
	tab = string(tab)
	tab = byte(tab[index])
        sxaddhist,'FTSORT: '+ systime() +' SORT KEYWORD - '+ttype,h
 endelse

 return
 end
