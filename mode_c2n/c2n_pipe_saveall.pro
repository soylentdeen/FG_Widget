; NAME:
;     C2N_PIPE_SAVEALL - Version .6.1
;
; PURPOSE:
;     Automatic Data Reduction Pipeline for C2N, altered version -
;     saves all intermediate steps for last input files
;
; CALLING SEQUENCE:
;     C2N_PIPE_SAVEALL, INMANIFEST, OUTMANIFEST
;
; INPUTS:
;     INMANIFEST - Name of the file containing the names of the files to
;                  be reduced
;     OUTMANIFEST - Name of file that contains output file names
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
;     Written by:  Marc Berthoud, Cornell University, January, 2005
;                  Adapted from c2n_pipe differences:
;                  - saves all intermediate steps for last datafile
;                  - saves filenames in output manifest

pro c2n_pipe_saveall, inmanifest, outmanifest

;** error check
s=size(inmanifest)
if (s[0] ne 0) and (s[1] ne 7) then $
  message, 'c2n_pipe - must provide input manifest file name'
s=size(outmanifest)
if (s[0] ne 0) and (s[1] ne 7) then $
  message, 'c2n_pipe - must provide output manifest file name'
;** get file names
; open file
openr, fileunit, inmanifest, /get_lun, error=err
if err ne 0 then $
  message, 'c2n_pipe - error opening input manifest file - error msg=' $
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
  message, 'c2n_pipe - invalid entries in input manifest file - aborting'
;** open and run pipe
; open
pipe=drip_new(filelist)
; check for valid mode
if strtrim(pipe->getdata(/mode),2) ne 'C2N' then $
  message, 'c2n_pipe - wrong instrument mode (should be C2N)'
; run data reduction
pipe->run,filelist
;** save data
pipe->save,/masterflat
pipe->save,/cleaned
pipe->save,/flatted
pipe->save,/merged
pipe->save,/undistort
pipe->save,/coadded
;** write output maifest
; make basic file name
filename=pipe->getdata(/filename)
namepos=strpos(filename, '.fit',/reverse_search)
fname=strmid(filename, 0, namepos)
; write manifest
openw, fileunit, outmanifest, /get_lun, error=err
if err ne 0 then $
  message, 'c2n_pipe - error opening output manifest file - error msg=' $
    + !error_state.msg
printf, fileunit, '1'
printf, fileunit, fname+'_masterflat.fits'
printf, fileunit, fname+'_cleaned.fits'
printf, fileunit, fname+'_flatted.fits'
printf, fileunit, fname+'_merged.fits'
printf, fileunit, fname+'_undistorted.fits'
printf, fileunit, fname+'_coadded.fits'

close, fileunit

end
