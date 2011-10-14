; NAME:
;     DRIP_DISPMAN - Version 1.7.0
;
; PURPOSE:
;     Display Manager for the GUI. Has overall management of the image
;     displays and the analysis objects.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_DISP: DISPMAN manages the displays
;     ANALMAN: DISPMAN commands to set the analysis objects if a new
;              display comes into focus
;
; PROCEDURE:
;     DISPMAN is responsible for the overall management of the
;     displays: It puts them in focus, manages and updates mouse
;     location / value / focus display and resets them. The only
;     interaction that DISPMAN has with ANAL and ANALMAN objects is
;     to call ANALMAN::SETALLWID when a new display comes to focus.
;
; RESTRICTIONS:
;     None
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, October 2003
;     Modified: Marc Berthoud, Cornell University, December 2003
;               Passed display mousevent action to displays
;               Added capability to deal with analysis objects
;     Modified: Marc Berthoud, Cornell University, March 2004
;               Imgman now makes its own widgets and widgets for
;                 analysis objects
;               Widgets are now shared between analysis objects from
;                 different displays
;     Modified: Marc Berthoud, Cornell University, May 2004
;               Imgman takes over all disp responsibility from dispman
;     Modified: Marc Berthoud, Cornell University, April 2005
;               Possible to take any size images
;     Modified: Marc Berthoud, Cornell University, June 2005
;               Upgraded to use pointsource analysis objects
;     Modified: Marc Berthoud, CU, April 2006
;               - renamed imgman -> dispman
;     Modified: Marc Berthoud, CU, July 2006
;               - added optional use of analysis tools
;               - use of drip_anal_extract
;     Modified: Nirbhik Chitrakar, IC, July 2007
;               - Added extended functionality for drip_anal_extract
;     Modified: Marc Berthoud, CU, November 2007
;               - Moved responsibility for managing analysis objects
;                 to drip_analman


;****************************************************************************
;     RESET - Reset droplists
;****************************************************************************

pro drip_dispman::reset
; clear own widgets
if self.mouse_active gt 0 then begin
   widget_control,self.location,set_value='   (0,0)'
   widget_control,self.value,set_value='   no data'
endif
; clear displays
dispn=size(*self.disps,/n_elements)
for i=0, dispn-1 do begin
     (*self.disps)[i]->reset
endfor
end

;**********************************************************************
;     RAISEDISP - to raise a display to focus
;                 (this function is called by the display event function)
;**********************************************************************

pro drip_dispman::raisedisp, disp
if disp ne self.dispinfocus then begin

   ; deactivate analysis widgets
   widget_control, self.upwidget, update=0
   ; lower display
   self.dispinfocus->setfocus,0
   self.dispinfocus->draw
   ; raise new display
   self.dispinfocus=disp
   self.dispinfocus->setfocus,1
   ; assign new widgets (and update them)
   analmann=size(*self.analmans,/n_elements)
   for i=0, analmann-1 do (*self.analmans)[i]->setallwid
   ; redraw and update standard analysis objects
   self.dispinfocus->draw
   ; reactivate analysis widgets
   widget_control, self.upwidget, /update
endif
end

;**********************************************************************
;     FOLLOW - to update mouse location, value and zoomin
;              (this function is called by the display event function)
;**********************************************************************

pro drip_dispman::follow, disp, event
if self.mouse_active gt 0 then begin
   ; find x, y in image
   ; (first find length in pix of longest image side)
   image=disp->getdata(/dataraw)
   imgsize=size(*image)
   xsize=disp->getdata(/xsize)
   ysize=disp->getdata(/ysize)
   zoom=disp->getdata(/zoom)
   ;** check if data is available
   if imgsize[0] gt 0 then begin
       ;** set location and value text
       ; get cursor location
       xpos=event.x-2
       ypos=event.y-2
       ; set range inside field
       ximg=long(float(xpos)/zoom)
       yimg=long(float(ypos)/zoom)
       if  ximg lt 0 then ximg=0
       if ximg gt imgsize[1]-1 then ximg=imgsize[1]-1
       if yimg lt 0 then yimg=0
       if yimg gt imgsize[2]-1 then yimg=imgsize[2]-1
       ; get text
       value=float((*image)[ximg,yimg])
       loctext=string(ximg,yimg,format='("  X=",I3," Y=",I3)')
       valtext='   '+ strtrim(string(value),2)
       ;** display zoom image
       ; get raw image
       dispimg=disp->getdata(/dispraw)
       ; set range >16 pix from border -> xmin xmax ymin ymax
       if ximg lt 16 then xmin=0 else xmin=ximg-16
       if ximg gt imgsize[1]-17 then xmax=imgsize[1]-1 else xmax=ximg+16
       if yimg lt 16 then ymin=0 else ymin=yimg-16
       if yimg gt imgsize[2]-17 then ymax=imgsize[2]-1 else ymax=yimg+16
       ; get image and resize it
       image=fltarr(33,33)
       image[16+xmin-ximg:16+xmax-ximg,16+ymin-yimg:16+ymax-yimg]= $
         (*dispimg)[xmin:xmax,ymin:ymax]
       image=congrid(image,165,165)
       ; draw image
       wset, self.closeup_wid
       tv, image
       ; draw box
       color=255+256L*(63+256L*63)
       plots, 79, 79, /device
       plots, 85, 79, /continue, color=color, /device
       plots, 85, 85, /continue, color=color, /device
       plots, 79, 85, /continue, color=color, /device
       plots, 79, 79, /continue, color=color, /device
   end else begin
       ;** if no data available
       loctext=string(event.x-2,event.y-2,format='("  X=",I3," Y=",I3)')
       valtext='   no data'
   endelse
   ; print text
   widget_control,self.location,set_value=loctext
   widget_control,self.value,set_value=valtext
endif
end

;******************************************************************************
;     GETDATA - Return the SELF structure elements
;******************************************************************************

function drip_dispman::getdata, dispinfocus=dispfoc

if keyword_set(dispfoc) then return, self.dispinfocus
end


;****************************************************************************
;     START
;****************************************************************************

pro drip_dispman::start, analmans

; get variables
*self.analmans=analmans
; get window id of closeup window
if self.mouse_active gt 0 then begin
   widget_control, self.closeup, get_value=wid
   self.closeup_wid=wid
endif
; Start Displays
dispn=size(*self.disps,/n_elements)
for i=0,dispn-1 do begin
   (*self.disps)[i]->start, self
endfor
; activate first infocus display
self.dispinfocus=(*self.disps)[0]
self.dispinfocus->setfocus,1
self.dispinfocus->draw
end

;******************************************************************************
;     CLEANUP - Free pointer heap variables, restore device
;               decomposition state
;******************************************************************************

pro drip_dispman::cleanup
; destroy disp objects
obj_destroy, *self.disps
; reset device
device, decomposed=self.dec_old
end

;****************************************************************************
;     INIT - Initialize structure
;****************************************************************************

function drip_dispman::init, disp_objs, dataman, mouse_active, ibase
;** Get variables
self.analmans=ptr_new(/allocate_heap)
self.disps=ptr_new(/allocate_heap)
*self.disps=disp_objs
self.dataman=dataman
self.upwidget=ibase
device, get_decomposed=dec_old ;save decomposition state
device, decomposed=1
self.dec_old=dec_old
;** Make Dispman Widgets
self.mouse_active=mouse_active
; Info frame: Location and Values widget
if self.mouse_active gt 0 then begin
   imgbase=widget_base(ibase,/row,/frame)
   common gui_os_dependent_values, largefont, smallfont, mediumfont
   infobase=widget_base(imgbase,/column)
   i=widget_label(infobase, value="Location:", /align_left, $
                  font=mediumfont)
   self.location=widget_label(infobase, value="  X=000 Y=000", $
                              /align_left, font=mediumfont, xsize=130)
   i=widget_label(infobase, value="Value:", /align_left, $
                  font=mediumfont)
   self.value=widget_label(infobase, value="  no data", $
                           /align_left, font=mediumfont, xsize=130)
   self.closeup=widget_draw(imgbase, xsize=165, ysize=165, retain=0)
endif
return, 1
end

;****************************************************************************
;     DRIP_DISPMAN__DEFINE
;****************************************************************************

pro drip_dispman__define

struct={drip_dispman, $
       ; other objects
       dataman:obj_new(), $    ; data manager
       analmans:ptr_new(), $   ; array with analysis object managers
       ; display variables
       dispinfocus:obj_new(),$ ; display object currently in focus
       disps:ptr_new(), $      ; array with display objects
       dec_old:0, $            ; old decomposition state (to restore it)
       ; live info variables
       mouse_active:0, $       ; decides if info (x/y/val zoom) available
       location:0L, $          ; widget id of location label
       value:0L, $             ; widget id of value label
       closeup:0L , $          ; widget id of closeup widget
       closeup_wid: 0B, $      ; window id of closeup window
       ; anal object widgets variables
       upwidget:0L ,$          ; base widget for making analysis objects
       inherits drip}          ; need some drip info        
end
