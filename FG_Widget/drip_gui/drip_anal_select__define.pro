; NAME:
;     DRIP_ANAL_SELECT__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Pipe Step Selection Analysis Objects for the GUI. This analysis
;     object allows the user to send any data from the dataman to the
;     displays.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_ANAL_SELECT inherits DRIP_ANAL
;     DRIP_ANALMAN_SELECT: This object creates ANAL_SELECT and
;                          assigns it screen widgets
;     CW_DRIP_DISP: DISPlays inform ANAL_SELECT of changes in focus,
;                   request updates redraws. ANAL_SELECT sends new
;                   data to display to the DISP (DISP::IMAGESET).
;     DRIP_DATAMAN: ANAL_SELECT requests lists of daps and elements
;                   and get data from DATAMAN. DATAMAN notifies
;                   ANAL_SELECT if data has changed or new data is
;                   available (ANAL_SELECT::NEWDAP)
;     DRIP_PIPEMAN: PIPEMAN sets which data ANAL_SELECT should send to
;                   the display (according to pipe->display configuration)
;     ATV: Is used by ANAL_SELECT as an external viewer.
;
; PROCEDURE:
;     On top of normal analysis object functions (focus, title)
;     ANAL_SELECT acts as a data conduit between the displays and the
;     rest of the GUI. Data is always moved from the DATAMAN to the
;     displays. There are three ways in which the data can be updated
;     / changed:
;       1) The user selects a different DAP or element from the
;          ANAL_SELECT widgets
;       2) DATAMAN notifies ANAL_SELECT that new data is available
;          (DATAMAN::CHANNELCALL calls ANAL_SELECT::NEWDAP)
;       3) PIPEMAN sets which DAP and ELEMENT to display by calling
;          ANAL_SELECT::NEWDAP
;     ANAL_SELECT automatically selects which ELEMENTS of the current
;     DAP are appropriate for showing in the DISP.
;
; RESTRICTIONS:
;     In developement
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, May 2004
;                  Created from drip_anal_scale__define.pro
;     Modified:    Marc Berthoud, CU, July 2006
;                  Modified to use DAPs from dataman
;     Fixed:       Marc Berthoud, Yerkes, March 2010
;                  Added code to compensate for loss of window focus
;                  after droplist events

;****************************************************************************
;     RESET - reset the object
;****************************************************************************

pro drip_anal_select::reset
self.dapn=0
self.elemn=0
*self.dataraw=fltarr(256,256)
end

;****************************************************************************
;     UPDATE - updates selections values in widgets
;****************************************************************************

pro drip_anal_select::update

if self.focus then begin
   ; set DAta Product to choose
   if self.dapn gt 0 then begin
       widget_control, self.drop_dap, set_droplist_select=self.dap_sel, $
         set_value=*self.daplist, sensitive=1
   endif else begin
       widget_control, self.drop_dap, set_droplist_select=0, sensitive=0, $
         set_value=*self.daplist
   endelse
   ; set element to choose
   if self.elemn gt 0 then begin
       widget_control, self.drop_elem, set_droplist_select=self.elem_sel, $
         set_value=*self.elemlist, sensitive=1
   endif else begin
       widget_control, self.drop_elem, set_droplist_select=0, sensitive=0, $
         set_value=*self.daplist
   endelse
   ; set frame step to choose
   imgsize=size(*self.dataraw)
   if imgsize[0] gt 2 then begin
       val=indgen(imgsize[3])+1
       vals=strtrim(string(val),2)+'/'+strtrim(string(imgsize[3]),2)
       widget_control, self.drop_frame, set_droplist_select=self.frame_sel, $
         sensitive=1, set_value=vals
   endif else begin
       widget_control, self.drop_frame, set_droplist_select=0, sensitive=0, $
         set_value=['0']
   endelse
   ; set TV button sensitive or not
   if self.elemn gt 0 then begin
       widget_control, self.button_tv, sensitive=1
   endif else begin
       widget_control, self.button_tv, sensitive=0
   endelse
endif
end

;****************************************************************************
;     IMAGEGET - acquired data and sends it to the display
;****************************************************************************

pro drip_anal_select::imageget

;** get correct element
if self.elemn gt 0 then begin
   ; get names
   dapname=(*self.daplist)[self.dap_sel]
   elemname=strupcase((*self.elemlist)[self.elem_sel])
   ; get data
   image=self.dataman->getelement(dapname,elemname)
   if size(image,/N_dimensions) gt 0 then begin
       imgtext=dapname+'['+elemname
   endif else begin
       image=fltarr(256,256)
       imgtext='none'
   endelse
endif else begin
   image=fltarr(256,256)
   imgtext='none'
endelse
*self.dataraw=image
;** if multiframe select required frame
imgsize=size(image)
if imgsize[0] gt 2 then begin
   ; set self.frame if necessary
   self.framen=imgsize[3]
   if self.frame_sel ge imgsize[3] then begin
       self.frame_sel=0
   endif
   ; get image
   image=image[*,*,self.frame_sel]
   imgtext=imgtext+'['+strtrim(string(self.frame_sel),2)+']]'
endif else begin 
   imgtext=imgtext+']'
   self.frame_sel=0
   self.framen=0
endelse
;** pass image (2d) to display
self.disp->imageset,image,imgtext
end

;****************************************************************************
;     NEWDAP - confirms current DAP and element selection or resets them
;****************************************************************************
pro drip_anal_select::newdap, dapnew=dapnew, elemnew=elemnew
; set new or save old dap and element names
if keyword_set(dapnew) then olddap=dapnew $
else olddap=(*self.daplist)[self.dap_sel]
if keyword_set(elemnew) then oldelem=elemnew $
else oldelem=(*self.elemlist)[self.elem_sel]
; get dap list
self.dapn=self.dataman->listdap(list)
*self.daplist=list
; if dapn=0 put empty data
if self.dapn eq 0 then begin
   self.dap_sel=0
   self.elem_sel=0
   self.frame_sel=0
   *self.daplist=['No Data Products']
   *self.elemlist=['No Elements']
   self->imageget
   return
endif
; check if old dap seleciton available else set to first dap
dapi=-1
repeat dapi=dapi+1 $
 until (olddap eq (*self.daplist)[dapi]) or (dapi eq self.dapn-1)
if olddap eq (*self.daplist)[dapi] then dap_sel=dapi else dap_sel=0
self.dap_sel=dap_sel
;** get valid element list for current dap (i.e. 2D or 3D images)
dapname=(*self.daplist)[self.dap_sel]
elemtot=self.dataman->listelement(dapname,fulllist)
self.elemn=0
elemsize=[0,0]
for elemi=0,elemtot-1 do begin
   elemsize=self.dataman->checkelement(dapname,fulllist[elemi],/size)
   ; check if a valid element -> add to list
   if elemsize[0] gt 1 then begin
       name=strmid(fulllist[elemi],0,1)+ $
         strlowcase(strmid(fulllist[elemi],1))
       if self.elemn gt 0 then begin
           *self.elemlist=[*self.elemlist,name]
       endif else begin
           *self.elemlist=[name]
       endelse
       self.elemn=self.elemn+1
   endif
endfor
;** set self.elem_sel
; check if any elements available
if self.elemn gt 0 then begin
; look for current element selection
   elemi=-1
   repeat elemi=elemi+1 until $
     ((*self.elemlist)[elemi] eq oldelem) or (elemi eq self.elemn-1)
   if (*self.elemlist)[elemi] eq oldelem then begin
       self.elem_sel=elemi
   endif else begin
   ; if not found look for preferred element seleciton
       elemi=-1
       repeat elemi=elemi+1 $
         until ((*self.elemlist)[elemi] eq self.elem_pref) or $
         (elemi eq self.elemn-1)
       if (*self.elemlist)[elemi] eq self.elem_pref then begin
           self.elem_sel=elemi
       endif else begin
           self.elem_sel=0
       endelse
   endelse
endif else begin
   self.elem_sel=0
   self.frame_sel=0
   *self.elemlist=['No Elements']
endelse
; call imageget
self->imageget
end

;****************************************************************************
;     INPUT - reacts to user input
;****************************************************************************

pro drip_anal_select::input, event
; set variables
case event.id of
   ; DAta Product selection
   self.drop_dap:begin
       ; save old element (string)
       oldelem=(*self.elemlist)[self.elem_sel]
       ; get new dap index and name
       self.dap_sel=event.index
       dapname=(*self.daplist)[self.dap_sel]
       ;** get valid elements list for new dap
       elemtot=self.dataman->listelement(dapname,fulllist)
       self.elemn=0
       for elemi=0,elemtot-1 do begin
           elemsize=self.dataman->checkelement(dapname,fulllist[elemi],/size)
           ; check if a valid element -> add to list
           if elemsize[0] gt 1 then begin
               name=strmid(fulllist[elemi],0,1)+ $
                 strlowcase(strmid(fulllist[elemi],1))
               if self.elemn gt 0 then begin
                   *self.elemlist=[*self.elemlist,name]
               endif else begin
                   *self.elemlist=[name]
               endelse
               self.elemn=self.elemn+1
           endif
       endfor
       ;** set self.elem_sel
       ; check if any elements available
       if self.elemn gt 0 then begin
           ; look for current element selection
           elemi=-1
           repeat elemi=elemi+1 until $
             ((*self.elemlist)[elemi] eq oldelem) or (elemi eq self.elemn-1)
           if (*self.elemlist)[elemi] eq oldelem then begin
               self.elem_sel=elemi
           endif else begin
               ; if not found look for preferred element seleciton
               elemi=-1
               repeat elemi=elemi+1 $
                 until ((*self.elemlist)[elemi] eq self.elem_pref) or $
                 (elemi eq self.elemn-1)
               if (*self.elemlist)[elemi] eq self.elem_pref then begin
                   self.elem_sel=elemi
               endif else begin
                   self.elem_sel=0
               endelse
           endelse
       endif else begin
           self.elem_sel=0
           *self.elemlist=['No Elements']
       endelse
       self->imageget
       self.dataman->callinfo,dapsel=dapname
       ; Set focus to display (fixes loss of focus by droplist widgets)
       widget_control, self.disp->getdata(/draw), /INPUT_FOCUS
   end
   ; element selection
   self.drop_elem:begin
       self.elem_sel=event.index
       dapname=(*self.daplist)[self.dap_sel]
       ; set frame_sel to valid value
       elemsize=self.dataman->checkelement( $
         dapname,(*self.elemlist)[self.elem_sel], /size)
       if elemsize[0] lt 3 then self.frame_sel=0 else begin
           if self.frame_sel gt elemsize[3]-1 then self.frame_sel=0
       endelse
       ; call imageget
       self->imageget
       ; save selection into elem_pref if we're in a pipe dap
       if self.dataman->checkelement(dapname,'MODE') then $
         self.elem_pref=(*self.elemlist)[self.elem_sel]
       ; Set focus to display (fixes loss of focus by droplist widgets)
       widget_control, self.disp->getdata(/draw), /INPUT_FOCUS
   end
   ; frame selection
   self.drop_frame:begin
       if self.framen gt 1 then begin
           self.frame_sel=event.index
           self->imageget
       endif
       ; Set focus to display (fixes loss of focus by droplist widgets)
       widget_control, self.disp->getdata(/draw), /INPUT_FOCUS
   end
   ; ATV button -> launch exernal viewer
   self.button_tv:begin
       atv22,(*self.dataraw)
       ;if (size(*self.dataraw))[0] EQ 3 then begin
       ;  drip_message,'ATV: Displaying 0th frame of 3-D array'
       ;endif
       ;smtv,(*self.dataraw);,lead=event.top, size=2*256
   end
   ; Button events from the display -> go to different frame / element
   self.disp_draw:begin
       if event.type eq 6 then begin
           case event.key of
               5:begin ; left -> decrease frame number
                   if (self.framen gt 0) and (self.frame_sel gt 0) then begin
                       self.frame_sel=self.frame_sel-1
                       self->imageget
                   endif                    
               end
               6:begin ; right -> increase frame number
                   if (self.framen gt 0) and $
                     (self.frame_sel lt self.framen-1) then begin
                       self.frame_sel=self.frame_sel+1
                       self->imageget
                   endif
               end
               7:begin ; up -> previous element
                   if(self.elemn gt 0) and (self.elem_sel gt 0) then begin
                       self.elem_sel=self.elem_sel-1
                       self->imageget
                   endif
               end
               8:begin ; down -> next element
                   if(self.elemn gt 0) and $
                     (self.elem_sel lt self.elemn-1) then begin
                       self.elem_sel=self.elem_sel+1
                       self->imageget
                   endif
               end
           endcase
       endif
   end
   else:
endcase
end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal_select::setwid, label, drop_dap, drop_elem, drop_frame, button_tv
self.labelwid=label
self.drop_dap=drop_dap
self.drop_elem=drop_elem
self.drop_frame=drop_frame
self.button_tv=button_tv
end

;****************************************************************************
;     SETFOCUS - puts object in and out of focus
;****************************************************************************

pro drip_anal_select::setfocus, focus
if focus ne self.focus then begin
    self.focus=focus
    if focus eq 1 then begin
        ;** set up widgets (callback functions, values and uvalues)
        ; label
        widget_control, self.labelwid, set_value=self.title
        ; set pipe step droplist
        widget_control, self.drop_elem, $
          set_uvalue={object:self, method:'input'}
        ; set sum select droplist
        widget_control, self.drop_dap, $
          set_uvalue={object:self, method:'input'}
        ; set frame select droplist
        widget_control, self.drop_frame, $
          set_uvalue={object:self, method:'input'}
        widget_control, self.button_tv, $
          set_uvalue={object:self, method:'input'}
        self.dataman->callinfo,dapsel=(*self.daplist)[self.dap_sel]
    endif
    ; update (will set the selections the the correct texts)
    self->update
endif
end

;****************************************************************************
;     CLEANUP - to clean up after object
;****************************************************************************

pro drip_anal_select::cleanup
; save elem_sel in configuration file
if self.elem_pref ne '' then begin
   common gui_config_info, guiconf
   parname='DISPSEL_'+string(byte(self.disp->getdata(/disp_id)))
   setpar,guiconf,parname,self.elem_pref
endif
; free all data
ptr_free, self.dataraw
ptr_free, self.daplist
ptr_free, self.elemlist
end

;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal_select::init, disp, analman, dataman, title

; same as parent
self.disp=disp
self.analman=analman
self.dataman=dataman
self.title=title
self.top=0
self.focus=0
; set selections
self.dap_sel=0
self.elem_sel=0
self.frame_sel=0
; allocate memory
self.dataraw=ptr_new(/allocate_heap)
self.daplist=ptr_new(/allocate_heap)
*self.daplist=['No DAta Product']
self.elemlist=ptr_new(/allocate_heap)
*self.elemlist=['No DAP Element']
; get id from disp
self.disp_draw=self.disp->getdata(/draw)
; look for elem_sel in configuration file
common gui_config_info, guiconf
parname='DISPSEL_'+string(byte(self.disp->getdata(/disp_id)))
self.elem_pref=getpar(guiconf,parname)
if size(self.elem_sel,/type) ne 7 then self.elem_sel=''
print,'loaded ',parname,'=',self.elem_sel
; register with dataman
dataman->channeladd, self
return, 1
end

;****************************************************************************
;     DRIP_ANAL_SELECT__DEFINE
;****************************************************************************

pro drip_anal_select__define

struct={drip_anal_select, $
       dataman:obj_new(), $ ; dataman object
       ; widgets
       drop_dap:0L, $       ; dap droplist id
       drop_elem:0L, $      ; step droplist id
       drop_frame:0L, $     ; frame droplist id
       button_tv:0L, $      ; button to call ATV
       disp_draw:0L, $      ; id of display draw widget (for input events)
       ; selections
       dap_sel:0, $         ; dap droplist selection
       elem_sel:0, $        ; step droplist selection
       elem_pref:'', $      ; preferred element selection
       frame_sel:0, $       ; frame droplist selection (starting with 0)
       ; data variables
       dapn:0, $            ; number of daps
       daplist:ptr_new(), $ ; list of current dap names
       elemn:0, $           ; number of available elements
       elemlist:ptr_new(), $ ; names of displayable elements in pipe
                            ;   both have 0,'none' as first selection
       framen:0, $          ; number of frames, 0 or 1 for no frames
       dataraw:ptr_new(), $ ; pointer to image (can be 3d)
       inherits drip_anal}  ; child object of drip_anal
end
