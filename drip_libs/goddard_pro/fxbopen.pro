	PRO FXBOPEN, UNIT, FILENAME, EXTENSION, HEADER, NO_TDIM=NO_TDIM, $
		ERRMSG=ERRMSG
;+
; Project     : SOHO - CDS
;
; Name        : 
;	FXBOPEN
; Purpose     : 
;	Open binary table extension in a disk FITS file for reading.
; Explanation : 
;	Opens a binary table extension in a disk FITS file for reading.  The
;	columns are then read using FXBREAD, and the file is closed when done
;	with FXBCLOSE.
; Use         : 
;	FXBOPEN, UNIT, FILENAME, EXTENSION  [, HEADER ]
; Inputs      : 
;	FILENAME  = Name of FITS file to be opened.
;	EXTENSION = Either the number of the FITS extension, starting with the
;		    first extension after the primary data unit being one; or a
;		    character string containing the value of EXTNAME to search
;		    for.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	UNIT	  = Logical unit number of the opened file.
; Opt. Outputs: 
;	HEADER	  = String array containing the FITS binary table extension
;		    header.
; Keywords    : 
;	NO_TDIM	  = If set, then any TDIMn keywords found in the header are
;		    ignored.
;
;	ERRMSG	  = If defined and passed, then any error messages will be
;		    returned to the user in this parameter rather than
;		    depending on the MESSAGE routine in IDL.  If no errors are
;		    encountered, then a null string is returned.  In order to
;		    use this feature, ERRMSG must be defined first, e.g.
;
;			ERRMSG = ''
;			FXBOPEN, ERRMSG=ERRMSG, ...
;			IF ERRMSG NE '' THEN ...
;
; Calls       : 
;	FXBFINDLUN, FXBPARSE, FXHREAD, FXPAR
; Common      : 
;	Uses common block FXBINTABLE--see "fxbintable.pro" for more
;	information.
; Restrictions: 
;	The file must be a valid FITS file.
; Side effects: 
;	None.
; Category    : 
;	Data Handling, I/O, FITS, Generic.
; Prev. Hist. : 
;	W. Thompson, Feb 1992, based on READFITS by J. Woffard and W. Landsman.
;	W. Thompson, Feb 1992, changed from function to procedure.
;	W. Thompson, June 1992, fixed up error handling.
; Written     : 
;	William Thompson, GSFC, February 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 27 May 1994
;		Added ERRMSG keyword.
;	Version 3, William Thompson, GSFC, 21 June 1994
;		Extended ERRMSG to call to FXBPARSE
;       Version 4, William Thompson, GSFC, 23 June 1994
;               Modified so that ERRMSG is not touched if not defined.
; Version     :
;       Version 4, 23 June 1994
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;
@fxbintable
	ON_ERROR, 2
;
;  Check the number of parameters.
;
	IF N_PARAMS() LT 3 THEN BEGIN
		MESSAGE = 'Syntax:  FXBOPEN, UNIT, FILENAME, EXTENSION  ' + $
			'[, HEADER ]'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
;
;  Check the type of the EXTENSION parameter.
;
	IF N_ELEMENTS(EXTENSION) NE 1 THEN BEGIN
		MESSAGE = 'EXTENSION must be a scalar'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
	SZ = SIZE(EXTENSION)
	ETYPE = SZ[SZ[0]+1]
	IF ETYPE EQ 8 THEN BEGIN
		MESSAGE = 'EXTENSION must not be a structure'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
;
;  If EXTENSION is of type string, then search for the proper extension by
;  name.  Otherwise, search by number.
;
	IF ETYPE EQ 7 THEN BEGIN
		S_EXTENSION = STRTRIM(STRUPCASE(EXTENSION),2)
	END ELSE BEGIN
		I_EXTENSION = FIX(EXTENSION)
		IF I_EXTENSION LT 1 THEN BEGIN
			MESSAGE = 'EXTENSION must be greater than zero'
			IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
				ERRMSG = MESSAGE
				RETURN
			END ELSE MESSAGE, MESSAGE
		ENDIF
	ENDELSE
;
;  Get a logical unit number, and open the file.
;
	ON_IOERROR, NO_SUCH_FILE
       	OPENR, UNIT, FILENAME, /BLOCK, /GET_LUN
	ON_IOERROR, NULL
;
;  Store the UNIT number in the common block, and leave space for the other
;  parameters.  Initialize the common block if need be.  ILUN is an index into
;  the arrays.
;
	ILUN = FXBFINDLUN(UNIT)
;
;  Mark the file as open for read.
;
	STATE[ILUN] = 1
;
;  Read the primary header.
;
	FXHREAD,UNIT,HEADER,STATUS
	IF STATUS NE 0 THEN BEGIN
		FREE_LUN,UNIT
		MESSAGE = 'Unable to read primary FITS header'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
	I_EXT = 0
;
;  Make sure that the file does contain extensions.
;
	IF NOT FXPAR(HEADER,'EXTEND') THEN BEGIN
		FREE_LUN, UNIT
		MESSAGE = 'File ' + FILENAME + ' does not contain extensions'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
;
;  Get the number of bytes taken up by the data.
;
NEXT_EXT:
	BITPIX = FXPAR(HEADER,'BITPIX')
	NAXIS  = FXPAR(HEADER,'NAXIS')
	GCOUNT = FXPAR(HEADER,'GCOUNT')  &  IF GCOUNT EQ 0 THEN GCOUNT = 1
	PCOUNT = FXPAR(HEADER,'PCOUNT')
	IF NAXIS GT 0 THEN BEGIN 
		DIMS = FXPAR(HEADER,'NAXIS*')		;Read dimensions
		NDATA = DIMS[0]
		IF NAXIS GT 1 THEN FOR I=2,NAXIS DO NDATA = NDATA*DIMS[I-1]
	ENDIF ELSE NDATA = 0
	NBYTES = (ABS(BITPIX) / 8) * GCOUNT * (PCOUNT + NDATA)
;
;  Read the next extension header in the file.
;
	NREC = LONG((NBYTES + 2879) / 2880)
	POINT_LUN, -UNIT, POINTLUN			;Current position
	MHEAD0 = POINTLUN + NREC*2880L
	POINT_LUN, UNIT, MHEAD0				;Next FITS extension
	FXHREAD,UNIT,HEADER,STATUS
	IF STATUS NE 0 THEN BEGIN
		FREE_LUN,UNIT
		MESSAGE = 'Requested extension not found'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
	I_EXT = I_EXT + 1
;
;  Check to see if the current extension is the one desired.
;
	IF ETYPE EQ 7 THEN BEGIN
		EXTNAME = STRTRIM(STRUPCASE(FXPAR(HEADER,'EXTNAME')),2)
		IF EXTNAME EQ S_EXTENSION THEN GOTO, DONE
	END ELSE IF I_EXT EQ I_EXTENSION THEN GOTO, DONE
	GOTO, NEXT_EXT
;
;  Check to see if the extension type is BINTABLE or A3DTABLE.
;
DONE:
	XTENSION = STRTRIM(STRUPCASE(FXPAR(HEADER,'XTENSION')),2)
	IF (XTENSION NE 'BINTABLE') AND (XTENSION NE 'A3DTABLE') THEN BEGIN
		IF ETYPE EQ 7 THEN EXT = S_EXTENSION ELSE EXT = I_EXTENSION
		FREE_LUN,UNIT
		MESSAGE = 'Extension ' + STRTRIM(EXT,2) +		$
			' is not a binary table'
		IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
			ERRMSG = MESSAGE
			RETURN
		END ELSE MESSAGE, MESSAGE
	ENDIF
;
;  Get the rest of the information, and store it in the common block.
;
	MHEADER[ILUN] = MHEAD0
	FXBPARSE,ILUN,HEADER,NO_TDIM=NO_TDIM,ERRMSG=ERRMSG
	RETURN
;
;  Error point for not being able to open the file
;
NO_SUCH_FILE:
	MESSAGE = 'Unable to open file ' + STRTRIM(FILENAME,2)
	IF N_ELEMENTS(ERRMSG) NE 0 THEN BEGIN
		ERRMSG = MESSAGE
		RETURN
	END ELSE MESSAGE, MESSAGE
	END
