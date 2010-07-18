; NAME:
;     DRIP_ANALMAN__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Analysis Object Manager for the GUI. Each manager is responsible
;     for one kind of analysis objects from all displays.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_DISP: ANALMAN registers new ANALOBJs with the DISP
;     DRIP_ANAL: ANALMAN creates, destroys and assigns widgets to ANALOBJs
;
; PROCEDURE:
;     Upon ANALMAN::START this manager creates one ANALOBJ for each
;     DISP.
;
; RESTRICTIONS:
;     In developement
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, November 2007

;****************************************************************************
;     SETALLWID - set widgets for all analysis objects (only where needed)
;****************************************************************************

pro drip_analman::setallwid

end

;******************************************************************************
;     GETDATA - Return the SELF structure elements
;******************************************************************************
function drip_analman::getdata, type=ty, analn=an, anals=as

if keyword_set(ty) then return, self.type
if keyword_set(an) then return, self.analn
if keyword_set(as) then return, *self.anals

end

;******************************************************************************
;     START - starts analysis object manager
;******************************************************************************

pro drip_analman::start, disps

; make widgets for object
common gui_os_dependent_values, largefont, smallfont
label=widget_label(self.topwid, value='Diaplay X Info:', font=largefont)
; create a general analysis object for each display
dispn=size(disps,/n_elements)
self.analn=dispn
*self.anals=objarr(dispn)
; loop through all displays
for i=0,dispn-1 do begin
    ; make the title (i.e. Display X Info:)
    title='Display '+string(byte(i)+byte('A'))+' Info:'
    ; create object and set it up
    anal=obj_new('drip_anal', disps[i], self, title)
    anal->setwid,label
    ; register the analobj with the display and store it locally
    disps[i]->openanal, anal
    (*self.anals)[i]=anal
endfor
end

;****************************************************************************
;     CLEANUP - to destroy analysis object manager
;****************************************************************************

pro drip_analman::cleanup

; destroy analysis objects and free memory
obj_destroy, *self.anals
ptr_free, self.anals

end

;****************************************************************************
;     INIT - to create analysis object manager
;****************************************************************************

function drip_analman::init, baseid

; set initial variables
self.type='label'
self.topwid=widget_base(baseid,/column,/frame)
self.analn=0
self.anals=ptr_new(/allocate_heap)
return, 1

end

;****************************************************************************
;     DRIP_ANALMAN__DEFINE
;****************************************************************************

pro drip_analman__define

struct={drip_analman, $
        type:'', $            ; analysis object type (string)
        topwid:0L, $          ; ID of top widget
        analn:0, $            ; number of analysis objects
        anals:ptr_new()}      ; list of analysis objects
end
