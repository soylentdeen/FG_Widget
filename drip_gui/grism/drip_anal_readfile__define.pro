;****************************************************************************
;     Display - Displays the buffer - doesnt extract
;****************************************************************************
pro drip_anal_readfile::display,event

if keyword_set(*self.owave) then begin
   case self.plot of
      1: begin ;case set as primary or 'P'
         self.xplot->setdata,/no_oplotn
         widget_control,self.disp->getdata(/text), get_value=title
         self.xplot->setdata,title=title
      end
      2: begin ;case set as secondary or 's'
         self.xplot->setdata,/oplotn
      end
      0: ;case set as no plot or ' '
   endcase
   
;color set
   linecolor=self.color[0]+256L*(self.color[1]+256L*self.color[2])
   self.xplot->setdata,linecolor=linecolor
;draw
   self.xplot->draw,*self.owave, *self.oflux, analobj=self
endif ;else self->extraction
end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal_readfile::setwid, wids, title

;** set widget variables
self.title=title ; what will be put in label
self.labelwid=wids.label
self.showwid=wids.show
self.topwid=wids.top
self.plotwid=wids.plot
self.closewid=wids.close
self.colorwid=wids.color
self.displaywid=wids.display
self.coordwid=wids.coordinates

;** set widgets
; label
widget_control, self.labelwid, set_value=self.title
; closewid
widget_control, self.closewid, event_pro='drip_anal_extract_eventhand', $
                set_uvalue={object:self.analman, method:'closeopenanal', $
                            obj:self}
; showwid
widget_control, self.showwid,sensitive=0

; topwid
widget_control, self.topwid, event_pro='drip_anal_extract_eventhand', $
  set_uvalue={object:self, method:'input'}
if self.top then begin
    widget_control, self.topwid, set_value=' X '
endif else begin
    widget_control, self.topwid, set_value='   '
endelse
; plotwid
widget_control, self.plotwid, event_pro='drip_anal_extract_eventhand', $
  set_uvalue={object:self, method:'input'}
;self->setplot,1
; colorwid (color)
;widget_control, self.colorwid, event_pro='drip_anal_extract_eventhand', $
;                        set_uvalue={object:self, method:'input'}, $
;                        set_value=self.color
;extract widget
widget_control, self.displaywid, event_pro='drip_anal_extract_eventhand', $
                        set_uvalue={object:self, method:'display'}

;coordiate widget
;widget_control, self.coordwid, event_pro='drip_anal_extract_eventhand',$
;                        set_uvalue={object:self, method:'coord'}
end

;****************************************************************************
;     INPUT - reacts to user input
;****************************************************************************

pro drip_anal_extract::input, event
; set variables
case event.id of
   self.plotwid:begin
        case self.plot of
            0:self->setplot,1
            1:self->setplot,2
            2:self->setplot,0
        endcase         
     end
   else:
endcase
end
;****************************************************************************
;     SETPLOT - to plot the widget in the extract
;****************************************************************************

pro drip_anal_readfile::setplot, plot
if self.plot ne plot then begin
    self.plot=plot
    case self.plot of
        0:text=' '
        1:text='P'
        2:text='s'
    endcase
    widget_control, self.plotwid, set_value=text
endif
end

;****************************************************************************
;     SETFOCUS - puts object in and out of focus
;****************************************************************************

pro drip_anal_readfile::setfocus, focus
if focus ne self.focus then begin
    self.focus=focus
endif
end

;****************************************************************************
;     ISSHOW - to querry if widget shown if display is not in focus
;****************************************************************************

function drip_anal_readfile::isshow
return, self.show
end

;****************************************************************************
;     ISFOCUS - to querry if widget in focus
;****************************************************************************

function drip_anal_readfile::isfocus
return, self.focus
end


;****************************************************************************
;    SETDATA - to set the data in the object
;****************************************************************************
pro drip_anal_readfile::setdata,owave=owave, oflux=oflux
  if keyword_set(owave) then *self.owave = owave
  if keyword_set(oflux) then *self.oflux = oflux
end


;****************************************************************************
;    GETDATA - to retrive data outside the object
;****************************************************************************
function drip_anal_readfile::getdata, plot=plot, title=ti,$
                                     focus=fo,$
                                     show=show

if keyword_set(ti) then return, self.title
if keyword_set(fo) then return, self.focus
if keyword_set(plot) then return,self.plot
if keyword_set(show) then return,self.show

end


;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal_readfile::init, analman, wid

; same as parent
self.analman=analman
self.xplot=analman.xplot
self.mw=(self.xplot).mw
self.wid=wid
self.plot=1
; get display sizes
; set box size and location (8 pix from border)
self.focus=1
self.oflux=ptr_new(/allocate_heap)
self.owave=ptr_new(/allocate_heap)

return, 1
end

;****************************************************************************
;     DRIP_ANAL_READFILE__DEFINE
;****************************************************************************

pro drip_anal_readfile__define

struct={drip_anal_readfile, $
        $;objects
        xplot:obj_new(), $      ;extraction display
        mw:obj_new(), $         ;message window
        $; widgets
        topwid:0L, $            ; widget id for top indicator
        plotwid:0L, $           ; widget id for plot indicator
        closewid:0L, $          ; widget id for close button
        showwid:0L, $           ; widget id for show button
        colorwid:0L, $          ; widget id for color selector
        displaywid:0L, $        ; widget id for display button
        coordwid:0l,$           ; widget id for coordinate button
        wid:0B, $               ; window id of display
        $; settings
        show:0, $               ; 1 if numbers shown when display not in focus
        plot:0, $               ; 1 if it is plotted in xplot
        owave:ptr_new(),$       ; plotted data
        oflux:ptr_new(),$
        inherits drip_anal} ; child object of drip_anal
end
