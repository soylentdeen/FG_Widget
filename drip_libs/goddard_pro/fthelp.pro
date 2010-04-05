pro fthelp,h,TEXTOUT=textout
;+
; NAME:
;	FTHELP
; PURPOSE:
;	Routine to print a description of a FITS ASCII table extension
;
; CALLING SEQUENCE:
;	FTHELP, H, [ TEXTOUT = ]
;
; INPUTS:
;	H - FITS header for ASCII table extension, string array
;
; OPTIONAL INPUT KEYWORD
;	TEXTOUT - scalar number (0-7) or string (file name) determining
;		output device (see TEXTOPEN).  Default is TEXTOUT=1, output 
;		to the user's terminal    
;
; NOTES:
;	FTHELP checks that the keyword XTENSION  equals 'TABLE' in the FITS
;		header.
;
; SYSTEM VARIABLES:
;	Uses the non-standard system variables !TEXTOUT and !TEXTUNIT
;	which must be defined (e.g. with ASTROLIB) prior to compilation.
; PROCEDURES USED:
;	REMCHAR, SXPAR(), TEXTOPEN, TEXTCLOSE, ZPARCHECK
;
; HISTORY:
;	version 1  W. Landsman  Jan. 1988
;       Add TEXTOUT option, cleaner format  W. Landsman   September 1991
;	TTYPE value can be longer than 8 chars,  W. Landsman  August 1995
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2                                  ;Return to caller

 if N_params() EQ 0 then begin
     print,'Syntax - FTHELP, hdr, [ TEXTOUT = ]
     return
 endif

 zparcheck,'FTHELP',h,1,7,1,'Table Header'     ;Make sure a string array

 n = sxpar( h, 'TFIELDS' ) 
 if strtrim(sxpar(h,'XTENSION'),2) ne 'TABLE' then $
	message,'WARNING - Header is not for a FITS Table',/INF
if !ERR EQ -1 then message, $
        'ERROR - FITS Header does not include required TFIELDS keyword'

 if not keyword_set(TEXTOUT) then textout = 1
 textopen,'fthelp',TEXTOUT=textout

 printf,!TEXTUNIT,'FITS ASCII Table Header: '
 printf,!TEXTUNIT,'Extension Name: ',sxpar(h,'EXTNAME')
 extver = sxpar(h, 'EXTVER')
 if !ERR NE -1 then printf,!TEXTUNIT,'Version: ',extver
 printf,!TEXTUNIT,'Number of rows: ',strtrim(sxpar(h,'NAXIS2'),2) 
 printf,!TEXTUNIT,' '                         
 printf,!TEXTUNIT,  $
 'Field      Name               Unit           Format     Column'
 printf,!TEXTUNIT,' '

 tbcol = intarr(n)
 tform = strarr(n) & tunit = tform & ttype =tform
 tbcal = fltarr(n) + 1.

 for i = 1, N_elements(h)-1 do begin
  case strmid(h[i],0,5) of
   'TTYPE':  ttype[fix(strtrim(strmid(h[i],5,3),2))-1] = strmid(h[i],11,20)
   'TFORM':  tform[fix(strtrim(strmid(h[i],5,3),2))-1] = $
                            strtrim(strmid(h[i],11,20),2)
   'TUNIT':  tunit[fix(strtrim(strmid(h[i],5,3),2))-1] = strmid(h[i],11,20)
   'TBCOL':  tbcol[fix(strtrim(strmid(h[i],5,3),2))-1] = fix(strmid(h[i],10,20))
   'END  ':  goto, DONE 
    ELSE :
 end

 endfor

DONE:                            ;Done reading FITS header

 for i = 0,n-1 do begin 
        xtype = strtrim(ttype[i],2) & xunit = tunit[i] & xform = tform[i]
        remchar,xtype,"'" & remchar,xunit,"'" & remchar,xform,"'"
 printf,!TEXTUNIT,i+1,xtype,xunit,xform,tbcol[i], $
              f='(I5,T9,A,T30,A,T47,A,T55,I8)'
 endfor

 textclose,TEXTOUT=textout

 return
 end
