; NAME:
;     DRIP_ANALMAN__DEFINE - Version .7.0
;
; PURPOSE:
;     Analysis Object Manager for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANALMAN', BASEID)
;
; INPUTS:
;     BASEID - Widget ID of base to put widgets
;
; STRUCTURE:
;     TITLE - object title
;     FOCUS - focus status (1 if in focus else 0)
;     DISPOBJ - display object
;     BASEWID - base widget
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     In developement
;
; PROCEDURE:
;     Gets called by display manager
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

;**** create a general analysis object for each display
;** make widgets
common gui_os_dependent_values, largefont, smallfont
label=widget_label(self.topwid, value='Diaplay X Info:', font=largefont)
;** initialize anal_objects
dispn=size(disps,/n_elements)
self.analn=dispn
*self.anals=objarr(dispn)
for i=0,dispn-1 do begin
    title='Display '+string(byte(i)+byte('A'))+' Info:'
    anal=obj_new('drip_anal', disps[i], self, title)
    anal->setwid,label
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
        type:'', $            ; analysis object type
        topwid:0L, $          ; ID of top widget
        analn:0, $            ; number of analysis objects
        anals:ptr_new()}      ; list of analysis objects
end
