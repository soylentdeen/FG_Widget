pro mrd_skip, unit, nskip
;+
; NAME:
;       MRD_SKIP
; PURPOSE:
;       Skip a number of bytes from the current location in a file or a pipe
; EXPLANATION:
;       First tries using POINT_LUN and if this doesn't work, perhaps because
;       the unit is a pipe, MRD_SKIP will just read in the requisite number 
;       of bytes.
; CALLING SEQUENCE:
;       MRD_SKIP, Unit, Nskip
;
; INPUTS:
;       Unit - File unit for the file or pipe in question, integer scalar
;       Nskip - Number of bytes to be skipped, positive integer
; NOTES:
;       This routine should be used in place of POINT_LUN wherever a pipe
;       may be the input unit (see the procedure FXPOSIT for an example).  
;       Note that it assumes that it can only work with nskip >= 0 so it 
;       doesn't even try for negative values.    
;
; REVISION HISTORY:
;       Written, Thomas A. McGlynn    July 1995
;	Don't even try to skip bytes on a pipe with POINT_LUN, since this
;	might reset the current pointer     W. Landsman        April 1996
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
        On_error,2

	if nskip le 0 then return

; If you can read the current position, then it is not a pipe and we can 
; go ahead and use POINT_LUN

	on_ioerror, byte_read
	point_lun, -unit, curr_pos
	on_ioerror, null
	if curr_pos NE -1 then begin             
		point_lun, unit, curr_pos+nskip
		return
        endif 

; Otherwise, we have to explictly read the number of bytes to skip

; If the number is very large we don't want to create a array so skip
; in chunks of 1 Megabyte
byte_read:
	on_ioerror, null
	buf = bytarr(nskip<1000000L, /nozero)
	nleft = nskip
	while (nleft gt 0) do begin
		readu, unit, buf
		nleft = nleft - 1000000L
	        if (nleft gt 0 and nleft lt 1000000L) then begin
		    buf = buf[0:nleft-1]
		endif
	endwhile
		
	return
end

