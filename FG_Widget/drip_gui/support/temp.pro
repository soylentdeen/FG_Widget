; NAME:
;   EDIT_PARAM_LIST - Version .1
;
; PURPOSE:
;   Edit a list of parameters and their values
;
; CALLING SEQUENCE:
;   EDIT_PARAM_LIST, LIST, COMMENT=COMMENT, /VIEWONLY
;
; INPUTS:
;   LIST - List with the parameters in the format
;          ['param1=value1','param2=value2','param3=value3']
;   COMMENT - comment printed as first line
;   VIEWONLY - no editing if this flag is set
;   PATH - path to look for files when loading parameter lists
;
; OUTPUTS:
;
; SIDE EFFECTS:
;   This is command opens a blocking window:
;
; RESTRICTIONS:
;
; PROCEDURE:
;   Makes a text with the format parameter=value. The text is
;   displayed in a editable text window with some lines of
;   instructions. Then the text is translated back into a parameter
;   list and returned.
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Palomar 2005-6-25
;               viewonly and path not implemented yet
;

pro edit_param_list_event, event
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

pro edit_param_list, list, path=path, viewonly=viewonly, comment=comment

; check and set
s=size(list)
if (s[0] ne 1) or (s[2] ne 7) then $
  message, 'edit_param_list - must have valid parameter list'
statval=ptr_new(/allocate_heap) ; to return values once
text=ptr_new(/allocate_heap) ; to return text
*text=['']
; translate paramlist -> text
if keyword_set(comment) then intext=[comment] else intext=['']
for i=0,(size(list))[1]-1 do intext=[intext,list[i]]
; make widgets
top=widget_base(uvalue=statval, /column)
if keyword_set(viewonly) then $
    textwid=widget_text(top, event_pro='edit_param_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3) else $
    textwid=widget_text(top, event_pro='edit_param_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3, $
           /editable )

;if keyword_set(viewonly) then begin
;    widget_control, textwid, /editable
;    print,'not editable'
;endif
button_list=widget_base(top, /row)
;loadwid=widget_button(button_list, value='Load', uvalue=2, $
;                          event_pro='edit_param_list_event')
if not keyword_set(viewonly) then $
  chancelwid=widget_button(button_list, value='Chancel', uvalue=0, $
                           event_pro='edit_param_list_event') $
  else chancelwid=0
donewid=widget_button(button_list, value='Done', uvalue=1, $
                          event_pro='edit_param_list_event')
; set status value
*statval={textwid:textwid, chancelwid:chancelwid, $
          donewid:donewid, retval:0, text:text }
; realize and start widgets
widget_control, top, /realize
xmanager, 'Edit Parameter List', top
; if done and interactive: translate text -> paramlist
if ((*statval).retval gt 0) and (not keyword_set(viewonly)) then begin
    list=['']
    for i=0,(size(*text))[1]-1 do begin
        pos=strpos((*text)[i],'=')
        param=strtrim(strmid((*text)[i],0,pos),2)
        value=strtrim(strmid((*text)[i],pos+1),2)
        if (strlen(param) gt 0) and (strlen(value) gt 0) then $
          list=[list,param+'='+value]
    endfor
endif

end
