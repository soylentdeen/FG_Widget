; NAME:
;     CW_DRIP_MW - Version 1.7.0
;
; PURPOSE:
;     Message window compound widget
;
; CALLING SEQUENCE:
;     ObjRef = CW_DRIP_MW( TOP, XSIZE=XS, YSIZE=YS)
;
; INPUTS:
;     TOP - Widget ID of the parent widget.
;     XSIZE - X dimension of the display windows
;     YSIZE - Y dimension of the display windows
;
; OUTPUTS:
;     ObjRef - the object reference of the associated object.
;
; CALLED ROUTINES AND OBJECTS:
;
; PROCEDURE:
;     This compound widget prints lines of text in a window. The last
;     line is kept at the bottom of the window. Old lines are deleted
;     after a maximum number of lines has been reached.
;
; RESTRICTIONS:
;     Container base widget id is lost. Unlike other compound widgets,
;     this widget returns an object reference instead.
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, March, 2003
;     Modified:    Marc Berthoud CU, June 2003
;                  Added self.sizemax for maximal number of lines
;

;******************************************************************************
;     PRINT - print text to listbox
;******************************************************************************

pro drip_mw::print, text
; add the text to the existing lines
if self.size eq 0 then val=text else begin
      val=[*self.value, text]
      if self.size gt self.sizemax-1 then val=val(1:self.sizemax)
endelse
*self.value=val
self.size=size(val, /n_elements)

; determine top line
top = self.size-9
if top lt 0 then top = 0

; set new text
widget_control, self.listid, set_value=val, set_list_top=top
end

;******************************************************************************
;     CLEANUP - Free pointer heap variables
;******************************************************************************

pro drip_mw::cleanup
ptr_free, self.value
end

;******************************************************************************
;     INIT - Initialize structure
;******************************************************************************

function drip_mw::init, list
self.value=ptr_new(/allocate_heap)
self.listid=list
self.sizemax=200
return, 1
end

;******************************************************************************
;     DRIP_MW__DEFINE
;******************************************************************************

pro drip_mw__define

struct={drip_mw, $
      value:ptr_new(), $;value in listbox
      size:0s, $        ;n_elements of value
      sizemax:0s, $     ;its maximum i.e. maximal number of lines
      listid:0L}        ;listbox widget id
end

;******************************************************************************
;     CW Definition: EVENTHANDLER / CLEANUP / CREATING FUNCTION
;******************************************************************************

pro drip_mw_cleanup, id
widget_control, id, get_uvalue=obj
obj_destroy, obj
end

pro drip_mw_eventhand, event
end

function cw_drip_mw, top, xsize=xs, ysize=ys, _extra=ex
; lay out widgets
tlb=widget_base(top, /frame, /column, /align_center)
list=widget_list(tlb, xsize=xs, ysize=ys, event_pro='drip_mw_eventhand', $
                 kill_notify='drip_mw_cleanup', _extra=ex)
; create associated object, put in list uvalue
obj=obj_new('drip_mw', list)
widget_control, list, set_uvalue=obj
; returns object, not id of base widget
return, tlb
end
