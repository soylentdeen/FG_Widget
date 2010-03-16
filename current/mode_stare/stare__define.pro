; NAME:
;     STARE - Version .6.1
;
; PURPOSE:
;     Data Reduction Pipeline for stare mode
;
; CALLING SEQUENCE:
;     Obj=Obj_new('STARE', FILELIST)
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
;     of bad pixel map and flat fields. (Both can be files that are
;     filled with 0's)
;
; PROCEDURE:
;     run the individual pipeline procedures.
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, October 2003
;                       Mostly Copied from TPC_DEFINE
;     Rewritten: Marc Berthoud, Cornell University, March 2005
;                     Mostly copied from tpc__define (the new one)
;     Modified:  Marc Berthoud, CU, March 2005
;                Renamed to STARE
;     Modified:  Marc Berthoud, Palomar, June 2005
;                use lastcoadded to store first frame, which is background
;                -> coadded is always last image - background (first image)
;

;******************************************************************************
;     RUN - Fills SELF structure pointer heap variables with proper values.
;******************************************************************************

pro stare::reduce

; clean
*self.cleaned=drip_clean(*self.data,*self.badmap)
;cleansum=total(*self.cleaned,3)
;darksum=total(*self.cleaneddarks,3)
;undarked=cleansum-darksum

*self.cleaned=*self.cleaned-*self.masterflat
; flat
*self.flatted=drip_flat(*self.cleaned,*self.masterflat,*self.darksum)
;*self.flatted=undarked/*self.masterflat

; nonlin
; stack
if size(*self.flatted, /n_dimen) eq 3 then $
  *self.stacked=drip_stack(*self.flatted,*self.header) $
else *self.stacked=*self.flatted
; undistort
*self.undistorted=*self.stacked
; merge
*self.merged=*self.undistorted
; coadd
if self.n gt 0 then begin
    *self.coadded=drip_coadd(*self.undistorted,*self.coadded, $
                             *self.header, *self.basehead)
endif else begin
    *self.coadded=drip_coadd(*self.undistorted,*self.coadded, $
                             *self.header, *self.basehead, /first)
endelse
; create README
;o=(mode eq 1) ? 'on' : 'off'
o=''
self.readme=['pipeline: Stare Mode ' + o + ' chip DRiP', $ ;info lines
  'file: ' + self.filename, $
  'final image: undistorted', $
  'order: CLEAN, FLAT, STACK, COADD', $
  'notes: badmap from CLEAN, masterflat from FLAT']

print,'Stare Mode FINISHED',self.n ;info
end

;******************************************************************************
;     STARE__DEFINE - Define the STARE class structure.
;******************************************************************************

pro stare__define  ;structure definition

struct={stare, $
      inherits drip} ; child object of drip object
end