pro ftinfo,h,field,tbcol,width,idltype,tunit,tscal,tzero,tnull,tform,ttype
;+
; NAME:
;	FTINFO
; PURPOSE:
;	Procedure to return information on the specified field 
;	in a FITS ASCII table.
; CALLING SEQUENCE:
;	ftinfo,h,field,tbcol,width,idltype,tunit,tscal,tzero,tnull,
;		tform,ttype
;
; INPUTS:
;	h - FITS ASCII table header
;	field - field name or field number (beginning at 1)
;
; OUTPUTS:
;	tbcol - starting column position in bytes
;	width - width of the field in bytes
;	idltype - idltype of field.
;			7 - string, 4- real*4, 3-integer, 5-real*8
;	tunit - string unit numbers
;	tscal - scale factor
;	tzero - zero point for field
;	tnull - null value for the field
;	tform - format for the field
;	ttype - field name
;
; SIDE EFFECTS:
;	!err is set to the field number.  If the specified field is not
;	in the table then !err is set to -1.
;
; HISTORY:
;	D. Lindler  July, 1987
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;----------------------------------------------------------------------------
On_error,2
;
; get number of fields
;
tfields = sxpar( h, 'TFIELDS' )
if !err lt 0 then $
	message,'Invalid FITS header. keyword TFIELDS is missing'

;
; if input is a field name then determine field number
;
s = size(field)
if ((s[0] ne 0) or (s[1] EQ 0)) then $
	message,'Invalid field specification, it must be a scalar'
;
if s[1] EQ 7 then begin			;Field name?
	if tfields EQ 0 then begin	;ANY fields in table
		!ERR = -1
		return
	end
	fname = strtrim(strupcase(field))
	ttype = sxpar(h,'TTYPE*')
	for i = 1,tfields do begin	; find match
		name = strupcase(strtrim(ttype[i-1]))
		if name EQ fname then goto,found
	end
	!ERR = -1		;not found
	return
found:	fpos = i
   end else begin			;number specified
	fpos = long(field)
	if fpos gt tfields then begin
		!err = -1
		message,'Invalid field number specified'
	end
end

;
; get info for specified field
;
apos = strtrim(fpos,2)		;convert to ascii
ttype = sxpar(h,'ttype'+apos)			;field name
if !err LT 0 then begin
	apos = strmid(string(fpos+1000,format = '(I4)'),1,3)
	ttype = sxpar(h,'ttype'+apos)
end
if !err LT 0 then $
	message,'Invalid FITS table header -- keyword TTYPE'+apos+' not present'
;
tbcol = sxpar(h,'tbcol'+apos)			;staring column position
if !err LT 0 then $
	message,'Invalid FITS table header -- keyword TBCOL' + $
                          apos+' not present'
;
tform = sxpar(h,'tform'+apos)			; column format
if !err LT 0 then $
	message,'Invalid FITS table header -- keyword TFORM'+apos+' not present'
;						; physical units
tunit = sxpar(h, 'TUNIT' + apos)
if !err LT 0 then tunit = ''
;
tscal = sxpar(h, 'TSCAL' + apos)			; data scale factor
if !err LT 0 then tscal = 1
;
tzero = sxpar(h,'TZERO' + apos)			; zero point for field
if !err LT 0 then tzero = 0
;
tnull = sxpar(h,'TNULL' + apos)			;null data value
if !err LT 0 then tnull = ''
;
; determine idl data type from format
;
type = strmid(tform,0,1)
case strupcase(type) of
	'A' : idltype = 7
	'I' : idltype = 3
	'E' : idltype = 4
	'F' : idltype = 4
	'D' : idltype = 5
	else: message,'Invalid format specification for keyword ' + $
			'TFORM'+apos
end
;
; get field width in characters
;
width = fix(strtrim(gettok(strmid(tform,1,strlen(tform)-1),'.'),2))
!err = fpos
return
end
