; NAME:
;     DRIP_ANALMAN_SCALE__DEFINE - Version .7.0
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANALMAN_SCALE', BASEID)
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

pro drip_analman_scale::start, disps, dataman

;**** create a general analysis object for each display
;** make widgets
common gui_os_dependent_values, largefont, smallfont, mediumfont
; header
headwid=widget_base(self.topwid, /column, /align_top)
label=widget_label(headwid, value='Scale:', font=largefont, /align_left)
setbase=widget_base(headwid, /column)
colorwid=cw_color_sel(setbase, [0b,0b,0b], label='Color:' )
topbase=widget_base(setbase, /row,/align_center)
toplabel=widget_label(topbase, value='Top')
topwid=widget_button(topbase, value='X' )

;base
rightbase=widget_base(self.topwid,/column)

;Radio-Button base
radiobase=widget_base(rightbase,/row,/Exclusive,/align_center)
minmaxbutton=widget_button(radiobase,value='Min-Max', font=mediumfont)
nsigmabutton=widget_button(radiobase,value='N-Sigma', font=mediumfont)
percenbutton=widget_button(radiobase,value='Percent', font=mediumfont)
widget_control,minmaxbutton,set_button=1

;Min-Max Scaling
minmaxbase=widget_base(rightbase,/row)
; minbase
minbase=widget_base(minmaxbase, /row )
; min values
minfield=widget_base(minbase, /row )
mintext=cw_field(minfield, title='Min :', /floating, /return_events,$
                 xsize=5,ysize=3 )
automin=widget_base(minfield, /column, /nonexclusive)
minautoset=widget_button(automin, value='Auto ' )

; maxbase
maxbase=widget_base(minmaxbase, /row )

; max values
maxfield=widget_base(maxbase, /row)
maxtext=cw_field(maxfield, title='Max :', /floating, /return_events,$
                 xsize=5,ysize=3 )
automax=widget_base(maxfield, /column, /nonexclusive)
maxautoset=widget_button(automax, value='Auto' )

;** initialize anal_objects
dispn=size(disps,/n_elements)
self.analn=dispn
*self.anals=objarr(dispn)
for i=0,dispn-1 do begin
    wid=disps[i]->getdata(/wid)
    anal=obj_new('drip_anal_scale', disps[i], self, $
                    'Scale:', wid)
    anal->setwid, label, colorwid, topwid,$
      minmaxbase,  mintext, minautoset, $
      maxtext, maxautoset, minmaxbutton, $
      nsigmabutton, percenbutton, rightbase
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
