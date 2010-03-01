; NAME:
;   EDIT_STRING_LIST - Version .1
;
; PURPOSE:
;   Edit a list of strings
;
; CALLING SEQUENCE:
;   EDIT_PARAM_LIST, LIST, COMMENT=COMMENT, /VIEWONLY
;
; INPUTS:
;   LIST - Array with Strings
;          ['string1','string2','string3']
;   COMMENT - comment printed at the top
;   VIEWONLY - no editing if this flag is set
;
; OUTPUTS:
;
; SIDE EFFECTS:
;   This is command opens a blocking window:
;
; RESTRICTIONS:
;
; PROCEDURE:
;   Takes a text as string array. The text is displayed in a editable
;   text window with some lines of instructions. Then the text is
;   translated back into a parameter list and returned.
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Cornell 2007-9-10
;               Most code from edit_param_list.pro
;

;******************************************************************************
;     EDIT_STRING_LIST_EVENT - event function
;******************************************************************************

pro edit_string_list_event, event
widget_control, event.id, get_uvalue=uval
widget_control, event.top, get_uvalue=statval
switch event.id of
    (*statval).donewid: begin
        (*statval).retval=1
        widget_control, (*statval).textwid, get_value=text
        *(*statval).text=text
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

;******************************************************************************
;     EDIT_STRING_LIST - Main functions
;******************************************************************************
pro edit_string_list, list, path=path, viewonly=viewonly, comment=comment

; check and set
s=size(list)
if (s[0] ne 1) or (s[2] ne 7) then $
  message, 'edit_string_list - must have valid list (string array)'
statval=ptr_new(/allocate_heap) ; to return values once
text=ptr_new(/allocate_heap) ; to return text
*text=['']
; translate list -> text
intext=[list[0]]
for i=1,(size(list))[1]-1 do intext=[intext,list[i]]
; make widgets
top=widget_base(uvalue=statval, /column) ; top
if keyword_set(comment) then labelwid=widget_label(top,value=comment) ; label
if keyword_set(viewonly) then $ ; text
    textwid=widget_text(top, event_pro='edit_string_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3) else $
    textwid=widget_text(top, event_pro='edit_string_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3, $
           /editable )
if not keyword_set(viewonly) then widget_control, textwid, /editable
button_list=widget_base(top, /row) ; button base
if not keyword_set(viewonly) then $ ; [Chancel]
  chancelwid=widget_button(button_list, value='Chancel', uvalue=0, $
                           event_pro='edit_string_list_event') $
  else chancelwid=0
donewid=widget_button(button_list, value='Done', uvalue=1, $ ; [DONE]
                          event_pro='edit_string_list_event')
; set status value
*statval={textwid:textwid, chancelwid:chancelwid, $
          donewid:donewid, retval:0, text:text }
; realize and start widgets
widget_control, top, /realize
xmanager, 'Edit Parameter List', top
; if done and interactive: translate text -> paramlist
if ((*statval).retval gt 0) and (not keyword_set(viewonly)) then list=*text

end
