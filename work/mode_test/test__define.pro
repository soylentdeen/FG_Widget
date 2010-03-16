; NAME:
;     TEST - Version .6.1
;
; PURPOSE:
;     Data Reduction Pipeline for test mode
;
; CALLING SEQUENCE:
;     Obj=Obj_new('CM', FILELIST)
;     Structure=Obj->RUN(FILELIST)
;
; INPUTS:
;     FILELIST - Filename(s) of the fits file(s) containing data to be reduced.
;                May be a string array
;
; STRUCTURE:
;     (see drip__define)
;
; CALLED ROUTINES:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;     various components need to be developed. Data file must specify locations
;     of bad pixel map and flat fields.
;
; PROCEDURE:
;     run the individual pipeline procedures.
;
; MODIFICATION HISTORY:
;     Written by: Marc Berthoud, Palomar, June 2005
;                 Copied form cm__define
;

;******************************************************************************
;     REDUCE - Fills SELF structure pointer heap variables with proper values.
;******************************************************************************

pro test::reduce

; clean
*self.cleaned=drip_clean(*self.data,*self.badmap)
; flat
*self.flatted=drip_flat(*self.cleaned,*self.masterflat)
; nonlin
; stack
if size(*self.flatted, /n_dimen) eq 3 then $
  *self.stacked=drip_stack(*self.flatted,*self.header, posdata=*self.posdata, $
                           chopsub=*self.chopsub, nodsub=*self.nodsub) $
else *self.stacked=*self.flatted
; undistort
*self.undistorted=drip_undistort(*self.stacked,*self.header,*self.basehead)
; merge
*self.merged=drip_merge(*self.undistorted,*self.header)
; coadd
if self.n gt 0 then begin
    *self.coadded=drip_coadd(*self.undistorted,*self.coadded, $
                             *self.header, *self.basehead, n=self.n)
endif else begin
    *self.coadded=drip_coadd(*self.undistorted,*self.coadded, $
                             *self.header, *self.basehead, /first, n=self.n)
endelse
; create README
self.readme=['pipeline: Test Mode', $ ;info lines
  'file: ' + self.filename, $
  'final image: undistorted', $
  'order: CLEAN, FLAT, STACK, UNDISTORT, MERGE, COADD', $
  'notes: badmap from CLEAN, masterflat from FLAT']

print,'TEST FINISHED' ;info
end

;******************************************************************************
;     TEST__DEFINE - Define the TEST class structure.
;******************************************************************************

pro test__define  ;structure definition

struct={test, $
      inherits drip} ; child object of drip object
end
