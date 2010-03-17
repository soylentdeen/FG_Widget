; NAME:
;     C2N - Version .7.0
;
; PURPOSE:
;     Data Reduction Pipeline for two position chop two position nod mode
;
; CALLING SEQUENCE:
;     Obj=Obj_new('C2N', FILELIST)
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
;     Written by:  Alfred Lee, Cornell University, 2001
;     Modified:   Alfred Lee, Cornell University, April, 2002
;                   Changed name to C2NON.  Adjusted drip to run without
;                   non-working components.  created RET input to allow
;                   quick viewing of results.  Switched to GET_DATA to
;                   read files to provide easier calling.
;     Modified:   Alfred Lee, CU, June 6, 2002
;                   Changed into an Object.  C2NON will now be
;                   called automatically from DRIP.
;     Modified:   Alfred Lee, CU June 18, 2002
;                   Data now saved as a structure, and is compressed
;                   by default. fixed other bugs and added two
;                   optional keywords
;     Modified:   Alfred Lee, CU June 21, 2002
;                   C2NON and C2NOFF are now simply, C2N.  takes a new CHOPPING
;                   parameter to determine whether the chop is on or off chip.
;                   MAKE_IMAGE is called accordingly.
;     Modified:   Alfred Lee, CU June 24, 2002
;                   Created RUN method to run the code as needed after a single
;                   initialization.
;     Modified:   Alfred Lee, CU, June 26, 2002
;                   put readme in class structure definition, and
;                   added information about the file and final image.
;                   Modified SAVE method to run from an external call,
;                   namely from DRIP. SAVE no longer compresses by
;                   default. Updated parameters and keywords to match
;                    changes in code.
;     Modified:   Alfred Lee, CU, July 18, 2002
;                   Enhanced error checking.
;     Modified:   Alfred Lee, CU, August 1, 2002
;                   Redesigned the pipeline architecture for better
;                   organization and DCAO compatibility.
;     Modified:   Alfred Lee, CU, September 27, 2002
;                   added _extra keyword to c2n::run
;     Modified:   Alfred Lee, CU, November 19, 2002
;                   returns correct structure
;     Rewritten: Marc Berthoud, CU, June 2004
;                Changed C2N object into a child object of the new
;                DRIP object (lots of code erased)
;     Modified:  Marc Berthoud, CU, March 2005
;                Renamed to C2N               
;     Modified   Luke Keller, IC, January 2010
;                Added non-linearity correction
;

;******************************************************************************
;     RUN - Fills SELF structure pointer heap variables with proper values.
;******************************************************************************

pro c2n::reduce

; clean
*self.cleaned=drip_clean(*self.data,*self.badmap)
; nonlin
*self.linearized=drip_nonlin(*self.cleaned,*self.lincor)   ;LIN
; flat
*self.flatted=drip_flat(*self.linearized,*self.masterflat,*self.darksum)
; stack
*self.stacked=drip_stack(*self.flatted,*self.header,posdata=*self.posdata, $
                         chopsub=*self.chopsub, nodsub=*self.nodsub)
; undistort
*self.undistorted=drip_undistort(*self.stacked,*self.header,*self.basehead)
; merge
*self.merged=drip_merge(*self.undistorted,*self.header)
; coadd
if self.n gt 0 then begin
    *self.coadded=drip_coadd(*self.merged,*self.coadded, $
                             *self.header, *self.basehead)
endif else begin
    *self.coadded=drip_coadd(*self.merged,*self.coadded, $
                             *self.header, *self.basehead, /first)
endelse
; create README
;o=(mode eq 1) ? 'on' : 'off'
o=''
self.readme=['pipeline: 2 Position Chop ' + o + ' chip DRiP', $ ;info lines
  'file: ' + self.filename, $
  'final image: undistorted', $
  'order: CLEAN, NONLIN, FLAT, STACK, UNDISTORT, MERGE, COADD', $
  'notes: badmap from CLEAN, masterflat from FLAT']

print,'C2N ' + o + ' chip FINISHED' ;info
end

;******************************************************************************
;     C2N__DEFINE - Define the C2N class structure.
;******************************************************************************

pro c2n__define  ;structure definition

struct={c2n, $
      inherits drip} ; child object of drip object
end
