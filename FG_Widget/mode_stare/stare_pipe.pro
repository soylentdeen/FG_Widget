; NAME:
;     STARE_PIPE - Version .7.0
;
; PURPOSE:
;     Automatic Data Reduction Pipeline for STARE
;
; CALLING SEQUENCE:
;     STARE_PIPE, INMANIFEST, OUTMANIFEST
;
; INPUTS:
;     INMANIFEST - Name of the file containing the names of the files to
;                  be reduced
;     OUTMANIFEST - Name of file that contains output file name
;
; OUTPUTS:
;     FITS output: final coadded result or individual step results
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_NEW
;     DRIP::PIPE
;     DRIP::RUN
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     None
;
; PROCEDURE:
;     Read filenames, create a pipeline, feed it the filenames, save
;     the result
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, March, 2005

pro stare_pipe, inmanifest, outmanifest

;** error check
s=size(inmanifest)
if (s[0] ne 0) and (s[1] ne 7) then $
  message, 'stare_pipe - must provide input manifest file name'
s=size(outmanifest)
if (s[0] ne 0) and (s[1] ne 7) then $
  message, 'stare_pipe - must provide output manifest file name'
;** get file names
; open file
openr, fileunit, inmanifest, /get_lun, error=err
if err ne 0 then $
  message, 'stare_pipe - error opening input manifest file - error msg=' $
    + !error_state.msg
; get number
n=0
readf, fileunit, n
; get names
filelist=strarr(n)
s=''
for i=0,n-1 do begin
    readf, fileunit, s
    filelist[i]=s
endfor
; close file
close, fileunit
; check for invalid (empty) names - if found - exit
for i=0,n-1 do if strlen(filelist[i]) eq 0 then $
  message, 'stare_pipe - invalid entries in input manifest file - aborting'
;** open and run pipe
; open
pipe=drip_new(filelist)
; check for valid mode
if strtrim(pipe->getdata(/mode),2) ne 'STARE' then $
  message, 'stare_pipe - wrong instrument mode (should be STARE)'
; run data reduction
pipe->run,filelist
;** save data
pipe->save
;** write output maifest
; make filename
filename=pipe->getdata(/filename)
namepos=strpos(filename, '.fit',/reverse_search)
fname=strmid(filename, 0, namepos)+'_reduced.fits'
; write manifest
openw, fileunit, outmanifest, /get_lun, error=err
if err ne 0 then $
  message, 'stare_pipe - error opening output manifest file - error msg=' $
    + !error_state.msg
printf, fileunit, '1'
printf, fileunit, fname
close, fileunit

end
