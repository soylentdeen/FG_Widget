pro fthmod,h,field,parameter,value
;+
; NAME:
;	FTHMOD
; PURPOSE:
;	Procedure to modify header information for a specified field
;	in a FITS table.
;
; CALLING SEQUENCE:
;	fthmod, h, field, parameter, value
;
; INPUT:
;	h - FITS header for the table
;	field - field name of number
;	parameter - string name of the parameter to modify.  Choices
;		include:
;			TTYPE - field name
;			TUNIT - physical units for field (eg. 'ANGSTROMS')
;			TNULL - null value (string) for field, (eg. '***')
;			TFORM - format specification for the field
;			TSCAL - scale factor
;			TZERO - zero offset
;		User should be aware that the validity of the change is
;		not checked.  Unless you really know what you are doing,
;		this routine should only be used to change field names,
;		units, or another user specified parameter.
;	value - new value for the parameter.  Refer to the FITS table
;		standards documentation for valid values.
;
; METHOD:
;	The header keyword <parameter><field number> is modified
;	with the new value.
; HISTORY:
;	version 1, D. Lindler  July 1987
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;-----------------------------------------------------------------------
on_error,2
ftinfo,h,field
if !err lt 0 then message,'Specified field '+field + ' does not exist'
;
par=parameter+strtrim(!err,2)
sxaddpar,h,par,value
return
end
