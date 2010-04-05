; NAME:
;     CW_COLOR_SEL - Version .1
;
; PURPOSE:
;     Color Select compound widget
;
; CALLING SEQUENCE:
;     WidgetID = CW_COLOR_SEL( PARENT, COLOR, LABEL)
;
; INPUTS:
;     PARENT - Widget ID of the parent widget.
;     COLOR - Color Value (bytarray(3) for r g b values)
;
; STRUCTURE: (saved as user value of first child)
;     {TOP, DRAW, COLOR}
;     TOP - top widget
;     DRAW - draw widget
;     COLOR - Color Value (bytarray(3) for r g b values)
;
; EVENTS:
;     Creates an event that has as color the new color value
;     if a color is selected
;
; OUTPUTS:
;     WidgetID - widget ID of the top level widget
;
; MODIFICATION HISTORY
;     Written by: Marc Berthoud, Cornell University, 2004
;

;***********************************************************
;     CW_COLOR_SEL_SETCOL - Set Value Function
;***********************************************************

pro cw_color_sel_setcol, id, color

; get state
child=widget_info(id, /child)
widget_control, child, get_uvalue=state, /no_copy
; set color
state.color=color
; set color in field
widget_control, state.draw, get_value=wid
wset, wid

dx=state.xsize
dy=state.ysize
ddy=1+dy/8
arr=bytarr(dx,dy)
arr[0:dx/2-1,*]=0
arr[dx/2:dx-1,*]=255
arr[*,ddy:dy-ddy-1]=color[0]
tv,arr,0,0,1
arr[dx/4:dx/2-1,*]=255
arr[dx/2:3*dx/4-1,*]=0
arr[*,ddy:dy-ddy-1]=color[1]
tv,arr,0,0,2
arr[*,0:dy/2-1]=255
arr[*,dy/2:dy-1]=0
arr[*,ddy:dy-ddy-1]=color[2]
tv,arr,0,0,3
; set state
widget_control, child, set_uvalue=state, /no_copy
end

;***********************************************************
;     CW_COLOR_SEL_GETCOL - Get Value Function
;***********************************************************

function cw_color_sel_getcol, id

; get state, color
child=widget_info(id, /child)
widget_control, child, get_uvalue=state, /no_copy
color=state.color
; set state
widget_control, child, set_uvalue=state, /no_copy
; return
return, color
end

;***********************************************************
;     CW_COLOR_SEL_EVENT - Event Handling Function
;***********************************************************

function cw_color_sel_event, event

; get state, color
top=widget_info(event.handler, /parent)
child=widget_info(top, /child)
widget_control, child, get_uvalue=state, /no_copy
; check if event from draw
if event.id eq state.draw then begin
    ; check if mousedown or mouseup
    widget_control, state.draw, get_value=wid
    wset, wid
    dx=state.xsize
    dy=state.ysize
    ddy=1+dy/8
    case event.type of
        0: begin ; button press
            ; set colors
            ; 000 0g0 r00 rg0
            ; 00b 0gb r0b rgb
            arr=bytarr(dx,dy)
            arr[0:dx/2-1,*]=0
            arr[dx/2:dx-1,*]=255
            tv,arr,0,0,1
            arr[dx/4:dx/2-1,*]=255
            arr[dx/2:3*dx/4-1,*]=0
            tv,arr,0,0,2
            arr[*,0:dy/2-1]=255
            arr[*,dy/2:dy-1]=0
            tv,arr,0,0,3
            ret=0 ; to return no further event
        end
        1: begin ; button release
            ; check if mouse release inside field
            x=event.x
            y=event.y
            if (x ge 0) and (x lt 40) and (y ge 0) and (y lt 30) then begin
                ; get color from mouse position
                color=bytarr(3)
                if x lt dx/2 then color[0]=0 else color[0]=255
                if (x lt dx/4) or ((x lt 3*dx/4) and (x ge dx/2)) then $
                    color[1]=0 else color[1]=255
                if y lt dy/2 then color[2]=255 else color[2]=0
                ; set color
                state.color=color
                arr=bytarr(dx,dy-2*ddy)
                arr[*,*]=color[0]
                tv,arr,0,ddy,1
                arr[*,*]=color[1]
                tv,arr,0,ddy,2
                arr[*,*]=color[2]
                tv,arr,0,ddy,3
                ; make retrun event
                ret = { cw_color_sel_event, id: state.top, top:event.top, $
                        handler:0L, color:color}
            endif else begin
                ; set back to old color
                arr=bytarr(dx,dy-2*ddy)
                arr[*,*]=state.color[0]
                tv,arr,0,ddy,1
                arr[*,*]=state.color[1]
                tv,arr,0,ddy,2
                arr[*,*]=state.color[2]
                tv,arr,0,ddy,3
                ret=0
            endelse
        end
    endcase
endif else ret=0 ; to return no further event
; set state
widget_control, child, set_uvalue=state, /no_copy
; return
return, ret
end

;***********************************************************
;     CW_COLOR_SEL - Creating Function
;***********************************************************

function cw_color_sel, parent, color, uvalue=uvalue, label=label, $
                       event_pro=event_pro, event_func=event_func, $
                       xsize=xsize, ysize=ysize

; get params
if not keyword_set(xsize) then xsize=40
if not keyword_set(ysize) then ysize=24
; open widgets
top=widget_base(parent, /row, $
                pro_set_value='cw_color_sel_setcol', $
                func_get_value='cw_color_sel_getcol' )
if keyword_set(label) then labelwid=widget_label(top, value=label)
draw=widget_draw(top, xsize=xsize, ysize=ysize, /button_events, $
                 event_func='cw_color_sel_event')
; make record and set
state={top:top, draw:draw, color:color, xsize:xsize, ysize:ysize}
widget_control, widget_info(top, /child) , set_uvalue=state, /no_copy
; set functions
if keyword_set(uvalue) then $
    widget_control, top, set_uvalue=uvalue
if keyword_set(event_pro) then $
    widget_control, top, event_pro=event_pro
if keyword_set(event_func) then $
    widget_control, top, event_func=event_func
; return id
return, top

end
