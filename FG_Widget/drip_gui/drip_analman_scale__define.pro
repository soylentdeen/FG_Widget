; NAME:
;     DRIP_ANALMAN_SCALE__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Analysis Object Manager for ANAL_SCALE objects.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_ANALMAN_SCALE inherits DRIP_ANALMAN
;     CW_DRIP_DISP: ANALMAN_SCALE registers new ANALOBJs with the DISP
;     DRIP_ANAL_SCALE: ANALMAN_SCALE creates, destroys and assigns
;                       widgets to ANAL_SCALE_OBJs
;
; PROCEDURE:
;     Upon ANALMAN_SCALE::START this manager creates one
;     ANAL_SCALE_OBJ for each DISP.
;
; RESTRICTIONS:
;     In developement
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, November 2007

;******************************************************************************
;     START - starts analysis object manager
;******************************************************************************

pro drip_analman_scale::start, disps, dataman

;** make widgets for object
common gui_os_dependent_values, largefont, smallfont, mediumfont
; header
headwid=widget_base(self.topwid, /column, /align_top)
label=widget_label(headwid, value='Scale:', font=largefont, /align_left)
setbase=widget_base(headwid, /row)
colorwid=cw_color_sel(setbase, [0b,0b,0b], label='Color:' )
topbase=widget_base(setbase, /row,/align_center)
toplabel=widget_label(topbase, value='Top')
topwid=widget_button(topbase, value='X' )

; base
rightbase=widget_base(self.topwid,/column)

; Radio-Button base
radiobase=widget_base(rightbase,/row,/Exclusive,/align_center)
minmaxbutton=widget_button(radiobase,value='Min-Max', font=mediumfont)
nsigmabutton=widget_button(radiobase,value='N-Sigma', font=mediumfont)
percenbutton=widget_button(radiobase,value='Percent', font=mediumfont)
widget_control,minmaxbutton,set_button=1

; initialize anal_objects
dispn=size(disps,/n_elements)
self.analn=dispn
*self.anals=objarr(dispn)
for i=0,dispn-1 do begin
    wid=disps[i]->getdata(/wid)
    anal=obj_new('drip_anal_scale', disps[i], self, $
                    'Scale:', wid)
    anal->setwid, label, colorwid, topwid,$
                  minmaxbutton, nsigmabutton, percenbutton, rightbase
    disps[i]->openanal, anal
    (*self.anals)[i]=anal
endfor

end

;****************************************************************************
;     INIT - to create analysis object manager
;****************************************************************************

function drip_analman_scale::init, baseid

; set initial variables
self.type='scale'
self.topwid=widget_base(baseid, /row, /frame, $
                        event_pro='drip_anal_eventhand' )
self.analn=0
self.anals=ptr_new(/allocate_heap)
return, 1

end

;****************************************************************************
;     DRIP_ANAL_SCALE__DEFINE
;****************************************************************************

pro drip_analman_scale__define

struct={drip_analman_scale, $
        inherits drip_analman}   ; child object of drip_analman

end
