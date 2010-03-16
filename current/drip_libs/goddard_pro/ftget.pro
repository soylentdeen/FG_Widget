function ftget,h,tab,field,rows,nulls
;+
; NAME:
;	FTGET 
; PURPOSE:
;	Function to return value(s) from specified column in a FITS ASCII table
;
; CALLING SEQUENCE
;	values = FTGET( h, tab, field, [ rows, nulls ] )
;
; INPUTS:
;	h - FITS ASCII extension header (e.g. as returned by FITS_READ)
;	tab - FITS ASCII table array (e.g. as returned by FITS_READ)
;	field - field name or number
;
; OPTIONAL INPUTS:
;	rows -  scalar or vector giving row number(s)
;		Row numbers start at 0.  If not supplied or set to
;		-1 then values for all rows are returned
;
; OUTPUTS:
;	the values for the row are returned as the function value.
;	Null values are set to 0 or blanks for strings.
;
; OPTIONAL OUTPUT:
;	nulls - null value flag of same length as the returned data.
;		It is set to 1 at null value positions and 0 elsewhere.
;		If supplied then the optional input, rows, must also 
;		be supplied.
;
; EXAMPLE:
;	Read the columns labeled 'WAVELENGTH' and 'FLUX' from the second
;	(ASCII table) extension of a FITS file 'spectra.fit'
;
;	IDL> fits_read,'spectra.fit',tab,htab,exten=2     ;Read 2nd extension
;	IDL> w = ftget(tab,htab,'wavelength')      ;Wavelength vector
;	IDL> f = ftget(tab,htab,'flux')            ;Flux vector
;
; NOTES:
;	(1) Use the higher-level procedure FTAB_EXT to extract vectors 
;		directly from the FITS file.
;	(2) Use FTAB_HELP or FTHELP to determine the columns in a particular
;		ASCII table.
; HISTORY:
;	coded by D. Lindler  July, 1987
;	Always check for null values    W. Landsman          August 1990
;	More informative error message  W. Landsman          Feb. 1996
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;------------------------------------------------------------------
 On_error,2
 !err=0			;no error yet

; get size of table

 ftsize,h,tab,ncols,nrows,tfields

; get characteristics of specified field

 ftinfo,h,field,tbcol,width,idltype,tunit,tscal,tzero,tnull
 if !err LT 1 then message, $ 
	'Specified field ' + strupcase(strtrim(field,2)) + ' not in table'
 tbcol = tbcol-1			;IDL starts at zero not one

; if rows not supplied then return all rows

 if N_params() LT 4 then rows = -1

; determine if scalar supplied

 row = rows
 s = size(row) & ndim = s[0]
 if ndim EQ 0 then begin		;scalar?
        if row LT 0 then begin	; -1 get all rows
		ndim = 1
		row = lindgen(nrows)
	   end else begin
		row = lonarr(1) + row
	end
 end

; check for valid row numbers

 if (min(row) lt 0) or (max(row) gt (nrows-1)) then $
	message,'ERROR - Row numbers must be between 0 and ' + $
		strtrim((nrows-1),2)

; get column

 if ndim EQ 0 then begin					;scalar?
	dd = string(tab[tbcol:tbcol+width-1,row[0]])
	data = strarr(1)
	data[0] = dd
    end else begin					;vector
	data = string(tab[tbcol:tbcol+width-1,*])
        data = data[row]
 end
 n = N_elements(data)

; check for null values

 len = strlen(data[0]) 	;field size
 while strlen(tnull) LT len do tnull = tnull + ' '	;pad with blanks
 if strlen(tnull) GT len then tnull = strmid(tnull,0,len)
 nulls = data EQ tnull
 valid = where(nulls EQ 0b, nvalid)

; convert data to the correct type

 d = make_array(size=[1,n,idltype,n])
 if nvalid GT 0 then d[valid] = data[valid]

 return,d
 end
