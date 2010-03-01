; NAME:
;     DRIP_NEW - Version 6.1
;
; PURPOSE:
;     Select and initialize correct drip object
;
; CALLING SEQUENCE:
;     Obj=drip_new(FILELIST)
;
; INPUTS:
;     FILELIST - Filename(s) of the fits file(s) containing data to be reduced.
;                May be a string array
;
; OUTPUTS:
;     IDL output: drip object of correct type
;                 OR null object if 
;                    - object::init fails to return 1
;                    - there is some other failure
;
; CALLED ROUTINES AND OBJECTS:
;     FITS_READ
;     SXPAR
;     DRIP__DEFINE
;
; SIDE EFFECTS:
;     None
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, June, 2004
;     Modified:    Marc Berthoud, Cornell University, November, 2004
;                  Added c3pd and tpcd (modes with dither)
;     Modified:    Marc Berthoud, Cornell University, March, 2005
;                  Changed mode names
;     Modified:    Marc Berthoud, Cornell University, May 2006
;                  Added mode C2
;     Modified:    Marc Berthoud, Cornell University, September 2007
;                  Made null object uniform return on failure
;

;****************************************************************************
;     DRIP_NEW - set data values
;****************************************************************************

function drip_new, filelist

; check validity of filelist
lists=size(filelist)
if lists[1+lists[0]] ne 7 then begin
    drip_message, 'drip_new - must specify file name(s)'
    return, obj_new() ; returns a null object
endif
; get filename
if lists[0] eq 0 then file=filelist else file=filelist[0]
; get base header
fits_read, file, null, header, /header
; get mode
mode=drip_getpar(header,'INSTMODE',/vital)
; if no mode found return 0
if mode eq 'x' then begin
    drip_message,'drip_new - no INSTMODE keyword found - exiting'
    return, obj_new() ; returns a null object
endif
mode=strtrim(mode,2)
drip_message,'new pipe, mode=<'+mode+'>'
case mode of
    'C2': pipe=obj_new('c2',filelist)
    'C2N': pipe=obj_new('c2n',filelist)
    'C2ND': pipe=obj_new('c2nd',filelist)
    'C3D': pipe=obj_new('c3d',filelist)
    'CM': pipe=obj_new('cm',filelist)
    'MAP': pipe=obj_new('map',filelist)
    'STARE': pipe=obj_new('stare',filelist)
    'TEST': pipe=obj_new('test',filelist)
    else: pipe=obj_new('drip',filelist)
endcase
return,pipe
end
