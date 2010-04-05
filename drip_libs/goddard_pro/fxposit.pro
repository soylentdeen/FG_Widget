        FUNCTION FXPOSIT, XFILE, EXT_NO, readonly=readonly
;+
; NAME:
;     FXPOSIT
; PURPOSE:
;     Return the unit number of a FITS file positioned at specified extension
; EXPLANATION:
;     The FITS file will be ready to be read at the beginning of the 
;     specified extension.
;
; CALLING SEQUENCE:
;     unit=FXPOSIT(FILE, EXT_NO, /READONLY)
;
; INPUT PARAMETERS:
;     FILE    = FITS file name, scalar string
;     EXT_NO  = Extension to be moved to, scalar nonnegative integer
;
; RETURNS:
;     Unit number of file or -1 if an error is detected.
;
; OPTIONAL KEYWORD PARAMETER:
;     /READONLY - If this keyword is set and non-zero, then OPENR rather 
;               than OPENU will be used to open the FITS file.
;
; COMMON BLOCKS:
;      None.
; SIDE EFFECTS:
;      Opens and returns the descriptor of a file.
; PROCEDURE:
;      Each FITS header is read in and parsed, and the file pointer is moved
;      to where the next FITS extension header until the desired
;      extension is reached.
; PROCEDURE CALLS:
;      FXPAR(), MRD_HREAD, MRD_SKIP
; MODIFICATION HISTORY:
;      Derived from William Thompson's FXFINDEND routine.
;      Modified by T.McGlynn, 5-October-1994.
;       Modified by T.McGlynn, 25-Feb-1995 to handle compressed
;          files.  Pipes cannot be accessed using FXHREAD so
;          MRD_HREAD was written.
;       W. Landsman 23-Apr-1997    Force the /bin/sh shell when uncompressing 
;       W. Landsman 26-May-1997    Non-unix is not just VMS
;       T. McGlynn  22-Apr-1999    Add /binary modifier needed for Windows
;       T. McGlynn  03-June-1999   Use /noshell option to get rid of processes left by spawn.
;                                  Use findfile to retain ability to use wildcards
;       W. Landsman 03-Aug-1999    Use EXPAND_TILDE under Unix to find file
;-
;
        ON_ERROR,2
;
;  Check the number of parameters.
;
        IF N_PARAMS() LT 2 THEN BEGIN 
            print,'Syntax:  unit = FXPOSIT(file, EXT_NO)'
            return,-1
        ENDIF

; Expand wildcards in name.    Compensate that FINDFILE doesn't recognize
; the meaning of the Unix tilde.

         if !VERSION.OS_FAMILY EQ 'unix' then $
                if strpos(xfile,'~') NE -1 then xfile = EXPAND_TILDE(xfile)
        file = findfile(xfile, count=count)
        if count eq 0 then begin
            return, -1   ; Don't print anything out, just report an error
        endif
        
        file = file[0]
;
;  Check if this is a compressed file.
;
        unit = -1
        
        len = strlen(file)
        if len gt 3 then tail = strmid(file, len-3, 3) else tail = ' '
        ucmprs = ' '
        if strmid(tail,1,2) eq '.Z' or strmid(tail,1,2) eq '.z' then  $
                           ucmprs = 'uncompress'
        if tail eq '.gz'  or tail eq '.GZ' then ucmprs = 'gunzip'
                
;  Handle compressed files.

        if ucmprs ne ' ' then begin
                if (!version.os ne 'vms') and (!version.os ne 'windows') and $
                   (!version.os ne 'MacOS') then begin
                        spawn, [ucmprs,'-c',file], unit=unit, /noshell
                endif else begin
                        print, 'MRDFITS: Only Unix IDL supports piped spawns'
                        print, '         File must be uncompressed manually'
                        return, -1                      
                endelse
                
        endif else begin
;
;  Go to the start of the file.
;
                if keyword_set(readonly) then begin
                        openr, unit, file, /get_lun, /block, /binary, ERROR = error
                endif else begin
                        openu, unit, file, /get_lun, /block, /binary, ERROR = error
                endelse
                if ERROR NE 0 then begin
                        print,!ERR_STRING
                        return,-1
                endif
                if ext_no le 0 then return, unit
        endelse
        
        for ext = 0, ext_no-1 do begin
               
;
;  Read the next header, and get the number of bytes taken up by the data.
;
                IF EOF(UNIT) THEN BEGIN
                        return, unit
                ENDIF

                ; Can't use FXHREAD to read from pipe, since it uses
                ; POINT_LUN.  So we read this in ourselves using mrd_hread

                mrd_hread, unit, header, status
                
                if status lt 0 then return, -1
                        
                ; Get parameters that determine size of data
                ; region.
                
                BITPIX = FXPAR(HEADER,'BITPIX')
                NAXIS  = FXPAR(HEADER,'NAXIS')
                GCOUNT = FXPAR(HEADER,'GCOUNT') 
                IF GCOUNT EQ 0 THEN GCOUNT = 1
                PCOUNT = FXPAR(HEADER,'PCOUNT')
                
                IF NAXIS GT 0 THEN BEGIN 
                        DIMS = FXPAR(HEADER,'NAXIS*')           ;Read dimensions
                        NDATA = DIMS[0]
                        IF NAXIS GT 1 THEN FOR I=2,NAXIS DO NDATA = NDATA*DIMS[I-1]
                        
                ENDIF ELSE NDATA = 0
                
                NBYTES = (ABS(BITPIX) / 8) * GCOUNT * (PCOUNT + NDATA)
;
;  Move to the next extension header in the file.
;
                NREC = LONG((NBYTES + 2879) / 2880)
                
                mrd_skip, unit, nrec*2880L

        endfor
        
        return, unit
        
        END

