pro ftsize,h,tab,ncols,nrows,tfields,ncols_all,nrows_all
;+
; NAME:
;	FTSIZE
; PURPOSE:
;	Procedure to return the size of a FITS ASCII table.
;
; CALLING SEQUENCE:
;	ftsize,h,tab,ncols,rows,tfields,ncols_all,nrows_all
;
; INPUTS:
;	h - FITS ASCII table header, string array
;	tab - FITS table array, 2-d byte array
;
; OUTPUTS:
;	ncols - number of characters per row in table
;	nrows - number of rows in table
;	tfields - number of fields per row
;	ncols_all - number of characters/row allocated (size of tab)
;	nrows_all - number of rows allocated
;
; HISTORY
;	D. Lindler  July, 1987
;	Fix for 1-row table,  W. Landsman    HSTX,     June 1994
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;------------------------------------------------------------------------
 On_error,2

; check for valid header type

 s=size(h) & ndim=s[0] & type=s[ndim+1]
 if (ndim ne 1) or (type ne 7) then $
	message,'Invalid FITS header, it must be a string array'
 
; check for valid table array

 s = size(tab) & ndim = s[0] & vtype = s[ndim+1]
 if (vtype ne 1) then $                  ;Mod June 1994, for degenerate dim.
	message,'Invalid table array, it must be a 2-D byte array'

 ncols_all = s[1]			;allocated characters per row
 nrows_all = s[2]			;allocated rows

; Get number of fields

 tfields = sxpar(h,'TFIELDS', Count = N)  
 if N LT 0 then $
	message,'Invalid FITS ASCII table header, TFIELDS keyword missing'

; Get number of columns and rows

 ncols = sxpar(h, 'NAXIS1')
 nrows = sxpar(h, 'NAXIS2')

 return
 end
