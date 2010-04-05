; NAME:
;   DIALOG_INPUT - Version .1
;
; PURPOSE:
;   Get an input value from the user
;
; CALLING SEQUENCE:
;   RESULT=DIALOG_INPUT(PROMPT)
;
; INPUTS:
;   PROMPT - Prompt to ask the user
;
; OUTPUTS:
;   RESULT - Input returned by the user
;            returns '' if [chancel] is pressed
;
; SIDE EFFECTS:
;   This command opens a blocking window
;
; RESTRICTIONS:
;
; PROCEDURE:
;   Opens a window with the prompt message, gives [OK] [Chancel] buttons
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Palomar 2006-7-2
;

pro dialog_input_event, event
widget_control, event.id, get_uvalue=uval
widget_control, event.top, get_uvalue=statval
switch event.id of
    (*statval).okwid: begin
        (*statval).retval=1
        widget_control, (*statval).fieldwid, get_value=input
        (*statval).input=input
        widget_control, event.top, /destroy
        break
    end
    (*statval).chancelwid: begin
        (*statval).retval=0
        widget_control, event.top, /destroy
        break
    end
endswitch
end

function dialog_input, prompt

; check and set
statval=ptr_new(/allocate_heap) ; to return values once
; make widgets
top=widget_base(uvalue=statval, /column)
field=cw_field(top,title=prompt, xsize=20)
buttons=widget_base(top, /row)
button_ok=widget_button(buttons, value='OK', event_pro='dialog_input_event')
button_chancel=widget_button(buttons, value='Chancel', $
                             event_pro='dialog_input_event')
; set status value
*statval={fieldwid:field, chancelwid:button_chancel, $
          okwid:button_ok, retval:0, input:'' }
; realize and start widgets
widget_control, top, /realize
xmanager, 'Input:', top
; if done and interactive: translate text -> paramlist
if (*statval).retval gt 0 then return,(*statval).input else return,''
end
