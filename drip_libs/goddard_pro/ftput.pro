pro ftput,h,tab,field,row,values,nulls
;+
; NAME:
;	FTPUT
; PURPOSE:
;	Procedure to add or update a field in an FITS ASCII table
;
; CALLING SEQUENCE:
;	FTPUT, htab, tab, field, row, values, [ nulls ]
;
; INPUTS:
;	htab - FITS ASCII table header string array
;	tab - FITS ASCII table array (e.g. as read by READFITS)
;	field - string field name or integer field number
;	row -  either a non-negative integer scalar giving starting row to 
;		update, or a non-negative integer vector specifying rows to 
;		update.   FTPUT will append a new row to a table if the value 
;		of 'row' exceeds the number of rows in the tab array	
;	values - value(s) to add or update.   If row is a vector
;		then values must contain the same number of elements.
;
; OPTIONAL INPUT:
;	nulls - null value flag of same length as values.
;		It should be set to 1 at null value positions
;		and 0 elsewhere.
;
; OUTPUTS:
;	htab,tab will be updated as specified.
;
; NOTES:
;	(1) If the specified field is not already in the table, then FTPUT will
;	create a new column for that field using default formatting.   However,
;	 FTADDCOL should be called prior to FTPUT for explicit formatting.
;
; PROCEDURES CALLED
;	FTADDCOL, FTINFO, FTSIZE, SXADDPAR, SXPAR()
; HISTORY:
;	version 1  D. Lindler July, 1987
;	Allow E format         W. Landsman          March 1992
;	Write in F format if E format will overflow    April 1994
;	Update documentation W. Landsman   January 1996
;	Allow 1 element vector  W. Landsman   March 1996
;	Adjust string length to maximum of input string array   June 1997
;	Work for more than 32767 elements August 1997
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2

 if N_params() LT 5 then begin
    print,'Syntax - FTPUT, htab, tab, field, row, values, [nulls]'
    return
 endif

 nrow = N_elements(row)        ;Number of elements in row vector

 if N_params() GT 5 then nullflag = 1 else nullflag = 0  ; Null values supplied?

 ftsize,h,tab,ncols,nrows,tfields,allcols,allrows     ; Get size of table

; Make values a vector if scalar supplied

 s = size(values) & ndim = s[0] & type = s[ndim+1]

 if ndim gt 1 then $
	message,'Input values must be scalar or 1-D array'

 sz_row = size(row)
 scalar = sz_row[0] EQ 0

 v = values
 if nullflag then nullvals = nulls

; Get info on field specified

 ftinfo,h,field,tbcol,width,idltype,tunit,tscal,tzero,tnull,tform,ttype

 if !err lt 0 then begin		;Does it exist?

; Add new column if it doesn't exist

	  if type EQ 7 then type = (-max(strlen(v)))
	  ftaddcol, h, tab, field, type
	  ftinfo,h,field,tbcol,width,idltype,tunit,tscal,tzero,tnull,tform,ttype
	  ftsize,h,tab,ncols,nrows,tfields,allcols,allrows
 end

 tbcol = tbcol-1			;IDL starts at zero not one.

; Convert input vector to string array

 n = N_elements(v)
 data = string(replicate(32b, width, n ) )
 if nrow GT 1 then if (nrow NE n) then $
        message,'Number of specified rows must equal number of values'

 fmt = strupcase(strtrim(tform,2))
 fmt1 = strmid(fmt,0,1)
 if (fmt1 EQ 'D') or (fmt1 EQ 'E') then begin  ;Need at least 6 chars for E fmt
 	point = strpos(fmt,'.')
	wid = fix(strmid(fmt,1,point-1))
        decimal = fix(strmid(fmt,point+1,1000))
	if wid-decimal LT 6 then fmt = 'F' + strmid(fmt,1,1000)
 endif
 fmt = '(' + fmt + ')'
 for i = 0L,n-1 do data[i] = string(v[i], FORMAT = fmt)

; insert null values

 if nullflag GT 5 then begin
	bad = where(nullvals, Nbad)
	if Nbad GT 0 then for i = 0L, Nbad-1 do data[bad[i]] = tnull
 end

;
; Do we need to increase the number of rows in the table?
;
if scalar then maxrow = row+n else maxrow = max(row) + 1
if maxrow GT allrows then begin		;expand table size

    ;
    ;  Create a replacement table with the required number of rows.
    ;
    newtab = replicate(32b,allcols,maxrow)
    newtab[0,0] = tab

    ;
    ;  Create the new line to stuff into the new slots.
    ;
    new_line = string( replicate(32b,allcols))
    fields = sxpar(h, 'TFIELDS')
    for i = 1, fields do begin
	fld_type = sxpar(h, 'TFORM'+strtrim(string(i),2))
	fld_type = strupcase(strmid(fld_type, 0, 1))
	if (fld_type ne 'A') then begin
	    pos = sxpar(h, 'TBCOL'+strtrim(string(i),2))
	    strput,new_line,'0',pos-1
	endif
    endfor

    ;
    ;  Put zeroes where the number slots of each new record.
    ;
    for i = allrows, (maxrow-1) do newtab[*,i] = byte(new_line)

    ;
    ;  Move the new table into the old table.
    ;
    tab = newtab

end
 if maxrow GT nrows then sxaddpar,h,'naxis2',maxrow

;
;  Now insert into table.
;
  if scalar then tab[tbcol,row] = byte(data) $
  else for i = 0L,N_elements(row)-1 do tab[tbcol,row[i]] = byte(data[i])

;
;  Return to calling routine.
;
 return
 end
