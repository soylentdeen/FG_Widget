pro dbsearch,type,svals,values,good, FULLSTRING = fullstring
;+
; NAME:
;	DBSEARCH
; PURPOSE:
;	Subroutine of DBFIND() to search a vector for specified values
;
; CALLING SEQUENCE:
;	dbsearch, type, svals, values, good, FULLSTRING = fullstring
;
; INPUT: 
;	type - type of search (output from dbfparse)
;	svals - search values (output from dbfparse)
;	values - array of values to search
;
; OUTPUT:
;	good - indices of good values
;	!err is set to number of good values
;
; OPTIONAL INPUT KEYWORD:
;	FULLSTRING - By default, one has a match if a search string is 
;		included in any part of a database value (substring match).   
;		But if /FULLSTRING is set, then all characters in the database
;		value must match the search string (excluding leading and 
;		trailing blanks).    Both types of string searches are case
;		insensitive.
; REVISION HISTORY:
;	D. Lindler  July,1987
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;-----------------------------------------------------------
 On_error,2
 svals = strupcase(svals)
;
; determine data type of values to be searched
;
 s=size(values) & datatype=s[s[0]+1] & nv = N_elements(values)
;
; convert svals to correct data type
;
 nvals = type>2
 if datatype NE 7 then sv = replicate(values[0],nvals) else $
                      sv = replicate(' ',nvals)
On_ioerror, BADVAL              ;Trap any type conversions
sv[0]= svals[0:nvals-1]
On_ioerror, NULL
sv0=sv[0] & sv1=sv[1]
;
; -----------------------------------------------------------
;      STRING SEARCHES (Must use STRPOS to search for substring match)
;
if datatype EQ 7 then begin
    valid = bytarr(nv)
    values = strupcase(values)
    case type of
						
         0: if keyword_set(FULLSTRING) then $            ;Exact string match?
	    valid = strtrim(values,2) EQ strtrim(sv0,2) else $
	    valid = strpos(values,strtrim(sv0,2)) GE 0   ;substring search
        -1: valid = values GE sv0                        ;greater than
	-3: valid = (values GE sv0) and (values LE sv1)  ;in range
	-4: valid = strtrim(values) NE ''       ;non zero (i.e. not null)
        -5: message, $                                  ;Tolerance value
               ' Tolerance specification for strings is not valid'
         else:  begin
                sv = strtrim(sv,2)

		if keyword_set(FULLSTRING) then begin
		values = strtrim(values,2)
                for ii = 0l,type-1 do valid = (values EQ sv[ii]) or valid

                endif else begin

                for ii=0L,type-1 do begin               ;within set of substring
		valid = (strpos(values,sv[ii]) GE 0) or valid
                endfor

		endelse
                end
	endcase
	good = where(valid)
	return
end
;
;---------------------------------------------------------------------
;		ALL OTHER DATA TYPES
case type of
 
	 0: good = where( values EQ sv0 )               ;value=sv0
	-1: good = where( values GE sv0 )		;value>sv0
	-2: good = where( values LE sv1 )		;value<sv1
	-3: begin				;sv0<value<sv1
	    if sv1 lt sv0 then begin
	        temp=sv0
		sv0=sv1
		sv1=temp
	    end
	    good=where((values GE sv0) and (values LE sv1))
	    end 	
	-5: begin				;sv1 is tolerance
	    minv=sv0-abs(sv1)
	    maxv=sv0+abs(sv1)
	    good=where( (values GE minv) and (values LE maxv) )
	    end
	-4: good=where(values)			;non-zero
	else: begin				;set of values	
	      nf=0				;number found
	      for i=0L,type-1 do begin		;loop on possible values    
		g = where( values EQ sv[i])
		if !err gt 0 then begin
			if nf eq 0 then good=g else good=[good,g]
			nf=nf+!err
		endif
	      end
	      !err=nf
              if nf EQ 0 then good = intarr(1)-1   ;Make sure good is defined
	      end
endcase
return
BADVAL: !ERR=-2       ;Illegal search value supplied
return
end
