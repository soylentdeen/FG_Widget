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
    (*statval).filter_text:
    (*statval).filterwid:begin
       list=(*statval).list
       ;update changes to the original list
       widget_control,(*statval).textwid, get_value = text
       list[*(*statval).flt_idx]= text
       widget_control,(*statval).filter_text,get_value=filter
       if (strlen(filter) eq 0) then filter='*'
       flt_idx=where(strmatch(list,filter,/fold_case) eq 1,count)
       if (count gt 0) then begin
          widget_control,(*statval).textwid, set_value=list[flt_idx]
          *(*statval).flt_idx=flt_idx
       endif else widget_control,(*statval).textwid, set_value=' '
       break
    end
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

intext=list
; make widgets
top=widget_base(uvalue=statval, /column) ; top
if keyword_set(comment) then com_label=widget_label(top,value=comment,$
                     /dynamic_resize)
if keyword_set(viewonly) then $ ; text
    textwid=widget_text(top, event_pro='edit_string_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3) else $
    textwid=widget_text(top, event_pro='edit_string_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3, $
           /editable )
if not keyword_set(viewonly) then widget_control, textwid, /editable

;make filter widgets
filter_base=widget_base(top, /row)
filter_label=widget_label(filter_base ,value='Enter text to Filter: ')
filter_text=widget_text(filter_base,/editable,xsize=20,uvalue=5,$
                        event_pro='edit_param_list_event')
filter_button=widget_button(filter_base, value='Filter',$
                            uvalue=4, event_pro='edit_param_list_event')
flt_idx=ptr_new(intarr(n_elements(list)))

;make buttons
button_list=widget_base(top, /row) ; button base
if not keyword_set(viewonly) then $ ; [Chancel]
  chancelwid=widget_button(button_list, value='Chancel', uvalue=0, $
                           event_pro='edit_string_list_event') $
  else chancelwid=0


donewid=widget_button(button_list, value='Done', uvalue=1, $ ; [DONE]
                          event_pro='edit_string_list_event')

; set status value
*statval={textwid:textwid, chancelwid:chancelwid, $
          donewid:donewid, retval:0, text:text, list:list,$
          filter_text:filter_text, filterwid:filter_button,$ 
          flt_idx:flt_idx}

; realize and start widgets
widget_control, top, /realize
xmanager, 'Edit Parameter List', top

; if done and interactive: translate text -> paramlist
if ((*statval).retval gt 0) and (not keyword_set(viewonly)) then list=*text

end
