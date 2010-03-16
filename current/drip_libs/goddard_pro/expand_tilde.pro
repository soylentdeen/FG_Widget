;+
; NAME:
;	 EXPAND_TILDE()
;               
; PURPOSE: 
;	Expand tilde in UNIX directory names
;               
; CALLING SEQUENCE: 
;	IDL> output=expand_tilde(input)
;    
; INPUTS: 
;	INPUT = input file or directory name, scalar string
;
; OUTPUT:
;	Returns expanded filename, scalar string
;               
; EXAMPLES: 
;	output=expand_tilde('~zarro/test.doc')
;               ---> output='/usr/users/zarro'
;
; PROCEDURE CALLS:
;	DATATYPE()
; REVISION HISTORY: 
;	Version 1,  17-Feb-1997,  D M Zarro.  Written
;	Transfered from Solar Library   W. Landsman   Sep. 1997
;-            

function expand_tilde,name
if N_elements(name) EQ 0 then return,''
if datatype(name) ne 'STR' then return,name
tpos=strpos(name,'~')
if tpos eq -1 then return,name
spos=strpos(name,'/')
if spos eq -1 then begin
 dir=name
 rest=''
endif else begin
 dir=strmid(name,0,spos)
 rest=strmid(name,spos+1,strlen(name))
endelse
cd,dir,curr=curr
cd,curr,curr=dcurr
if rest ne '' then tname=dcurr+'/'+rest else tname=dcurr
return,tname & end
