; NAME:
;     CM - Version .6.1
;
; PURPOSE:
;     Data Reduction Pipeline for multi position mode
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
;     Written by:  Alfred Lee, Cornell University, August 1, 2002
;                       Modified from TPC__DEFINE
;     Modified:   Alfred Lee, CU, August 26, 2002
;                 updated for new pipeline architecture.
;     Rewritten: Marc Berthoud, CU, June 2004
;                Changed TPC object into a child object of the new
;                DRIP object (lots of code erased)
;     Modified:  Marc Berthoud, CU, March 2005
;                Renamed to CM
;

;******************************************************************************
;     RUN - Fills SELF structure pointer heap variables with proper values.
;******************************************************************************

pro cm::reduce

; clean
*self.cleaned=drip_clean(*self.data,*self.badmap)
; flat
*self.flatted=drip_flat(*self.cleaned,*self.masterflat)
; nonlin
; stack
*self.stacked=drip_stack(*self.flatted,*self.header, posdata=*self.posdata, $
                         chopsub=*self.chopsub)
; undistort
*self.undistorted=drip_undistort(*self.stacked,*self.header,*self.basehead)
; merge
*self.merged=drip_merge(*self.undistorted,*self.header)
; coadd
if self.n gt 0 then begin
    *self.coadded=drip_coadd(*self.undistorted,*self.coadded, $
                             *self.header, *self.basehead)
endif else begin
    *self.coadded=drip_coadd(*self.undistorted,*self.coadded, $
                             *self.header, *self.basehead, /first)
endelse
; create README
self.readme=['pipeline: Multi Position Chop DRiP', $ ;info lines
  'file: ' + self.filename, $
  'final image: undistorted', $
  'order: CLEAN, FLAT, STACK, UNDISTORT, MERGE, COADD', $
  'notes: badmap from CLEAN, masterflat from FLAT']

print,'CM FINISHED' ;info
end

;******************************************************************************
;     CM__DEFINE - Define the CM class structure.
;******************************************************************************

pro cm__define  ;structure definition

struct={cm, $
      inherits drip} ; child object of drip object
end
