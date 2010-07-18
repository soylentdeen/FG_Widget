; NAME:
;     DRIP_ANAL__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Analysis Objects for the GUI. This analysis object displays a
;     title for it's GUI display.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_ANALMAN: These objects create ANALOBJs and assign it screen
;                   widgets
;     CW_DRIP_DISP: DISPlays inform ANALOBJs of changes in focus,
;                   request updates and redraws
;
; PROCEDURE:
;     Whenever the display associated with this analysis object comes
;     into focus, the new title is displayed.
;
; RESTRICTIONS:
;     In developement
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
;     INPUT - reacts to user input
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

