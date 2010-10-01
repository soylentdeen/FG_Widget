; NAME:
;     DRIP_ANAL_OPENFILE__DEFINE - Version .6
;
; PURPOSE:
;     Statistics Analysis Objects for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANAL_OPENFILE', MW)
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
;     CLOSEWID - widget id for close button
;     COLORWID - widget id for color selector
;     TEXTWID1 - widget id for text display
;     TEXTWID2 - widget id for text display
;     TEXTWID3 - widget id for text display
;     X0, Y0 - position of lower left corner of frame
;     X1, Y1 - position of upper right corner of frame
;              (legal indices from x0 to x1)
;     COLOR - array for color values
;     WID - window id of display
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_MW020
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
;     Written by: Marc Berthoud, Cornell University, October 2003
;     Modified:   Marc Berthoud, Cornell University, December 2003
;                 Added movable frame in display
;     Modified:   Marc Berthoud, Cornell University, March 2004
;                 Added feature to see frame while moving
;                 Added setwid and getwid to share widgets with
;                   analysis objects from different displays
;                 Added logfile capability
;                 Nirbhik Chitrakar, Ithaca College
;                   converted to extract
;                   logfile removed, 11/2006
;****************************************************************************
;     Display - Displays the buffer - doesnt extract
;****************************************************************************
pro drip_anal_openfile::display,event

if keyword_set(*self.owave) then begin
   case self.plot of
      1: begin ;case set as primary or 'P'
         self.xplot->setdata,/no_oplotn
         self.xplot->setdata,title=file_basename(self.file)
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
endif else self->extraction
end

;****************************************************************************
;     Extract - extraction of selected box
;****************************************************************************

pro drip_anal_openfile::extraction,event

;check validity of box coordinates
if (self.boxx0 lt  self.boxx1-2)  then begin
    data=self.disp->getdata(/dataraw)
    sz=size(*data)
    ;check size of data to see if there is any data to plot
    if (sz[0] gt 0) then begin
        self.extman->newdata,boxx0=self.boxu0, boxy0=self.boxv0,$
          boxx1=self.boxu1, boxy1=self.boxv1,boxx2=self.boxx2,$
          boxy2=self.boxy2, data=data
        self.extman->extract
        ext=self.extman->getdata(/extract)
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
        self.xplot->draw,self.boxx0+findgen(self.boxx1-self.boxx0+1),*ext,$
                         analobj=self
        *self.owave=self.boxx0+findgen(self.boxx1-self.boxx0+1)
        *self.oflux=*ext
        ;message window print
        message='Data extracted from'+ strtrim(string(self.boxu0))$
          +' to'+ strtrim(string(self.boxu1))
        self.mw->print,message
    endif else begin
        self.mw->print,'No Data to extract'
    endelse
endif else begin
    self.mw->print,'Box has to be atleast 2 pixels wide'
endelse

end

;****************************************************************************
;     UPDATE - updates the displayed data
;****************************************************************************

pro drip_anal_openfile::update

; check if in focus
if self.focus or self.show then begin
    ; get data
    ;image=self.disp->getdata(/dataraw)
    ;imgsize=size(*image)
    ;if (imgsize[0] gt 0) then begin ; we have data
        ; check box locations in image (if nesessary change display box)
        ;zoom=self.disp->getdata(/zoom)
        ;if self.boxu0 gt imgsize[1]-2 then self.boxu0=0
        ;if self.boxv0 gt imgsize[2]-2 then self.boxv0=0
        ;if self.boxu1 gt imgsize[1]-1 then self.boxu1=imgsize[1]-1
        ;if self.boxv1 gt imgsize[2]-1 then self.boxv1=imgsize[2]-1
        ; update box positions
        ;self.boxx0=round(float(self.boxu0)*zoom)
        ;self.boxy0=round(float(self.boxv0)*zoom)
        ;self.boxx1=round(float(self.boxu1+1)*zoom)
        ;self.boxy1=round(float(self.boxv1+1)*zoom)
        ;; get sub image
        ;img=(*image)[self.boxu0:self.boxu1,self.boxv0:self.boxv1]
        ;; get extract
        ;image_statistics,img,mean=mean,stddev=stddev, $
        ;                 minimum=min,maximum=max
        ;med=median(img)
        ;npix=long(self.boxu1-self.boxu0+1)*long(self.boxv1-self.boxv0+1)
        ;; display
        ;text=string(mean,med,stddev,min,max,npix, $
        ;            format='(F9.2,F9.2,F9.2,F9.2,F9.2,I6)')
        ;widget_control, self.datawid, set_value=text
    ;endif else begin ; we don't have data
        ;widget_control, self.datawid, set_value='No Data in this Window'
    ;endelse
    ;print,'update'
    ;widget_control, self.colorwid, set_value=self.color
endif
end

;****************************************************************************
;     INPUT - reacts to user input
;****************************************************************************

pro drip_anal_openfile::input, event
; set variables
case event.id of
    self.colorwid:begin
        self.color=event.color
        ;self.disp->draw
    end
    self.topwid:begin
        ; if not on top
        if not self.top then begin
            ; make top and draw
            ;self.disp->settopanal,self
            ;self.disp->draw
        endif
    end
    self.plotwid:begin
        case self.plot of
            0:self->setplot,1
            1:self->setplot,2
            2:self->setplot,0
        endcase         
    end
    self.showwid:begin
        ; if shown
        if self.show then begin
            ; make not shown
            self.show=0
            ; if in focus
            if self.focus then begin
                ; set button
                widget_control, self.showwid, set_value=' '
            endif else begin
                ; erase clear from widgets list
                self.analman->setallwid
                ;redraw display
                ;self.disp->draw
            endelse
        endif else begin
            ; make show and set button
            self.show=1
            widget_control, self.showwid, set_value='X'
            ;self.disp->draw
        endelse
    end
endcase
end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal_openfile::setwid, wids, title

;** set widget variables
self.title=title ; what will be put in label
self.labelwid=wids.label
self.showwid=wids.show
self.topwid=wids.top
self.plotwid=wids.plot
self.closewid=wids.close
self.colorwid=wids.color
self.displaywid=wids.display
self.filewid=wids.coordinates

;** set widgets
; label
widget_control, self.labelwid, set_value=self.title
; closewid
widget_control, self.closewid, event_pro='drip_anal_openfile_eventhand', $
                set_uvalue={object:self.analman, method:'closeopenanal', obj:self}
; showwid
widget_control, self.showwid, event_pro='drip_anal_openfile_eventhand', $
                set_uvalue={object:self, method:'input'}
if self.show then begin
    widget_control, self.showwid, set_value=' X '
endif else begin
    widget_control, self.showwid, set_value='   '
endelse
; topwid
widget_control, self.topwid, event_pro='drip_anal_openfile_eventhand', $
  set_uvalue={object:self, method:'input'}
if self.top then begin
    widget_control, self.topwid, set_value=' X '
endif else begin
    widget_control, self.topwid, set_value='   '
endelse
; plotwid
widget_control, self.plotwid, event_pro='drip_anal_openfile_eventhand', $
  set_uvalue={object:self, method:'input'}
;self->setplot,1
; colorwid (color)

widget_control, self.colorwid, event_pro='drip_anal_openfile_eventhand', $
                        set_uvalue={object:self, method:'input'}, $
                        set_value=self.color
;extract widget
widget_control, self.displaywid, event_pro='drip_anal_openfile_eventhand', $
                        set_uvalue={object:self, method:'display'}
widget_control, self.filewid,set_value=file_basename(self.file)
;coordiate widget
;widget_control, self.coordwid, event_pro='drip_anal_openfile_eventhand',$
;                        set_uvalue={object:self, method:'coord'}
end

;****************************************************************************
;     SETTOP - to set widget on top
;****************************************************************************

pro drip_anal_openfile::settop, top
if self.top ne top then begin
    self.top=top
    if top gt 0 then begin
        text=' X '
    endif else text='   '
    if self.focus gt 0 then widget_control, self.topwid, set_value=text
endif
end

;****************************************************************************
;     SETPLOT - to plot the widget in the extract
;****************************************************************************

pro drip_anal_openfile::setplot, plot
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

pro drip_anal_openfile::setfocus, focus
if focus ne self.focus then begin
    self.focus=focus
endif
end

;****************************************************************************
;     ISSHOW - to querry if widget shown if display is not in focus
;****************************************************************************

function drip_anal_openfile::isshow
return, self.show
end

;****************************************************************************
;     ISFOCUS - to querry if widget in focus
;****************************************************************************

function drip_anal_openfile::isfocus
return, self.focus
end

;****************************************************************************
;    SETDATA - to set the data in the object
;****************************************************************************
pro drip_anal_openfile::setdata,owave=owave, oflux=oflux, file=file
  if keyword_set(owave) then *self.owave = owave
  if keyword_set(oflux) then *self.oflux = oflux
  if keyword_set(file) then begin
     self.file=file
  endif
end

pro drip_anal_openfile::store_multi_order, orders, wave, flux

(*self.extman).orders = orders
for j = 0, n_orders-1 DO BEGIN
    bm = where(im[3,*] eq orders[j])
    (*self.extman).allwave[j] = im[0,bm]
    (*self.extman).allflux[j] = im[1,bm]
ENDFOR


END

;****************************************************************************
;    GETDATA - to retrive data outside the object
;****************************************************************************
function drip_anal_openfile::getdata, plot=plot, title=ti,$
                                     focus=fo, top=to, disp=di,$
                                     show=show

if keyword_set(ti) then return, self.title
if keyword_set(fo) then return, self.focus
if keyword_set(to) then return, self.top
if keyword_set(di) then return, self.disp
if keyword_set(plot) then return,self.plot
if keyword_set(show) then return,self.show

end

;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal_openfile::init, disp, analman, wid

; same as parent
self.disp=disp
self.analman=analman
self.extman=analman.extman
self.mw=(self.extman).mw
self.xplot=analman.xplot
self.xplot_multi=analman.xplot_multi
self.wid=wid
self.top=0
self.plot=1
; get display sizes
xsize=disp->getdata(/xsize)
ysize=disp->getdata(/ysize)
; set box size and location (8 pix from border)
self.focus=1
self.color=[255,0,0]
self.oflux=ptr_new(/allocate_heap)
self.owave=ptr_new(/allocate_heap)

return, 1
end

;****************************************************************************
;     CW Features: EVENTHANDLER
;****************************************************************************

pro drip_anal_openfile_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
end


;****************************************************************************
;     DRIP_ANAL_OPENFILE__DEFINE
;****************************************************************************

pro drip_anal_openfile__define

struct={drip_anal_openfile, $
        $;objects
        extman:obj_new(),$      ;extraction data manager object
        xplot:obj_new(), $      ;extraction display
        xplot_multi:obj_new(), $ ;extraction display for multi-order data
        mw:obj_new(), $         ;message window
        $; widgets
        topwid:0L, $            ; widget id for top indicator
        plotwid:0L, $           ; widget id for plot indicator
        closewid:0L, $          ; widget id for close button
        showwid:0L, $           ; widget id for show button
        colorwid:0L, $          ; widget id for color selector
        displaywid:0L, $        ; widget id for display button
        filewid:0l,$           ; widget id for filename wid
        color:bytarr(3), $      ; array for color values
        wid:0B, $               ; window id of display
        $; settings
        show:0, $               ; 1 if numbers shown when display not in focus
        plot:0, $               ; 1 if it is plotted in xplot
        owave:ptr_new(),$       ; plotted data
        oflux:ptr_new(),$
        file:'',$
        inherits drip_anal} ; child object of drip_anal
end

