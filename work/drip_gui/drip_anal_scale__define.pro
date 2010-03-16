 NAME:
;     DRIP_ANAL_SCALE__DEFINE - Version .7.0
;
; PURPOSE:
;     Color Scaling Analysis Objects for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANAL_SCALE', MW)
;
; INPUTS:
;     MW - Message manager object reference
;
; STRUCTURE:
;     TITLE - object title
;     FOCUS - focus status (1 if in focus else 0)
;     DISPOBJ - display object
;     BASEWID - base widget
;     MW - message window object reference
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_MW
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     In developement
;
; PROCEDURE:
;     Gets called by image manager
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, January 2004
;                  Created from drip_anal_stats__define.pro
;     Modified:    Marc Berthoud, Cornell University, March 2004
;                  Added feature to see frame while moving
;                  Use widgets as passed down by setwid member
;                  function
;     Modified:    Nirbhik Chitrakar, Cornell University, October 2008
;                  Added sigma clipping and percentage
;                  clipping. Basically self->minmaxcalc calculates the
;                  minmax according to which scaling type is
;                  selected. This is called in self->update.
;     Modified:    Marc Berthoud, Yerkes, September 2009
;                  - Consolidated scaling into update and widget
;                    responses into input.
;                  - Added new variables: scaleoption and scalemin/max

;****************************************************************************
;     UPDATE - updates the displayed data
;****************************************************************************

pro drip_anal_scale::update

; set set min, max values
image=self.disp->getdata(/dataraw)
imgsize=size(*image)
if imgsize[0] gt 0 then begin ; we have data
   ; update locations of box in image
   zoom=self.disp->getdata(/zoom)
   self.boxu0=round(float(self.boxx0)/zoom)
   self.boxv0=round(float(self.boxy0)/zoom)
   self.boxu1=round(float(self.boxx1)/zoom)
   self.boxv1=round(float(self.boxy1)/zoom)
   ; check box locations in image (if nesessary change display box)
   if self.boxu0 gt imgsize[1]-2 then self.boxu0=0
   if self.boxv0 gt imgsize[2]-2 then self.boxv0=0
   if self.boxu1 gt imgsize[1]-1 then self.boxu1=imgsize[1]-1
   if self.boxv1 gt imgsize[2]-1 then self.boxv1=imgsize[2]-1
   ; update box positions
   self.boxx0=round(float(self.boxu0)*zoom)
   self.boxy0=round(float(self.boxv0)*zoom)
   self.boxx1=round(float(self.boxu1)*zoom)
   self.boxy1=round(float(self.boxv1)*zoom)
   ; get sub image
   img=(*image)[self.boxu0:self.boxu1,self.boxv0:self.boxv1]
   ; set scalemin/max (according to scaleoption)
   case self.scaleoption of
       'minmax':begin
           if self.minauto gt 0 then self.minval=min(img)
           if self.maxauto gt 0 then self.maxval=max(img)
           self.scalemin=self.minval
           self.scalemax=self.maxval
       end
       'nsigma':begin
           meanval=mean(img,/nan)
           stdval=stddev(img,/nan)*self.nsigval
           self.scalemin = meanval - stdval
           self.scalemax = meanval + stdval
       end
       'percen':begin
           n=n_elements(img)
           sortindex=sort(img)
           noff=fix((100.-self.perval)*n/200, type=13); noff=fix((100.-self.perval)*n/200)
           ;print,n,self.perval,noff 
           self.scalemin=img[sortindex[n-1-noff]]
           self.scalemax=img[sortindex[noff]]
       end
   endcase
   ; check ranges
   if self.scalemax eq self.scalemin then self.scalemax=self.scalemin+1.0
   ; make sure no value is zero (else it won't be forwarded by setdata)
   valrange=self.scalemax-self.scalemin
   ; update display range (need to make sure value passed is ne zero)
   if self.scalemin ne 0 then self.disp->setdata, colormin=self.scalemin $
     else self.disp->setdata, colormin=-valrange/10000.0
   if self.scalemax ne 0 then self.disp->setdata, colormax=self.scalemax $
     else self.disp->setdata, colormax=valrange/10000.0
   self.disp->imagescale
endif else begin
   self.scalemin=0.0
   self.scalemax=0.0
endelse
; put values out if in focus and minmax option is selected
if self.focus eq 1 and self.scaleoption eq 'minmax' then begin
   widget_control, self.mintext, set_value=self.minval
   widget_control, self.maxtext, set_value=self.maxval
   widget_control, self.colorwid, set_value=self.color
endif
end

;****************************************************************************
;     DRAW - draws screen signs
;****************************************************************************

pro drip_anal_scale::draw
; draw box
wset, self.wid
plots, self.boxx0+2, self.boxy0+2, /device
color=self.color[0]+256L*(self.color[1]+256L*self.color[2])
plots, self.boxx1+2, self.boxy0+2, /continue, color=color, /device
plots, self.boxx1+2, self.boxy1+2, /continue, color=color, /device
plots, self.boxx0+2, self.boxy1+2, /continue, color=color, /device
plots, self.boxx0+2, self.boxy0+2, /continue, color=color, /device
end

;****************************************************************************
;     INPUT - reacts to user input
;****************************************************************************

pro drip_anal_scale::input, event
; set variables
case event.id of
   ; N-Sigma Events
   self.nsigtext:begin
      self.nsigval=event.value
      if self.nsigval le 0 then begin
          self.nsigval=0.0001
          widget_control, self.nsigtext, set_value=self.nsigval
      endif
      self->update
      self.disp->draw
   end
   ; Percent Events
   self.pertext:begin
      self.perval=event.value
      if self.perval le 0 then begin
          self.perval=1
          widget_control, self.pertext, set_value=self.perval
      endif
      if self.perval gt 100 then begin
          self.perval=100
          widget_control, self.pertext, set_value=self.perval
      endif
      self->update
      self.disp->draw        
   end
   ; Min / Max Events
   self.maxautoset:begin
       self.maxauto=event.select
       self->update
       self.disp->draw
   end
   self.minautoset:begin
       self.minauto=event.select
       self->update
       self.disp->draw
   end
   self.maxtext:begin
       self.maxval=event.value
       self.maxauto=0
       widget_control, self.maxautoset, set_button=0
       self->update
       self.disp->draw
   end
   self.mintext:begin
       self.minval=event.value
       self.minauto=0
       widget_control, self.minautoset, set_button=0
       self->update
       self.disp->draw
   end
   ; Scale option radio Button Events
   self.minmaxbutton:begin
       if event.select then begin
           widget_control, self.optionbase, /destroy
           self.scaleoption='minmax'
           self->buildgui
           self->update
           self.disp->draw
       endif
   end
   self.nsigmabutton:begin
       if event.select then begin
           widget_control, self.optionbase, /destroy
           self.scaleoption='nsigma'
           self->buildgui
           self->update
           self.disp->draw
       endif
   end
   self.percenbutton:begin
       if event.select then begin
           widget_control, self.optionbase, /destroy
           self.scaleoption='percen'
           self->buildgui
           self->update
           self.disp->draw
       endif
   end
   ; Analobj Events
   self.colorwid:begin
       self.color=event.color
       self.disp->draw
   end
   self.topwid:begin
       if self.top eq 0 then begin
           self.disp->settopanal,self
           self.disp->draw
       endif
   end
   else:
endcase
end

;****************************************************************************
;    GUIControl - controls which guis are displayed
;****************************************************************************

pro drip_anal_scale::guicontrol,event

  ;action only if the button is selected
 if (event.select) then begin
    case event.id of
       self.minmaxbutton:begin
          self->buildgui,'minmax'
       end
       self.nsigmabutton:begin
          self->buildgui,'nsigma'
       end
       self.percenbutton:begin
          self->buildgui,'percen'
       end
    endcase
 endif else begin
    case event.id of
       self.minmaxbutton:begin
          widget_control,self.minmaxbase,/destroy
          self.minmaxbase=-1
       end
       self.nsigmabutton:begin
          widget_control,self.nsigbase,/destroy
          self.nsigbase=-1
       end
       self.percenbutton:begin
          widget_control,self.perbase,/destroy
          self.perbase=-1
       end
    endcase
 endelse

end



;****************************************************************************
;     BUILDGUI - builds option base and fills in values
;****************************************************************************

pro drip_anal_scale::buildgui

 case self.scaleoption of
    'minmax':begin
       ;** Min-Max Scaling
       ; set radio button
       widget_control, self.minmaxbutton, set_button=1
       ; make optionbase
       self.optionbase=widget_base(self.rightbase,/row)
       ; minbase, min widgets (value and auto)
       minbase=widget_base(self.optionbase, /row )
       self.mintext=cw_field(minbase, $
                             title='Min :', /floating, $
                             /return_events,$
                             xsize=5,ysize=3 )
       automin=widget_base(minbase, /column, /nonexclusive)
       self.minautoset=widget_button(automin, value='Auto ' )

       ; maxbase, max widgets (value and auto)
       maxbase=widget_base(self.optionbase, /row )
       self.maxtext=cw_field(maxbase,$
                             title='Max :', /floating,$
                             /return_events,$
                             xsize=5,ysize=3 )
       automax=widget_base(maxbase, /column, /nonexclusive)
       self.maxautoset=widget_button(automax, value='Auto' )

       ; set min / max values
       widget_control, self.mintext, $
                       set_uvalue={object:self, method:'input'}, $
                       set_value=self.minval
       widget_control, self.maxtext, $
                       set_uvalue={object:self, method:'input'}, $
                       set_value=self.maxval
       ; set min/max auto
       widget_control, self.minautoset, $
                       set_uvalue={object:self, method:'input'}
       widget_control, self.minautoset, set_button=self.minauto
       widget_control, self.maxautoset, $
                       set_uvalue={object:self, method:'input'}
       widget_control, self.maxautoset, set_button=self.maxauto
    end
    'nsigma':begin
       ;** N-sigma Scaling
       ; set radio button
       widget_control, self.nsigmabutton, set_button=1
       ; make widgets
       self.optionbase=widget_base(self.rightbase,/row)
       self.nsigtext=cw_field(self.optionbase,$
                              title='N-Sigma :',/floating,$
                              /return_events,$
                              xsize=7,ysize=3)
       ; set N-sigma value
       widget_control, self.nsigtext, $
                       set_uvalue={object:self, method:'input'}, $
                       set_value=self.nsigval
    end
    'percen':begin
       ;** Percentage Scaling
       ; set radio button
       widget_control, self.percenbutton, set_button=1
       ; make widgets
       self.optionbase=widget_base(self.rightbase,/row)
       self.pertext=cw_field(self.optionbase,$
                             title='Percentage :',/floating,$
                             /return_events,$
                             xsize=7,ysize=3) 
       ; set Percent value
       widget_control, self.pertext, $
                       set_uvalue={object:self, method:'input'}, $
                       set_value=self.perval
    end
 endcase
end

;****************************************************************************
;     MOVE - reaction to moving screen sign
;****************************************************************************

function drip_anal_scale::move, xa, ya, xb, yb, final=fin

; u/v is image coordinates, x/y is display coordinates

; get x/y (display coords) values of image boundary (all float)
zoom=self.disp->getdata(/zoom)
imgsize=size(*(self.disp->getdata(/dataraw)))
if imgsize[0] eq 0 then begin
   imgsize=[0,self.disp->getdata(/xsize),self.disp->getdata(/ysize)]
   zoom=1.0
endif
xmin=0.0 ; until I move things around
ymin=0.0
xmax=float(imgsize[1])*zoom-1
ymax=float(imgsize[2])*zoom-1
; get x/y (display coords) values of original box location boxorigx/y0/1
boxorigx0=round(float(self.boxu0)*zoom)
boxorigy0=round(float(self.boxv0)*zoom)
boxorigx1=round(float(self.boxu1+1)*zoom)
boxorigy1=round(float(self.boxv1+1)*zoom)
; set change variable
change=0
if (ya gt boxorigy0-3) and (ya lt boxorigy0+3) then begin
   ; close to bottom line
   if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
       ; bottom left corner -> move left line
       if xb lt boxorigx1 then begin
           ; (make sure the right does not left of the left
           if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
           ; (make sure we're right of the right border of image)
       endif else self.boxx0=boxorigx0
       change=1
   endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
       ; bottom right corner -> move right line
       if xb gt boxorigx0 then begin
           ; (make sure the right does not left of the left
           if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
           ; (make sure we're right of the right border of image)
       endif else self.boxx1=boxorigx1
       change=1
   endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
       ; bottom line -> move bottom line
       change=1
   endif
   if change then begin
       ; move bottom line
       if yb lt boxorigy1 then begin
           ; (make sure the bottom does not go over the top
           if yb gt ymin then self.boxy0=yb else self.boxy0=ymin
           ; (make sure we're above bottom of image)
       endif else self.boxy0=boxorigy0
   endif
endif else if (ya gt boxorigy1-3) and (ya lt boxorigy1+3) then begin
   ; close to top line
   if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
       ; top left corner -> move left line
       if xb lt boxorigx1 then begin
           ; (make sure the right does not left of the left
           if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
           ; (make sure we're right of the right border of image)
       endif else self.boxx0=boxorigx0
       change=1
   endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
       ; top right corner -> move right line
       if xb gt boxorigx0 then begin
           ; (make sure the right does not left of the left
           if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
           ; (make sure we're right of the right border of image)
       endif else self.boxx1=boxorigx1
       change=1
   endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
       ; top line -> move top line
       change=1
   endif
   if change then begin
       ; move top line
       if yb gt boxorigy0 then begin
           ; (make sure the top does not go below the bottom
           if yb lt ymax then self.boxy1=yb else self.boxy1=ymax
           ; (make sure we're below top of image)
       endif else self.boxy1=boxorigy1
   endif
endif else if (ya gt boxorigy0+2) and (ya lt boxorigy1-2) then begin
   ; between top and bottom line
   if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
       ; left line -> change width of box
       if xb lt boxorigx1 then begin
           ; (make sure the right does not left of the left
           if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
           ; (make sure we're right of the right border of image)
       endif else self.boxx0=boxorigx0
       change=1
   endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
       ; right line -> change width of box
       if xb gt boxorigx0 then begin
           ; (make sure the right does not left of the left
           if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
           ; (make sure we're right of the right border of image)
       endif else self.boxx1=boxorigx1
       change=1
   endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
       ; inside -> move box arround
       ; move horizontally
       if xb lt xmin then dx=xmin-xa else if xb gt xmax then dx=xmax-xa $
         else dx=xb-xa
       if boxorigx0+dx gt xmin then self.boxx0=boxorigx0+dx $
         else self.boxx0=xmin
       if boxorigx1+dx lt xmax then self.boxx1=boxorigx1+dx $
         else self.boxx1=xmax
       ; move vertically
       if yb lt ymin then dy=ymin-ya else if yb gt ymax then dy=ymax-ya $
         else dy=yb-ya
       if boxorigy0+dy gt ymin then self.boxy0=boxorigy0+dy $
         else self.boxy0=ymin
       if boxorigy1+dy lt ymax then self.boxy1=boxorigy1+dy $
         else self.boxy1=ymax
       change=1
   endif
endif
if change ne 0 then begin
   ; get new positions in image coordinates boxnewu/v0/1 (round)
   boxnewu0=round(float(self.boxx0)/zoom)
   boxnewv0=round(float(self.boxy0)/zoom)
   boxnewu1=round(float(self.boxx1)/zoom)-1
   boxnewv1=round(float(self.boxy1)/zoom)-1
   ; derive new box postions in display coordinates
   self.boxx0=round(float(boxnewu0)*zoom)
   self.boxy0=round(float(boxnewv0)*zoom)
   self.boxx1=round(float(boxnewu1+1)*zoom)
   self.boxy1=round(float(boxnewv1+1)*zoom)
   if keyword_set(fin) then begin
       ; update data framesize to draw framesize
       self.boxu0=boxnewu0
       self.boxv0=boxnewv0
       self.boxu1=boxnewu1
       self.boxv1=boxnewv1
   endif
   return, 1
endif else return, 0
end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal_scale::setwid, label, colorwid, topwid, $
                            minmaxbutton, nsigmabutton, percenbutton,rightbase

self.labelwid=label
self.colorwid=colorwid
self.topwid=topwid
self.minmaxbutton=minmaxbutton
self.nsigmabutton=nsigmabutton
self.percenbutton=percenbutton
self.rightbase=rightbase

end

;****************************************************************************
;     SETTOP - to set widget on top
;****************************************************************************

pro drip_anal_scale::settop, top
if self.top ne top then begin
   self.top=top
   if top gt 0 then text='X' else text=' '
   if self.focus gt 0 then widget_control, self.topwid, set_value=text
endif
end

;****************************************************************************
;     SETFOCUS - puts object in and out of focus
;****************************************************************************

pro drip_anal_scale::setfocus, focus
if focus ne self.focus then begin
   self.focus=focus
   if focus eq 1 then begin
       ;** If coming in focus
       ;   set up widgets (callback functions, values and uvalues)
       ; set label
       widget_control, self.labelwid, set_value=self.title
       ; set colorwid (color)
       widget_control, self.colorwid, $
                       set_uvalue={object:self, method:'input'}, $
                       set_value=self.color
       ; set topwid
       widget_control, self.topwid, $
                       set_uvalue={object:self, method:'input'}
       if self.top gt 0 then begin
           widget_control, self.topwid, set_value='X'
       endif else begin
           widget_control, self.topwid, set_value=' '
       endelse

       ; radiobuttons
       widget_control,self.minmaxbutton,$
                      set_uvalue={object:self, method:'input'}
       widget_control,self.nsigmabutton,$
                      set_uvalue={object:self, method:'input'}
       widget_control,self.percenbutton,$
                      set_uvalue={object:self, method:'input'}
       ; build option gui
       self->buildgui

   endif else begin
      ;** Loosing focus: destroy variable widgets
      widget_control, self.optionbase, /destroy
   endelse
endif
end

;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal_scale::init, disp, analman, title, wid

; same as parent
self.disp=disp
self.analman=analman
self.title=title
self.wid=wid
self.top=0
; get display sizes
xsize=disp->getdata(/xsize)
ysize=disp->getdata(/ysize)
; set box size and location (8 pix from border)
self.focus=0
self.boxu0=8
self.boxv0=8
self.boxu1=xsize-8
self.boxv1=ysize-8
self.boxx0=self.boxu0
self.boxy0=self.boxv0
self.boxx1=self.boxu1
self.boxy1=self.boxv1
self.color=[0,0,255]
; option settings
self.scaleoption='minmax'
self.minauto=1
self.maxauto=1
return, 1
end

;****************************************************************************
;     DRIP_ANAL_SCALE__DEFINE
;****************************************************************************

pro drip_anal_scale__define

struct={drip_anal_scale, $
       ; widgets
       colorwid:0L, $      ;widget id for color selector
       topwid:0L, $        ;widget id for top widget
       minmaxbutton:0L, $  ;widget id for min-max radio button
       nsigmabutton:0L, $  ;widget id for n-sigma radio button
       percenbutton:0L, $  ;widget id for percent radio button
       rightbase:0L,$      ;widget id for frame with options settings
       optionbase:0L, $    ;widget id for frame with option parameters
       ; minmax option wids
       maxautoset:0L, $    ;widget id of auto selector for max
       minautoset:0L, $    ;widget id of auto selector for min
       maxtext:0L, $       ;widget id of text field with maximum
       mintext:0L, $       ;widget id of text field with minimum
       ; nsigma option wids
       nsigtext:0L,$       ;widget id of text field with n-sigma
       ; percentage option wids
       pertext:0L,$        ;widget id of text field with percentage
       ; current values for options
       minval:0D, $        ;current min value
       maxval:0D, $        ;current max value
       minauto:0, $        ;current setting of minauto
       maxauto:0, $        ;current setting of maxauto
       nsigval:0D,$        ;current nsigma value
       perval:0D, $        ;current percent value
       ; scale value
       scalemin:0D, $      ;current minimal scale
       scalemax:0D, $      ;current maximal scale
       scaleoption:'', $   ;option selection: minmax / nsigma / percen
       ; box characteristics
       boxu0:0, boxv0:0, $ ;box frame positions:   lower left corner
       boxu1:0, boxv1:0, $ ;(in image coordinates) upper right corner
                           ;(legal indices from x0 to x1)
       boxx0:0, boxy0:0, $ ;box frame positions:      lower left corner
       boxx1:0, boxy1:0, $ ;(in display coordinates)  upper right corner
                           ; boxu/v0/1~boxx/y0/1 except when frame moved
       color:bytarr(3), $  ;array for color values
       wid:0B, $           ;window id of display
       inherits drip_anal} ;child object of drip_anal
end