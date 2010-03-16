pro fits_close,fcb,no_abort=no_abort,message=message
;+
;
;*NAME:
;	FITS_CLOSE
;
;*PURPOSE:
;	Close a FITS data file
;
;*CATEGORY:
;	INPUT/OUTPUT
;
;*CALLING SEQUENCE:
;	FITS_CLOSE,fcb
;
;*INPUTS:
;	FCB: fits control block returned by FITS_OPEN.
;
;*KEYWORD PARAMETERS:
;       /NO_ABORT: Set to return to calling program instead of a RETALL
;               when an I/O error is encountered.  If set, the routine will
;               return with !err=-1 and a message in the keyword MESSAGE.
;               If not set, FITS_CLOSE will print the message and issue a RETALL
;       MESSAGE = value: Output error message
;	
;*EXAMPLES:
;	Open a FITS file, read some data, and close it with FITS_CLOSE
;
;		FITS_OPEN,'infile',fcb
;		FITS_READ,fcb,data
;		FITS_READ,fcb,moredata
;		FITS_CLOSE,fcb
;
;*HISTORY:
;	Written by:	D. Lindler	August, 1995
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;----------------------------------------------------------------------------
;
; print calling sequence if no parameters supplied
;
	if n_params(0) lt 1 then begin
		print,'CALLING SEQUENCE: fits_close,fcb
		print,'KEYWORD PARAMETERS: no_abort, message'
		retall
	end
;
; close unit
;
	on_ioerror,ioerror
	free_lun,fcb.unit
	!err = 1
	return
;
; error exit (probably should never occur)
;
ioerror:
        message = !err_string
        !err = -1
        if keyword_set(no_abort) then return
        print,'FITS_CLOSE ERROR: '+message
        retall
end
