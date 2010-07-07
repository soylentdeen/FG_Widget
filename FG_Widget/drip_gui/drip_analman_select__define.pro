; NAME:
;     DRIP_ANALMAN_SELECT__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Analysis Object Manager for ANAL_SELECT objects.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_ANALMAN_SELECT inherits DRIP_ANALMAN
;     CW_DRIP_DISP: ANALMAN_SELECT registers new ANALOBJs with the DISP
;     DRIP_ANAL_SELECT: ANALMAN_SELECT creates, destroys and assigns
;                       widgets to ANAL_SCALE_OBJs
;
; PROCEDURE:
;     Upon ANALMAN_SELECT::START this manager creates one
;     ANAL_SELECT_OBJ for each DISP.
;
; RESTRICTIONS:
;     In developement
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, November 2007

;******************************************************************************
;     START - starts analysis object manager
;******************************************************************************

pro drip_analman_select::start, disps, dataman

; make widgets for object
common gui_os_dependent_values, largefont, smallfont
label=widget_label(self.topwid, value='Pipe Step:', font=largefont)
button_tv=widget_button(self.topwid, value='ATV' )
drop_dap=widget_droplist(self.topwid, $
                         value=['  No DAta Product  '] )
drop_elem=widget_droplist(self.topwid, $
                          value=['  No DAP Element  '] )
drop_frame=widget_droplist(self.topwid, value=['   0'] )

; create a general analysis object for each display
dispn=size(disps,/n_elements)
self.analn=dispn
*self.anals=objarr(dispn)
; loop through all displays
for i=0,dispn-1 do begin
    ; create the object and set it up
    anal=obj_new('drip_anal_select', disps[i], self, $
                 dataman, 'Pipe Step:')
    anal->setwid, label, drop_dap, drop_elem, drop_frame, button_tv
    ; register the analobj with the display and store it locally
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
