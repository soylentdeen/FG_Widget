; NAME:
;     DRIP_ANAL__DEFINE - Version .7.0
;
; PURPOSE:
;     Analysis Objects for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANAL', MW)
;
; INPUTS:
;     MW - Message manager object reference
;
; STRUCTURE:
;     TITLE - object title
;     FOCUS - focus status (1 if in focus else 0)
;     DISPOBJ - display object
;     BASEWID - base widget
;     MW - message window object reference
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_MW
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     In developement
;
; PROCEDURE:
;     Gets called by displays and analysis object manager
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, October 2003
;     Modified:    Marc Berthoud, Cornell University, March 2004
;                  Use widgets passed through setwid member function

;****************************************************************************
;     RESET - reset the object
;****************************************************************************

pro drip_anal::reset
end

;****************************************************************************
;     UPDATE - updates the displayed data
;****************************************************************************

pro drip_anal::update
end

;****************************************************************************
;     DRAW - draws screen signs
;****************************************************************************

pro drip_anal::draw
end

;****************************************************************************
;     INPUT - reaction to moving screen sign
;****************************************************************************

pro drip_anal::input, event
end

;****************************************************************************
;     MOVE - reaction to moving screen sign
;****************************************************************************

function drip_anal::move, x0, y0, x1, y1, final=fin
return, 0
end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal::setwid, label
self.labelwid=label
end

;****************************************************************************
;     SETTOP - to set widget on top
;****************************************************************************

pro drip_anal::settop, top
self.top=top
end

;****************************************************************************
;     ISTOP - to querry if widget is on top
;****************************************************************************

function drip_anal::istop
return, self.top
end

;****************************************************************************
;     SETFOCUS - puts object in and out of focus
;****************************************************************************

pro drip_anal::setfocus, focus
if self.focus ne focus then begin
    self.focus=focus
    if focus eq 1 then begin
        ; set label text
        widget_control, self.labelwid, set_value=self.title
    endif
endif
end

;****************************************************************************
;     ISFOCUS - to querry if widget in focus
;****************************************************************************

function drip_anal::isfocus
return, self.focus
end

;****************************************************************************
;     ISSHOW - to querry if widget shown if display is not in focus
;****************************************************************************

function drip_anal::isshow
return, 0
end

;******************************************************************************
;     GETDATA - Return the SELF structure elements
;******************************************************************************
function drip_anal::getdata, title=ti, focus=fo, top=to, disp=di

if keyword_set(ti) then return, self.title
if keyword_set(fo) then return, self.focus
if keyword_set(to) then return, self.top
if keyword_set(di) then return, self.disp

end

;****************************************************************************
;     CLEANUP - to destroy analysis object
;****************************************************************************

pro drip_anal::cleanup
end

;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal::init, disp, analman, title
self.disp=disp
self.analman=analman
self.title=title
self.top=1
return, 1

end

;****************************************************************************
;     CW Features: EVENTHANDLER
;****************************************************************************

pro drip_anal_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
end

;****************************************************************************
;     DRIP_ANAL__DEFINE
;****************************************************************************

pro drip_anal__define

struct={drip_anal, $
        title:'', $          ; object title
        focus:0, $           ; focus status (1 if in focus else 0)
        top:0, $             ; top status (1 if on top, 0 else)
        disp:obj_new(), $    ; display object
        analman:obj_new(), $ ; analman object
        labelwid:0L }        ; label widget
end

