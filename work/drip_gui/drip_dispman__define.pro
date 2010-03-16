; NAME:
;     DRIP_DISPMAN - Version .7.0
;
; PURPOSE:
;     Image Information Manager for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_DISPMAN', MW)
;
; INPUTS:
;     MW - Message manager object reference
;
; STRUCTURE:
;     MW - message window object reference
;     LOCATION - id of location label
;     VALUE - id of value label
;     CLOSEUP - id of closeup widget
;     CLOSEUP_WID - window id of closeup window
;     DISPINFOCUS - display object currently in focus
;     MOUSEAC - mouse action variable
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_MW
;     CW_DRIP_DISP
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     In developement
;
; PROCEDURE:
;     Gets called by ql event manager - does its magic
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
;**********************************************************************

pro drip_dispman::raisedisp, disp
if disp ne self.dispinfocus then begin
    ; lower display
    self.dispinfocus->setfocus,0
    self.dispinfocus->draw
    ; raise new display
    self.dispinfocus=disp
    self.dispinfocus->setfocus,1
    ; assign new widgets (and update them)
    analmann=size(*self.analmans,/n_elements)
    for i=0, analmann-1 do (*self.analmans)[i]->setallwid
    ; redraw and update standart analysis objects
    self.dispinfocus->draw
endif
end

;**********************************************************************
;     FOLLOW - to update mouse location, value and zoomin
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
    if imgsize[0] gt 0 then begin
        ;** if data is available
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
        ;loctext='   X='+strtrim(string(ximg),2)+ $
        ;  ' Y='+strtrim(string(yimg),2)
        valtext='   '+ strtrim(string(value),2)
        ;** display zoom image
        ; get cursor position
        dispimg=disp->getdata(/dispraw)
        ; set range >16 pix from border
        if ximg lt 16 then xmin=0 else xmin=ximg-16
        if ximg gt imgsize[1]-17 then xmax=imgsize[1]-1 else xmax=ximg+16
        if yimg lt 16 then ymin=0 else ymin=yimg-16
        if yimg gt imgsize[2]-17 then ymax=imgsize[2]-1 else ymax=yimg+16
        ; get and scale
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

;** get variables
*self.analmans=analmans
;** mouse information widget
if self.mouse_active gt 0 then begin
    widget_control, self.closeup, get_value=wid
    self.closeup_wid=wid
endif
;** Start Displays
dispn=size(*self.disps,/n_elements)
for i=0,dispn-1 do begin
    (*self.disps)[i]->start, self
endfor
;** activate first infocus display
self.dispinfocus=(*self.disps)[0]
self.dispinfocus->setfocus,1
self.dispinfocus->draw
end

;******************************************************************************
;     CLEANUP
;******************************************************************************

pro drip_dispman::cleanup
; destroy disp,mw objects
obj_destroy, *self.disps
obj_destroy, self.mw
; reset device
device, decomposed=self.dec_old
end

;****************************************************************************
;     INIT
;****************************************************************************

function drip_dispman::init, disp_objs, mw, dataman, mouse_act, ibase
;** take variables
self.analmans=ptr_new(/allocate_heap)
self.disps=ptr_new(/allocate_heap)
*self.disps=disp_objs
self.mw=mw
self.dataman=dataman
device, get_decomposed=dec_old ;save decomposition state
device, decomposed=1
self.dec_old=dec_old
;** Dispman Widgets
;self.mouse_active=1
self.mouse_active=mouse_act
; Info frame: Location and Values widget
if self.mouse_active gt 0 then begin
    imgbase=widget_base(ibase,/row,/frame)
    common gui_os_dependent_values, largefont, smallfont
    infobase=widget_base(imgbase,/column)
    i=widget_label(infobase, value="Location:", /align_left, $
                   font=largefont)
    self.location=widget_label(infobase, value="  X=000 Y=000", $
                               /align_left, font=largefont, xsize=130)
    i=widget_label(infobase, value="Value:", /align_left, $
                   font=largefont)
    self.value=widget_label(infobase, value="  no data", $
                            /align_left, font=largefont, xsize=130)
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
        mw:obj_new(), $         ; message window object
        dataman:obj_new(), $    ; data manager
        analmans:ptr_new(), $   ; array with analysis object managers
        ; display variables
        dispinfocus:obj_new(),$ ; display object currently in focus
        disps:ptr_new(), $      ; display objects
        dec_old:0, $            ;old decomposition state (to restore it)
        ; live info variables
        mouse_active:0, $       ; decides if info (x/y/val zoom) available
        location:0L, $          ; id of location label
        value:0L, $             ; id of value label
        closeup:0L , $          ; id of closeup widget
        closeup_wid: 0B, $      ; window id of closeup window
                                ; anal object widgets variables
        ; widget IDs
        upwidget:0L}            ; base widget for making analysis objects
end

;****************************************************************************
;****************************************************************************
;
;     CODE FROM VERSION 6.1
;
;****************************************************************************
;****************************************************************************

pro dontusethiscode
;****** Unused Variables
       extwidget:0L,$   ; base widget for extraction analysis objects
         ; analysisobjects
        anal_active:ptr_new(),$ ; array list of active variable number
        ; extract anal objects variables
        extract_wids:ptr_new(),$ ; pointer to widget list for anal extract objs
        ; first entry has column id
        extract_new:0L,$        ; button_id for "create extract object"
        extract_ext:0L, $       ; button_id for extracting
        extract_multi:0L, $     ; button_id for multiple order mode
        extract_sa:0L,$         ; button id for save ascii
        extract_sf:0L,$         ; button id for save fits
        extract_sps:0L,$        ; button id for save postscript
        extract_ra:0L,$         ; button id for read ascii
        extract_rf:0L,$         ; button id for read fits
        ; spectral extration displays
        disp_ext:obj_new(), $   ; plot display
        xplot_multi:obj_new(),$ ; cross-dispersed multiple order mode
        extman:obj_new() }      ; extract manager


;****** from dispman::init
self.disp_ext=disp_ext
self.extman=extman
if ebase ne ibase then self.extwidget=widget_base(ebase,/column,/frame) $
  else ebase=ibase
;*self.anal_active=['drip_anal_stats','drip_anal_point']
self.extract_wids=ptr_new(/allocate_heap)
;****** from dispman::cleanup
ptr_free, self.extract_wids
;****** from dispman::start
;** Anal Objects Widgets
self.upwidget=widget_base(ibase,/column,/frame)
;**** create a general analysis object for each display
common gui_os_dependent_values, largefont, smallfont
;**** create anal_stats and anal_point objects list
; (make and break analobj just to make sure things have been compiled)
; extract widgets
if total(where(*self.anal_active eq 'drip_anal_extract')) ge 0.0 then begin
    analobj=obj_new('drip_anal_extract', self.mw, self.disp_objs[0], self, 0)
    *self.extract_wids=analobj->setup(self.extwidget)
    self.extract_new=(*self.extract_wids)[0].ext.new
    self.extract_ext=(*self.extract_wids)[0].ext.extract
    self.extract_multi=(*self.extract_wids)[0].ext.multi
    obj_destroy,analobj
    widget_control, self.extract_new, event_pro='drip_eventhand', $
      set_uvalue={object:self, method:'create'}
    widget_control, self.extract_ext, event_pro='drip_eventhand', $
      set_uvalue={object:self, method:'extract'}
    widget_control, self.extract_multi, event_pro='drip_eventhand',$
      set_uvalue={object:self, method:'multi_order'}
endif
;**** run assignwids for all
for i=0, (size(*self.anal_active))[1]-1 do $
  self->assignwid,(*self.anal_active)[i]

end

;****************************************************************************
;     ASSIGNWID - return widgets to an analysis object
;                 only for variable number widgets (stats, point, extract)
;****************************************************************************

pro drip_dispman::assignwid

; deactivate update for upwid
widget_control, self.upwidget, update=0
; make a temp object
analobj=obj_new(analtype, self.mw, self.disp_objs[0], self, 0)
allobjs=[analobj]
; get all objects of that type
for dispi=0,self.dispn-1 do begin
    dispobjs=self.disp_objs[dispi]->getdata(/analobjs)
    dispobjn=self.disp_objs[dispi]->getdata(/analobjn)
    for dispobji=0,dispobjn-1 do begin
        if analtype eq strlowcase(obj_class(dispobjs[dispobji])) then $
            allobjs=[allobjs,dispobjs[dispobji]]
    endfor
endfor
; call setwid for all objects
allobjn=(size(allobjs))[1]
if analtype eq 'drip_anal_stats' then begin
    analobj->setallwid, allobjs, self.stats_wids
endif
if analtype eq 'drip_anal_point' then begin
    analobj->setallwid, allobjs, self.point_wids
endif
if analtype eq 'drip_anal_extract' then begin
    analobj->setallwid, allobjs, self.extract_wids
endif
; reactivate update for upwid
widget_control, self.upwidget, update=1
; update all widgets
if allobjn gt 1 then begin
    for i=1,allobjn-1 do begin
        allobjs[i]->update
    endfor
endif
; destroy temp object
obj_destroy,analobj
end

;****************************************************************************
;     CREATE - process a button event to create a analysis object
;****************************************************************************

pro drip_dispman::create, event
wid=self.dispinfocus->getdata(/wid)
if event.id eq self.stats_new then begin
    analobj=obj_new('drip_anal_stats', self.mw, self.dispinfocus, self, wid)
endif else if event.id eq self.point_new then begin
    analobj=obj_new('drip_anal_point', self.mw, self.dispinfocus, self, wid)
endif else if event.id eq self.extract_new then begin
    analobj=obj_new('drip_anal_extract', self.mw, self.dispinfocus, self, wid)
endif
self.dispinfocus->openanal, analobj ; also gets new wigets by setting focus
self->assignwid, strlowcase(obj_class(analobj))
self.dispinfocus->draw
end

;****************************************************************************
;     Extract_multi: extract multiple orders
;****************************************************************************

pro drip_dispman::multi_order,event
data=self.dispinfocus->getdata(/dataraw)
if keyword_set(*data) then begin
    self.extman->newdata,data=data
    self.extman->multi_order
    orders=self.extman->getdata(/orders)
    
    ;xplot_multi=cw_xplot_multi(self.disp_ext->getdata(/xzoomplot_base),$
    ;                           mw=self.mw,orders=orders,extman=self.extman,$
    ;                           xsize=640,ysize=480)
    id=widget_info(xplot_multi,/child)
    widget_control,id,get_uvalue=obj
    self.xplot_multi=obj

    self.xplot_multi->start,self

    self.xplot_multi->draw,/all
endif

end

;****************************************************************************
;     Extract - extraction of all selected anal obj
;****************************************************************************
pro drip_dispman::extract,event
;if there are extract objects
if (n_elements(*self.extract_wids) gt 1) then begin
    ;array of references to the extract anal objects
    extanalobjs=objarr(20)
    ;number of extract objects
    x=0
    ;check all displays for extract objects
    for i=0,self.dispn-1 do begin
        num=self.disp_objs[i]->getdata(/analobjn)
        analobjs=self.disp_objs[i]->getdata(/analobjs)
        for n=0,num-1 do begin
            if (strlowcase(obj_class(analobjs[n]) )eq 'drip_anal_extract') $
              then begin
                extanalobjs[x]=analobjs[n]
                x=x+1
            endif
        endfor
    endfor
    
    
                                ;Note: if there are more than 1 set to
                                ;primary, it takes the first one and
                                ;plots the other secondary ones, ie it
                                ;doesnt plot the other objects set as
                                ;primary
    ;index value that is incremented for while loop
    n=0
    plot=0
    ;check for extract objects set for primary plot
    while((n ne x) and (plot ne 1)) do begin
        plot=extanalobjs[n]->getdata(/plot)
        n=n+1
        print,n,x
    endwhile
    n=n-1;ends up being one bigger than the one we need
    ;check to see if none are set to primary
    if (n lt x) then begin
        extanalobjs[n]->extraction,event
        for i=0,x-1 do begin
            if(extanalobjs[i]->getdata(/plot) eq 2) then begin
                extanalobjs[i]->extraction,event
            endif
        endfor
    endif else begin
        self.mw->print,'At least one must be primary'
    endelse
endif
end
