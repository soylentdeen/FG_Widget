; NAME:
;     DRIP_ANALMAN_SELECT__DEFINE - Version .7.0
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANALMAN_SELECT', BASEID)
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

;******************************************************************************
;     START - starts analysis object manager
;******************************************************************************

pro drip_analman_select::start, disps, dataman

;**** create a general analysis object for each display
;** make widgets
common gui_os_dependent_values, largefont, smallfont
label=widget_label(self.topwid, value='Pipe Step:', font=largefont)
button_tv=widget_button(self.topwid, value='ATV' )
drop_dap=widget_droplist(self.topwid, $
                         value=['  No DAta Product  '] )
drop_elem=widget_droplist(self.topwid, $
                          value=['  No DAP Element  '] )
drop_frame=widget_droplist(self.topwid, value=['   0'] )

;** initialize anal_objects
dispn=size(disps,/n_elements)
self.analn=dispn
*self.anals=objarr(dispn)
for i=0,dispn-1 do begin
    anal=obj_new('drip_anal_select', disps[i], self, $
                 dataman, 'Pipe Step:')
    anal->setwid, label, drop_dap, drop_elem, drop_frame, button_tv
    disps[i]->openanal, anal
    (*self.anals)[i]=anal
endfor

end

;****************************************************************************
;     INIT - to create analysis object manager
;****************************************************************************

function drip_analman_select::init, baseid

; set initial variables
self.type='select'
self.topwid=widget_base(baseid, /row, /frame, /base_align_left, $
                        event_pro='drip_anal_eventhand' )
self.analn=0
self.anals=ptr_new(/allocate_heap)
return, 1

end

;****************************************************************************
;     DRIP_ANAL_SELECT__DEFINE
;****************************************************************************

pro drip_analman_select__define

struct={drip_analman_select, $
        inherits drip_analman}   ; child object of drip_analman

end
