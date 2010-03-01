pro ftdelcol,h,tab,name                                               
;+
; NAME:
;	FTDELCOL
; PURPOSE:
;	Delete a column of data from a FITS table
;
; CALLING SEQUENCE:
;	ftdelcol, h, tab, name
;
; INPUTS-OUPUTS
;	h,tab - FITS table header and data array.  H and TAB will
;		be updated with the specified column deleted
;
; INPUTS:
;	name - Either (1) a string giving the name of the column to delete
;		or (2) a scalar giving the column number to delete
;
; EXAMPLE:
;	Suppose it has been determined that the F7.2 format used for a field
;	FLUX in a FITS table is insufficient.  The old column must first be 
;	deleted before a new column can be written with a new format.
;
;	flux = FTGET(h,tab,'FLUX')       ;Save the existing values
;	FTDELCOL,h,tab,'FLUX'            ;Delete the existing column            
;	FTADDCOL,h,tab,'FLUX',8,'F9.2'   ;Create a new column with larger format
;	FTPUT,h,tab,'FLUX',0,flux        ;Put back the original values
;
; REVISION HISTORY:                                           
;	Written   W. Landsman        STX Co.     August, 1988
;	Adapted for IDL Version 2, J. Isensee, July, 1990
;	Converted to IDL V5.0   W. Landsman   September 1997
;- 
 On_error,2

 if N_params() LT 3 then begin
     print,'Syntax - ftdelcol, h, tab, name'
     return
 endif

 s = size(name)

 ftsize,h,tab,ncol,nrows,tfields,allcols,allrows

; Make sure column exists

 ftinfo, h, name, tbcol, width     ;Get starting column and width (in bytes)
 field = !ERR                      ;Field number specified
 if field lt 1 then message,'Specified field "'+name+'" does not exist'

; Eliminate relevant columns from TAB

 tbcol = tbcol-1                     ;Convert to IDL indexing

 case 1 of 
 tbcol eq 0: tab = tab[width:*,*]                     ;First column
 tbcol eq ncol-width: tab = tab[0:tbcol-1,*]          ;Last column
 else: tab = [tab[0:tbcol-1,*],tab[tbcol+width:*,*]]  ;All other columns
 endcase

; Parse the header.  Remove specified keyword from header.  Lower
; the index of subsequent keywords.  Update the TBCOL*** index of
; subsequent keywords

 hnew = strarr(n_elements(h))
 j = 0
 for i= 0,N_elements(h)-1 do begin    ;Loop over each element in header
 key = strupcase(strmid(h[i],0,5))
 if (key eq 'TTYPE') OR (key eq 'TFORM') or (key eq 'TUNIT') or $
    (key eq 'TNULL') OR (key eq 'TBCOL') then begin
    row = h[i]                    
    ifield = fix(strtrim(strmid(row,5,3)))    
    if ifield gt field then begin    ;Subsequent field?
      if ifield le 10 then fmt = "(I1,' ')" else fmt ='(I2)'
      strput,row,string(ifield-1,format=fmt),5
      if key eq 'TBCOL' then begin
         value = fix(strtrim(strmid(row,10,20)))-width
         v = string(value)
         s = strlen(v)
         strput,row,v,30-s                  ;Right justify
      endif
   endif 
   if ifield ne field then hnew[j] = row else j=j-1

 endif else hnew[j] = h[i]      

 j = j+1
 endfor   

 sxaddpar,hnew,'TFIELDS',tfields-1 ;Reduce number of fields by 1
 sxaddpar,hnew,'NAXIS1',ncol-width ;Reduce num. of columns by WIDTH

 h = hnew[0:j-1]
 print,'Field ',strupcase(name),' has been deleted from the FITS table

 return  
 end
