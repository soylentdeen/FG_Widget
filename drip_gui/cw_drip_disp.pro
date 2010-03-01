; NAME:
;     CW_DRIP_DISP - Version .7.0
;
; PURPOSE:
;     Display window compount widget
;
; CALLING SEQUENCE:
;     WidgetID = CW_DRIP_DISP( TOP, INDEX=IN, XSIZE=XS, YSIZE=YS)
;
; INPUTS:
;     TOP - Widget ID of the parent widget.
;     INDEX - Assigned index letter (A-D)
;     XSIZE - X dimension of the display windows
;     YSIZE - Y dimension of the display windows
;
; STRUCTURE:
;     {DRIP_QL, IMAGE, PROCESS, DISPMAN, LABEL, DROP_SUM, SUM, DRAW, WID, DROP_FRAME,
;      FRAME, BUTTON, XSIZE, YSIZE, INDEX}
;     NPIPES - Number of pipes processed
;     DISPIMAGE - Image in display
;     DISPMAN - Display manager
;     LABEL - Label in window
;     DROP_STEP - Step droplist id
;     STEP_SEL - Step droplist selection
;     DROP_SUM - Sum droplist id
;     SUM_SEL - Sum droplist selection ( 0:recent 1:average 2:sum)
;     DRAW - Draw widget id
;     WID - Window id
;     DROP_FRAME - Frame droplist id
;     FRAME_SEL - Frame droplist selection
;     BUTTON - Button widget id
;     XSIZE - X-size
;     YSIZE - Y-size
;     QUAD_ID - Quadrant Identification (input as A-D, stored as 0-3)
;
; OUTPUTS:
;     WidgetID - the widget ID of the top level base of the compound widget.
;
; CALLED ROUTINES AND OBJECTS:
;     SMTV
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     None
;
; PROCEDURE:
;     Create DRIP_QL object.  lay out widgets.  set in motion.
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, 2002
;     Modified:   Alfred Lee, Cornell University, January 2003
;                 Decided to give this version a number
;     Modified:   Alfred Lee, CU, January 30, 2003
;                 Added reset routine.
;     Modified: Marc Berthoud, CU, June 2003
;               Made scaling consistant
;               Added sumimage and npipes variables
;               Put sum/lastimage/average selection, size scaling and
;                 value scaling into refresh -> now draw and drop call refresh
;     Modified: Marc Berthoud, CU, July 2003
;               Changed interface, added management of pipeline steps into
;                 CW window
;               Added drawfits to have a single image drawn
;     Modified: Marc Berthoud, CU, October 2003
;               Changed activity of drop lists
;               Saved drop lists selection in configuration file
;     Modified: Marc Berthoud, CU, December 2003
;               Renamed QL's to DISP's
;               Added mouse interaction
;               Added ability to deal with analysis objects
;     Modified: Marc Berthoud, CU, January 2004
;               Added Variables dataraw dataimg dispimg
;               Split refresh into imageget, imagesetsize,
;               imagesetcolor
;     Modified: Marc Berthoud, CU, March 2004
;               Added feature to see anal_objects while moving
;     Modified: Marc Berthoud, CU, May 2004
;               Moved image selection to drip_anal_select object
;     Modified: Marc Berthoud, CU, Apr 2005
;               Changed imagesetsize and imagesetcolor into imageset
;               Allowed any image and display size and ratio
;               introduced zoom var(double) <1 for shrink >1 for blowup
;     Modified: Marc Berthoud, CU, Nov 2007
;               - renamed imageset->imagescale, imageget->imageset
;               - moved responsibility for managing analysis objects to
;                 drip_analman
;     Modified: Nirbhik Chitrakar, CU, August 2008
;               - added decomposed=0/1 in self->input and self->draw
;                 This is for changing from 24bit color to 8bit for
;                 atv to work properly 

;******************************************************************************
;     RESET - Reset draw window
;******************************************************************************

pro drip_disp::reset
; reset data
widget_control, self.text, set_value='No Data'
*self.dataraw=fltarr(256,256)
*self.dispraw=fltarr(256,256)
*self.dispimg=fltarr(256,256)
; reset all anal objects
for i=0, self.analn-1 do (*self.anals)[i]->reset
; update all anal objects
self->updateanal
; draw window
self->draw
end

;******************************************************************************
;     IMAGESET - Get 2D image data
;                -> dataraw is filled
;******************************************************************************

pro drip_disp::imageset, image, text

; set text
widget_control, self.text, set_value=text
; set image
*self.dataraw=image
; set initial scaleing values
self.colormin=min(image)
self.colormax=max(image)
; call imagesetsize to scale
self->imagescale ; may get called twice if an anal_scale object exists
                 ; must get called now such that analobjs have valid zoom
; update analysis objects
self->updateanal
self->draw
end

;******************************************************************************
;     IMAGESCALE - Scale image to right size and scale image colors
;                    updates analobjects
;                    -> dispimg is filled
;******************************************************************************

pro drip_disp::imagescale

; scale image size to <xsize ysize -> dataimg (the rest gets black)
s=size(*self.dataraw)
; make empty array
dataimg=fltarr(self.xsize,self.ysize)
; scale data, set zoom
if float(s[2])/float(s[1]) lt float(self.ysize)/float(self.xsize) then begin
    ; image fills display width
    dataimg[*,0:self.xsize*s[2]/s[1]-1]= $
      congrid((*self.dataraw), self.xsize, self.xsize*s[2]/s[1])
    self.zoom=float(self.xsize)/float(s[1])
endif else begin
    ; image fills display height
    dataimg[0:self.ysize*s[1]/s[2]-1,*]= $
      congrid((*self.dataraw), self.ysize*s[1]/s[2], self.ysize)
    self.zoom=float(self.ysize)/float(s[2])
endelse
; scale dispimage values (not necessary anymore, was med-stdev..med+stdev)
; scale image
*self.dispimg=!d.table_size*((dataimg)-self.colormin)/ $
              (self.colormax-self.colormin)
*self.dispimg=(*self.dispimg > 0.0)
*self.dispimg=(*self.dispimg < 255.0)
; scale dataimg (all image data with color scaled)
*self.dispraw=!d.table_size*((*self.dataraw)-self.colormin)/ $
              (self.colormax-self.colormin)
*self.dispraw=(*self.dispraw > 0.0)
*self.dispraw=(*self.dispraw < 255.0)

end

;**********************************************************************
;     DRAW - draw display
;**********************************************************************

pro drip_disp::draw
;set 24-bit color indices
device, decomposed=1
; draw border in appropriate color
display=fltarr(self.xsize+4,self.ysize+4)
display[*,*]=self.focus*255.0
; get data
if (size(*self.dispimg))[0] gt 0 then begin
    display[2:self.xsize+1,2:self.ysize+1]=(*self.dispimg)
endif
; display data
wset, self.wid
tv,display
; draw analysis objects
if self.focus gt 0 then begin
    for i=0, self.analn-1 do begin
        if ((*self.anals)[i]->istop()) eq 0 then (*self.anals)[i]->draw
    endfor
    if self.analn gt 0 then self.topanal->draw
endif else begin
    for i=0, self.analn-1 do begin
        if ((*self.anals)[i]->isshow()) gt 0 then (*self.anals)[i]->draw
    endfor
endelse
;set 8-bit color indices
device,decomposed=0
end

;**********************************************************************
;     INPUT - Handle mouse action event
;**********************************************************************

pro drip_disp::INPUT, event
;set 24-bit color indices
device,decomposed=1
case event.type of
    ;** button press (do nothing if not in focus)
    0: begin
        if self.focus gt 0 then begin
            ; look for affected object
            objind=self.analn
            ; check if top anal object
            found=self.topanal->move( event.x-2, $
                  event.y-2, event.x-2, event.y-2)
            ; check for others
            if found then self.mouseanalobj=self.topanal else begin
                while (found eq 0) and (objind gt 0) do begin
                    objind=objind-1
                    found=(*self.anals)[objind]->move( event.x-2, $
                          event.y-2, event.x-2, event.y-2)
                endwhile
                if found then self.mouseanalobj=(*self.anals)[objind]
            endelse
            ; if found
            if found then begin
                ; set variables
                self.mousedown=1
                self.mousex=event.x
                self.mousey=event.y
            endif
        endif
    end
    ;** button release
    1: begin
        ; if in focus
        if self.focus then begin
            ; if one object is under movement
            if self.mousedown then begin
                ; final move (i.e. update frame size for data)
                i=self.mouseanalobj->move(self.mousex-2, self.mousey-2, $
                                          event.x-2, event.y-2, /final)
                ; update object
                self.mouseanalobj->update
                ; top the new object
                self->settopanal, self.mouseanalobj
                ; draw
                self->draw
            endif
        ; else (not in focus) -> set into focus
        endif else begin
            self.dispman->raisedisp, self
        endelse
        self.mousedown=0
    end
    ;** mouse motion
    2: begin
         self.dispman->follow, self, event
        ; check if objectmotion in progress
        if self.mousedown and self.focus then begin
            ; move object
            i=self.mouseanalobj->move(self.mousex-2, self.mousey-2, $
                                      event.x-2, event.y-2)
            ; make data array
            display=fltarr(self.xsize+4,self.ysize+4)
            display[*,*]=255.0
            if ((size(*self.dataraw))[0] gt 0) then begin
                display[2:self.xsize+1,2:self.ysize+1]=(*self.dispimg)
            endif
            ; display data
            wset, self.wid
            tv,display
            ; draw analysis object
            self.mouseanalobj->draw
        endif
    end
    ;** expose event
    4: begin
        self->draw
    end
    ;** character event
    5: begin
        ;print,'*** CHAR Event: press=',event.press,' ch=',event.ch, $
        ;      ' release=',event.release,' mod=',event.modifiers
    end
    ;** key event (non ASCII character)
    6: begin
        ;print,'*** KEY Event: press=',event.press,' key=',event.key, $
        ;      ' release=',event.release,' mod=',event.modifiers
        ; pass event along to anal_objects
        ; (most won't know what todo with it)
        if event.press gt 0 then $
          for i=0,self.analn-1 do (*self.anals)[i]->input,event
    end
endcase
;set 8-bit color indices
device,decomposed=0
end

;**********************************************************************
;     OPENANAL - new analysis object
;**********************************************************************

pro drip_disp::openanal, anal
; add object to list
if self.analn gt 0 then (*self.anals)=[*self.anals,anal] $
  else (*self.anals)=[anal]
; set up object
anal->setfocus, self.focus
; if it's first object make it top object
if self.analn eq 0 then begin
    self.topanal=anal
    anal->settop,1
endif
self.analn++
end

;******************************************************************************
;     CLOSEANAL - close an analysis object
;******************************************************************************

pro drip_disp::closeanal, anal
; find object -> index into i
i=0
while (i lt self.analn) and (anal ne (*self.anals)[i]) do i=i+1
; clear object from list (if found)
if i lt self.analn then begin
    ; !!! assumption here: there will always be AT LEAST ONE analysis object!!!
    if i gt 0 then begin
        if i lt self.analn-1 then $
            *self.anals=[(*self.anals)[0:i-1],(*self.anals)[i+1:self.analn-1]]$
          else *self.anals=[(*self.anals)[0:i-1]]
    endif else *self.anals=[(*self.anals)[1:self.analn-1]]
    self.analn--
    ; if top object cleared, set first object to top
    if anal->istop() then self->settopanal, (*self.anals)[0]
    ; destroy object
    obj_destroy, anal
endif
end

;******************************************************************************
;     UPDATEANAL - updates all analysis objects
;******************************************************************************

pro drip_disp::updateanal

for i=0, self.analn-1 do begin ; only for base and scale widget
    (*self.anals)[i]->update
endfor

end

;******************************************************************************
;     SETTOPANAL - puts analysis object on top
;******************************************************************************

pro drip_disp::settopanal, anal

if anal ne self.topanal then begin
    self.topanal->settop,0
    self.topanal=anal
    self.topanal->settop,1
endif

end

;**********************************************************************
;     SETFOCUS - change display focus (sets for all analobjs)
;**********************************************************************

pro drip_disp::setfocus, focus

if self.focus ne focus then begin
    ; set focus variable
    self.focus=focus
    ; focus analysis objects
    for i=0, self.analn-1 do (*self.anals)[i]->setfocus, focus
endif
end

;******************************************************************************
;     SETDATA - Adjust the SELF structure elements
;******************************************************************************

pro drip_disp::setdata, image=im, dispimg=dimg, $
      colormin=cmin, colormax=cmax, $
      label=la, draw=dr, wid=wid, xsize=xs, ysize=ys, $
      disp_id=id, text=text

if keyword_set(im) then begin
      self.dispimage=im
      self.npipes=1
endif
if keyword_set(dimg) then self.dispimg=dimg
if keyword_set(cmin) then self.colormin=cmin
if keyword_set(cmax) then self.colormax=cmax
if keyword_set(text) then self.text=text
if keyword_set(la) then self.label=la
if keyword_set(dr) then self.draw=dr
if keyword_set(wid) then self.wid=wid
if keyword_set(xs) then self.xsize=xs
if keyword_set(ys) then self.ysize=ys
if keyword_set(id) then self.disp_id=byte(id)-byte('A')

end

;******************************************************************************
;     GETDATA - Return the SELF structure elements
;******************************************************************************

function drip_disp::getdata, $
         dataraw=daraw, dispraw=dpraw, dispimg=dpimg, $
         colormin=cmin, colormax=cmax, $
         text=text, label=la, drop_sum=dpsum, draw=dr, drop_step=dpstep, $
         wid=wid, drop_frame=dpframe, button=bu, $
         xsize=xs, ysize=ys, zoom=zm, $
         frame_sel=framesel, step_sel=stepsel, sum_sel=sumsel, $
         disp_id=id, analn=an, anals=as

if keyword_set(daraw) then return, self.dataraw
if keyword_set(dpraw) then return, self.dispraw
if keyword_set(dpimg) then return, self.dispimg
if keyword_set(cmin) then return, self.cmin
if keyword_set(cmax) then return, self.cmax
if keyword_set(text) then return, self.text
if keyword_set(la) then return, self.label
if keyword_set(dr) then return, self.draw
if keyword_set(wid) then return, self.wid
if keyword_set(xs) then return, self.xsize
if keyword_set(ys) then return, self.ysize
if keyword_set(zm) then return, self.zoom
if keyword_set(id) then return, self.disp_id+byte('A')
if keyword_set(an) then return, self.analn
if keyword_set(as) then return, *self.anals

end

;******************************************************************************
;     START - start the display
;******************************************************************************

pro drip_disp::start, dispman

widget_control, self.draw, get_value=wid
self.dispman=dispman
self.wid=wid

end

;******************************************************************************
;     CLEANUP - destroys the display
;******************************************************************************

pro drip_disp::cleanup

; free pointers
ptr_free, self.dataraw
ptr_free, self.dispraw
ptr_free, self.dispimg
ptr_free, self.anals

end

;******************************************************************************
;     INIT - initialized the display
;******************************************************************************

function drip_disp::init

; allocate memory
self.dataraw=ptr_new(/allocate_heap)
self.dispraw=ptr_new(/allocate_heap)
self.dispimg=ptr_new(/allocate_heap)
self.anals=ptr_new(/allocate_heap)
; set all variables
self.focus=0
self.mousedown=0
self.mousex=0
self.mousey=0
self.zoom=1.0
self.colormin=0.0
self.colormax=1.0
self.analn=0

return, 1
end

;******************************************************************************
;     DRIP_DISP__DEFINE
;******************************************************************************

pro drip_disp__define

struct={drip_disp, $
    ; data variables
    dataraw:ptr_new(), $        ;2D raw image data
    dispraw:ptr_new(), $        ;raw image color scaled (needed for dispman)
    dispimg:ptr_new(), $        ;image in display color scaled & resized
    colormin:0D, $              ;datavalue of black data
    colormax:0D, $              ;datavalue of white data
    ; object variables
    dispman:obj_new(), $        ;display manager
    analn:0, $                  ;number of analysis objects
    anals:ptr_new(), $          ;analysis objects
    topanal:obj_new(), $        ;top analysis object (updated each draw)
    ; widgets and selections
    label:0L, $                 ;label in window
    text:0L, $                  ;label for text
    draw:0L, $                  ;draw widget id
    wid:0B, $                   ;window id - for graphics
    ; mouse action
    mousedown:0, $              ;status of mouse button analobj interaction
                                ; =1 if mouse pressed AND moving an analobj
    mousex:0, mousey:0, $       ;coordinates where mouse pressed down
    mouseanalobj:obj_new(), $   ;analysis object currently being moved
                                ; i.e. treated by mouse
    ; geometry
    xsize:0, $                  ;xsize
    ysize:0, $                  ;ysize
    zoom:0D, $                  ;zoom factor for image >1 zoom up
    ; admin variables
    focus:0, $                  ;focus status (1 if in focus else 0)
    disp_id:0b}                 ;display id (input as A-D, stored as 0-3)

end

;******************************************************************************
;     CW Definition: EVENTHANDLER / CLEANUP / CREATING FUNCTION
;******************************************************************************

pro drip_disp_cleanup, id
widget_control, id, get_uvalue=obj
obj_destroy, obj
end


pro drip_disp_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
end


function cw_drip_disp, top, quad_id=id, xsize=xs, ysize=ys, _extra=ex

obj=obj_new('drip_disp') ;create associated object

; get font string from common block
COMMON gui_os_dependent_values, largefont

;lay out widgets
tlb=widget_base(top, /frame, /column)
;top: label draw
base1=widget_base(tlb, row=1, /align_center, kill_notify='drip_disp_cleanup')
label=widget_label(base1, Value = id, font=largefont, /align_top)
;**** took out /keyboard_events,
draw=widget_draw(base1, xsize=xs+4, ysize=ys+4, _extra=e, $
                 /button_events, /motion_events, /expose_events, retain=0, $
                 keyboard_events=1, $
                 event_pro='drip_disp_eventhand', $
                 uvalue={object:obj, method:'input'})
;center: text
base2=widget_base(tlb, /row, /base_align_top, /align_center)
text=widget_label(base2, value='.           NONE(pipestep[frame])           .' )
     ;, font=largefont)
;populate object 'self' structure
obj->setdata, label=label, text=text, draw=draw, $
      xsize=xs, ysize=ys, disp_id=id
widget_control, base1, set_uvalue=obj ;store object reference in 1st child widget

return, tlb
end
