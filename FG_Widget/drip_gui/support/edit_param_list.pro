; NAME:
;   EDIT_PARAM_LIST - Version 1.1
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
;   This command opens a blocking window:
;
; RESTRICTIONS:
;   Do not add or delete lines if you are using the filtering
;   function. If done is pressed when the text is filtered, only the
;   matching lines are returned.
;
; PROCEDURE:
;   Makes a text with the format parameter=value. The text is
;   displayed in a editable text window with some lines of
;   instructions. Then the text is translated back into a parameter
;   list and returned. The entries can also be filtered such that only
;   lines matching a certain pattern are shown.
;
; MODIFICATION HISTORY
;   Written By: Marc Berthoud Palomar 2005-6-25
;               path not implemented yet
;   Modified By: Nirbhik Chitrakar 04/2009
;                added filter utility
;

;***********************************************************
;     EDIT_PARAM_LIST_EVENT - event function
;***********************************************************
pro edit_param_list_event, event
widget_control, event.id, get_uvalue=uval
widget_control, event.top, get_uvalue=statval
switch event.id of
    ; Filter Text
    (*statval).filter_text:
    (*statval).filterwid:begin
        list=(*statval).list
        ; update changes to the original list if the text
        widget_control,(*statval).textwid, get_value = text
        list[*(*statval).flt_idx]= text
        ; get filter search string
        widget_control,(*statval).filter_text, get_value=filter
        if (strlen(filter) eq 0) then filter='*'
        ; Find header lines containing the filter (e.g. filter+'*')
        flt_idx=where(strmatch(list,filter+'*',/fold_case) eq 1,count)
        ; Send matching lines to text (or all lines if no match found)
        if (count gt 0) then begin
            widget_control,(*statval).textwid, set_value=list[flt_idx]
            *(*statval).flt_idx=flt_idx
        endif else widget_control,(*statval).textwid, set_value='No match found'
        break
    end
    ; Done -> Save and exit
    (*statval).donewid: begin
        (*statval).retval=1
        widget_control, (*statval).textwid, get_value=text
        *(*statval).text=text
        widget_control, event.top, /destroy
        break
    end
    ; Chancel -> Exit
    (*statval).chancelwid: begin
        (*statval).retval=0
        widget_control, event.top, /destroy
        break
    end
endswitch
end

;******************************************************************************
;     EDIT_PARAM_LIST - Main functions
;******************************************************************************
pro edit_param_list, list, path=path, viewonly=viewonly, comment=comment

; check and set
s=size(list)
if (s[0] ne 1) or (s[2] ne 7) then $
  message, 'edit_param_list - must have valid parameter list'
statval=ptr_new(/allocate_heap) ; to return values once
text=ptr_new(/allocate_heap) ; to return text
*text=['']

intext=list
; make widgets
top=widget_base(uvalue=statval, title='FORCAST FITS File Header', /column)
if keyword_set(comment) then com_label=widget_label(top,value=comment,$
                     /dynamic_resize)
if keyword_set(viewonly) then $
    textwid=widget_text(top, event_pro='edit_param_list_event', $
           /scroll, value=intext, xsize=80, ysize=40, uvalue=3) else $
    textwid=widget_text(top, event_pro='edit_param_list_event', $
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
button_list=widget_base(top, /row)
if not keyword_set(viewonly) then $
  chancelwid=widget_button(button_list, value='Chancel', uvalue=0, $
                           event_pro='edit_param_list_event') $
  else chancelwid=0
donewid=widget_button(button_list, value='Done', uvalue=1, $
                          event_pro='edit_param_list_event')
; set status value
*statval={textwid:textwid, chancelwid:chancelwid, $
          donewid:donewid, retval:0, text:text , $
          filter_text:filter_text, filterwid:filter_button, $
          flt_idx:flt_idx, list:list}

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
