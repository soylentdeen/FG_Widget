pro ftprint,h,tab,columns,rows,textout=textout
;+
;  NAME:
;	FTPRINT
;  PURPOSE:
;	Procedure to print specified columns and rows of a FITS table
;
; CALLING SEQUENCE:
;	FTPRINT, h, tab, columns, [ rows, TEXTOUT = ]
;
; INPUTS:
;	h - Fits header for table, string array
;	tab - table array 
;	columns - string giving column names, or vector giving
;		column numbers (beginning with 1).  If string 
;		supplied then column names should be separated by comma's.
;	rows - (optional) vector of row numbers to print.  If
;		not supplied or set to scalar, -1, then all rows
;		are printed.
;
; OUTPUTS:
;	None
;
; OPTIONAL INPUT KEYWORDS:
;	TEXTOUT controls the output device; see the procedure TEXTOPEN
;
; SYSTEM VARIABLES:
;	Uses nonstandard system variables !TEXTOUT and !TEXTOPEN
;	Set !TEXTOUT = 3 to direct output to a disk file.   The system
;	variable is overriden by the value of the keyword TEXTOUT
;
; EXAMPLES:
;
;	ftprint,h,tab,'STAR ID,RA,DEC'    ;print id,ra,dec for all stars
;	ftprint,h,tab,[2,3,4],indgen(100) ;print columns 2-4 for 
;					  ;first 100 stars
;	ftprint,h,tab,text="STARS.DAT"    ;Convert entire FITS table to
;                                         ;an ASCII file named STARS.DAT
;
; PROCEDURES USED:
;	FTSIZE, FTINFO, TEXTOPEN, TEXTCLOSE
;
; RESTRICTIONS: 
;	(1) Program does not check whether output length exceeds output
;		device capacity (e.g. 80 or 132).
;	(2) Column heading may be truncated to fit in space defined by
;		the FORMAT specified for the column
;	(3) Program does not check for null values
;
; HISTORY:
;	version 1  D. Lindler Feb. 1987
;	Accept undefined values of rows, columns   W. Landsman August 1997
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2
;
; set defaulted parameters
;
 npar = N_params()
 if npar LT 2 then begin
   print,'Syntax -  FTPRINT, h, tab, [ columns, rows, TEXTOUT= ]
   return
 endif

 if N_elements(columns) EQ 0 then columns = -1
 if N_elements(rows) EQ 0 then rows= -1
 if  not keyword_set(TEXTOUT)  then textout = !TEXTOUT

; make sure rows is a vector

 n = N_elements(rows)
 if n EQ 1 then r = intarr(n) + rows else r = long(rows)
 ftsize,h,tab,ncols,nrows,tfields,allcols,allrows		;table size
 if !err LT 0 then $
	message,'Invalid FITS header for table file'
 if r[0] EQ -1 then r = lindgen(nrows)		;default

;
; if columns is a string, change it to string array
;
 s = size(columns) & ndim = s[0] & dtype = s[ndim+1]
 colnames = strarr(30)			;string array to hold names
 if dtype EQ 7 then begin
	colnames = strarr(30)		;string array to hold names
	numcol = 0			;number of columns
	st = columns			;don't want to change columns var.
	while st ne '' do begin
		colnames[numcol] = gettok(st,',')
		numcol = numcol+1
	endwhile
   end else begin			;user supplied vector
	colnum = fix(columns)		;make sure it is integer
	numcol = N_elements(colnum)	;number of elements
	if numcol EQ 1 then begin
        colnum = intarr(1)+colnum ;make sure it is vector
        if colnum[0] EQ -1 then begin 
              colnum = indgen(tfields) + 1 & numcol = tfields
         endif & endif
 end
;
; create vectors to hold column descriptions
;
 flen = intarr(numcol)			;field lengths
 colpos = intarr(numcol)			;column position in tab
;
; extract column info
;
 title1 = '   ROW   '
 title2 = '         '
 for i = 0,numcol-1 do begin
        if dtype EQ 7 then field = strtrim(colnames[i],2) else $ 
           field = colnum[i]
	ftinfo,h,field,tbcol,len,idltype,tunit,tscal,tzero,tnull,tform,ttype
        if !ERR EQ -1 then message, $
                   'ERROR - Field ' + field + ' not found in FITS ASCII table'
	flen[i]=len
	colpos[i]=tbcol
;
; create header lines
;
	name = strtrim(ttype,2)
	len = strlen(name)
	if len GT flen[i] then begin		;name longer than field?
		name = strmid(name,0,flen[i])	;yes. trim it
	   end else begin
		blanks = (flen[i]-len)/2	;add blanks to each side
		if blanks GT 0 then name = string(replicate(32b,blanks))+$
					name+string(replicate(32b,blanks))
		if strlen(name) LT flen[i] then name=' '+name ;if odd number
	end
	title1 = title1+' '+ name
	unit = strtrim(tunit,2)
	len = strlen(unit)
	if len GT flen[i] then begin		;unit too long?
		unit=strmid(unit,0,flen[i])	;yes, trim it
	    end else begin
		blanks=(flen[i]-len)/2		;number of blanks
		if ( blanks GT 0 ) then unit=string(replicate(32b,blanks)) + $
					unit+string(replicate(32b,blanks))
		if ( strlen(unit) LT flen[i] ) then unit=' '+unit
	end
	title2=title2+' '+unit
 end
;
; open output file
;
 textopen,'FTPRINT',TEXTOUT=textout
;
; loop on rows 
;
 printf,!TEXTUNIT,title1
 printf,!TEXTUNIT,title2
 printf,!TEXTUNIT,' '
 for i = 0, N_elements(r)-1 do begin
	rnum = r[i]
	if (rnum LT 0) or (rnum GE nrows) then goto,NEXTI	;invalid row #
;
; loop on columns
;
	line = string(rnum,format='(i7)')+'  '		;print line
	for j = 0,numcol-1 do begin
		cpos=colpos[j]-1			;column number
                val = string(tab[cpos:cpos+flen[j]-1,rnum])
		line = line+' '+ val
	endfor
	printf,!TEXTUNIT,line
        if (!TEXTOUT EQ 1) then if (!ERR EQ 1) then goto, DONE
NEXTI:
 endfor
;
; done
;
DONE: 
 textclose,textout=textout

 return
 end
