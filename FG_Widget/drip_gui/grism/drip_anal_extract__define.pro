; NAME:
;     DRIP_ANAL_EXTRACT__DEFINE - Version .6
;
; PURPOSE:
;     Statistics Analysis Objects for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANAL_EXTRACT', MW)
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
pro drip_anal_extract::display,event
device,decomposed=1
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
endif else self->extraction
device,decomposed=0
end
;****************************************************************************
;     CheckPoints - Check validity of points for Coordinate method
;                    a sub function for self->coord
;****************************************************************************
function drip_anal_extract::checkPoints,textx,texty,h
good = 1
;x0
if textx(0) lt 0 then good=0
if textx(0) gt 256 then good=0
if textx(0) gt textx(1) then good=0
;x2
if textx(1) lt 0 then good=0
if textx(1) gt 256 then good=0
if textx(1) lt textx(0) then good=0
;y0
if texty(0) lt 0 then good=0
if texty(0) gt 256 then good=0
;y2
if texty(1) lt 0 then good=0
if texty(1) gt 256 then good=0

if h lt 2 then good=0

return,good

end


;****************************************************************************
;     Coordinate - coordinates for the box
;****************************************************************************

pro drip_anal_extract::coord, event

widget_control,event.id,get_value=value

case value of
    'Coordinates':begin
        ;base
        base=widget_base(Group_leader=self.labelwid,$
                         /column, title='Enter Coordinates',$
                         /base_align_center,xsize=250)
        baseInput=widget_base(base,/row)
        baseLabel=widget_base(baseInput,/column,$
                              /base_align_left)
        baseText=widget_base(baseInput,/column)

        ;bottom-left point
        label0=widget_label(baseLabel, value='Bottom-left:',ysize=35)
        base0=widget_base(baseText,/row)
        textx0=widget_text(base0, /editable,xsize=4,$
                           value=strcompress(string(self.boxx0)))
        texty0=widget_text(base0, /editable, xsize=4,$
                           value=strcompress(string(self.boxy0)),$
                           event_pro='drip_anal_extract_eventhand',$
                           uvalue={object:self, method:'coord'})
        ;bottom-right point
        label2=widget_label(baseLabel, value='Bottom-right:',ysize=35)
        base2=widget_base(baseText,/row)
        textx2=widget_text(base2, /editable,xsize=4,$
                           value=strcompress(string(self.boxx2)))
        texty2=widget_text(base2,/editable,xsize=4,$
                           value=strcompress(string(self.boxy2)),$
                           event_pro='drip_anal_extract_eventhand',$
                           uvalue={object:self, method:'coord'})
        ;top-right point
        labelh=widget_label(baseLabel, value='Height:',ysize=35)
        baseh=widget_base(baseText,/row)
        texth=widget_text(baseh,/editable,xsize=4,$
                          value=strcompress(string(self.boxy1-self.boxy2)),$
                          event_pro='drip_anal_extract_eventhand',$
                          uvalue={object:self, method:'coord'})

        ;Buttons
        baseBut=widget_base(base,/row,/base_align_center)
        ok=widget_button(baseBut, value='OK',xsize=50,$
                         event_pro='drip_anal_extract_eventhand',$
                         uvalue={object:self, method:'coord'})
        cancel=widget_button(baseBut, value='Cancel',xsize=50,$
                             event_pro='drip_anal_extract_eventhand',$
                             uvalue={object:self, method:'coord'})
        ;realize
        widget_control,base,/Realize
        ;store them in object structure
        self.cobase=base
        self.cotextx0=textx0
        self.cotexty0=texty0
        self.cotextx2=textx2
        self.cotexty2=texty2
        self.cotexth=texth
        ;Xmanager
        Xmanager,'coord',self.cobase
    end
    'OK':begin
        widget_control,self.cotextx0,get_value=textx0
        widget_control,self.cotexty0,get_value=texty0
        widget_control,self.cotextx2,get_value=textx2
        widget_control,self.cotexty2,get_value=texty2
        widget_control,self.cotexth,get_value=texth
        textx=[fix(textx0),fix(textx2)]
        texty=[fix(texty0),fix(texty2)]
        texth=fix(texth)

        ;check validity of coordinates and height
        valid=self->checkPoints(textx,texty,texth)
        if (valid) then begin
            widget_control,self.cobase,/destroy
            ;update box coordinates in image coordinates
            self.boxu0=textx(0)
            self.boxv0=texty(0)
            self.boxu2=textx(1)
            self.boxv2=texty(1)
            self.boxu1=textx(1)
            self.boxv1=texty(1)+texth
            self.boxu3=textx(0)
            self.boxv3=texty(0)+texth
            ;update box coordinates in display coordinates
            zoom=self.disp->getdata(/zoom)
            self.boxx0=round(float(self.boxu0)*zoom)
            self.boxy0=round(float(self.boxv0)*zoom)
            self.boxx1=round(float(self.boxu1)*zoom)
            self.boxy1=round(float(self.boxv1)*zoom)
            self.boxx2=round(float(self.boxu2)*zoom)
            self.boxy2=round(float(self.boxv2)*zoom)
            self.boxx3=round(float(self.boxu3)*zoom)
            self.boxy3=round(float(self.boxv3)*zoom)

            self->update
            self.disp->settopanal,self
            self.disp->draw
        endif else begin
            message=dialog_message('Invalid Coordinates',/Error,title='Error')
        endelse

    end
    'Cancel':begin
        widget_control,self.cobase,/destroy
    end

    else:begin
        print,'event.type =',event.type
    end

endcase

end

;****************************************************************************
;     Extract - extraction of selected box
;****************************************************************************

pro drip_anal_extract::extraction,event

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

pro drip_anal_extract::update

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
    widget_control, self.colorwid, set_value=self.color
endif
end

;****************************************************************************
;     DRAW - draws screen signs
;****************************************************************************

pro drip_anal_extract::draw

device,decomposed=1
; draw box
wset, self.wid
plots, self.boxx0+2, self.boxy0+2, /device
color=self.color[0]+256L*(self.color[1]+256L*self.color[2])
plots, self.boxx2+2, self.boxy2+2, /continue, color=color, /device
plots, self.boxx1+2, self.boxy1+2, /continue, color=color, /device
plots, self.boxx3+2, self.boxy3+2,$
  /continue, color=color, /device
plots, self.boxx0+2, self.boxy0+2, /continue, color=color, /device

device,decomposed=0
end

;****************************************************************************
;     INPUT - reacts to user input
;****************************************************************************

pro drip_anal_extract::input, event
; set variables
case event.id of
    self.colorwid:begin
        self.color=event.color
        self.disp->draw
    end
    self.topwid:begin
        ; if not on top
        if not self.top then begin
            ; make top and draw
            self.disp->settopanal,self
            self.disp->draw
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
                self.disp->draw
            endelse
        endif else begin
            ; make show and set button
            self.show=1
            widget_control, self.showwid, set_value='X'
            self.disp->draw
        endelse
    end
endcase
end

;****************************************************************************
;     MOVE - reaction to moving screen sign
;****************************************************************************

function drip_anal_extract::move, xa, ya, xb, yb, final=fin

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
boxorigx1=round(float(self.boxu1)*zoom)
boxorigy1=round(float(self.boxv1)*zoom)
boxorigx2=round(float(self.boxu2)*zoom)
boxorigy2=round(float(self.boxv2)*zoom)
boxorigx3=round(float(self.boxu3)*zoom)
boxorigy3=round(float(self.boxv3)*zoom)
boxorigslope=float(boxorigy2-boxorigy0)/float(boxorigx2-boxorigx0)
; set change variable
change=0
if (ya gt boxorigy0-3) and (ya lt boxorigy0+3) and $
  (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
    ;******* bottom left corner -> move left line*********
    ; (make sure left edge stays left of right edge)
    if (xb lt boxorigx2) then begin
    ; (make sure left edge stays right of right border of image)
        if (xb gt xmin) then begin
            self.boxx0=xb
            self.boxx3=xb
        endif else begin
            self.boxx0=xmin
            self.boxx3=xmin
        endelse

    endif else begin
        self.boxx0=boxorigx0
        self.boxx3=boxorigx3
    endelse
    change=1
    if change then begin
    ; move bottom line
    ; (make sure bottom edge stays below top edge)
        if (yb lt boxorigy3+2) then begin
        ; (make sure bottom edge stays above bottom of image)
            if (yb gt ymin) and ((yb-boxorigy0+boxorigy2) gt ymin)$
              then begin
                self.boxy2= self.boxy2 + (yb-self.boxy0)
                self.boxy0=yb
            endif else if (yb lt ymin) and $
              ((yb-boxorigy0+boxorigy2) lt ymin) then begin
                if (boxorigy2 gt boxorigy0) then begin
                    self.boxy0=ymin
                endif else begin
                    self.boxy2=ymin
                endelse
            endif

        endif else begin
            self.boxy0=boxorigy0
            self.boxy2=boxorigy2
        endelse
    endif
endif else if (ya gt boxorigy2-3) and (ya lt boxorigy2+3) and $
  (xa gt boxorigx2-3) and (xa lt boxorigx2+3) then begin
        ;******** bottom right corner -> move right line***********
        ; (make sure right edge stays right of left edge)
    if (xb gt boxorigx0) then begin
            ; (make sure right edge stays left of right border of image)
        if (xb lt xmax) then begin
            self.boxx1=xb
            self.boxx2=xb
        endif else begin
            self.boxx1=xmax
            self.boxx2=xmax
        endelse
    endif else begin
        self.boxx1=boxorigx1
        self.boxx2=boxorigx2
    endelse
    change=1
    ;endif else if (xa gt boxorigx0+2) and (xa lt boxorigx2-2) then begin
        ; bottom line -> move bottom line
    ;    change=1
    if change then begin
    ; move bottom line
    ; (make sure bottom edge stays below top edge)
        if (yb lt boxorigy1+2) then begin
        ; (make sure bottom edge stays above bottom of image)
            if (yb gt ymin) and ((yb-boxorigy2+boxorigy0) gt ymin)$
              then begin
                self.boxy0= self.boxy0 + (yb-self.boxy2)
                self.boxy2=yb
            endif else if (yb lt ymin) and $
              ((yb-boxorigy2+boxorigy0) lt ymin) then begin
                if (boxorigy2 gt boxorigy0) then begin
                    self.boxy0=ymin
                endif else begin
                    self.boxy2=ymin
                endelse
            endif
        endif else begin
            self.boxy0=boxorigy0
            self.boxy2=boxorigy2
        endelse
    endif
endif else if (ya gt boxorigy3-3) and (ya lt boxorigy3+3) and $
  (xa gt boxorigx3-3) and (xa lt boxorigx3+3) then begin
    ;******* top left corner -> move left line*********
    ; (make sure left edge stays left of right edge)
    if xb lt boxorigx1 then begin
        ; (make sure left edge stays right of left border of image)
        if xb gt xmin then begin
            self.boxx0=xb
            self.boxx3=xb
        endif else begin
            self.boxx0=xmin
            self.boxx3=xmin
        endelse
    endif else begin
        self.boxx0=boxorigx0
        self.boxx3=boxorigx3
    endelse
    change=1
    if change then begin
        ; move top line
        ; (make sure top edge stays above bottom edge)
        if (yb gt boxorigy0+2) then begin
            ; (make sure top edge stays below top of image)
            if (yb lt ymax) and ((yb+boxorigy1-boxorigy3) lt ymax) $
              then begin
                self.boxy1= self.boxy1+(yb-self.boxy3)
                self.boxy3=yb
            endif else if (yb gt ymax) or $
              ((yb+boxorigy1-boxorigy3) gt ymax) then begin
                if (boxorigy1 gt boxorigy3) then self.boxy1=ymax else $
                  self.boxy3=ymax
            endif
        endif else begin
            self.boxy3=boxorigy3
            self.boxy1=boxorigy1
        endelse
    endif

endif else if (ya gt boxorigy1-3) and (ya lt boxorigy1+3) and $
  (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
    ;************ top right corner -> move right line************
    ; (make sure right edge stays right of left edge)
    if xb gt boxorigx0 then begin
            ; (make sure right edge stays left of right border of image)
        if xb lt xmax then begin
            self.boxx1=xb
            self.boxx2=xb
        endif else begin
            self.boxx1=xmax
            self.boxx2=xmax
        endelse
    endif else begin
        self.boxx1=boxorigx1
        self.boxx2=boxorigx2
    endelse
    change=1
   ; endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
        ; top line -> move top line
   ;     change=1
    if change then begin
        ; move top line
        ; (make sure top edge stays above bottom edge)
        if (yb gt boxorigy2+2) then begin
        ; (make sure top edge stays below top of image)
            if (yb lt ymax) and ((yb+boxorigy3-boxorigy1) lt ymax)$
              then begin
                self.boxy3=self.boxy3+(yb-self.boxy1)
                self.boxy1=yb
            endif else if (yb gt ymax) or $
              ((yb+boxorigy3-boxorigy1) gt ymax) then begin
                if (boxorigy1 gt boxorigy3) then self.boxy1=ymax else $
                  self.boxy3=ymax
            endif
        endif else begin
            self.boxy3=boxorigy3
            self.boxy1=boxorigy1
        endelse
    endif
endif else if ((ya gt boxorigy0+2) and (ya lt boxorigy3-2))and $
  (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
        ; left line -> change width of box
        ; (make sure left edge stays left of right edge)
    dy3=boxorigy3-ya
    dy0=ya-boxorigy0
    if xb lt boxorigx1 then begin
        ; (make sure left edge stays right of left border of image)
        if xb gt xmin then begin
            self.boxx0=xb
            self.boxx3=xb
        endif else begin
            self.boxx0=xmin
            self.boxx3=xmin
        endelse
    endif else begin
        self.boxx0=boxorigx0
        self.boxx3=boxorigx3
    endelse
    change=1
    if (yb-dy0 gt ymin) and (yb+dy3 lt ymax) then begin
        self.boxy0=yb-dy0
        self.boxy3=yb+dy3
    endif
endif else if ((ya gt boxorigy2+2) and (ya lt boxorigy1-2))and (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; right line -> change width of box
        ; (make sure right edge stays right of left edge)
    dy1=boxorigy1-ya
    dy2=ya-boxorigy2
    if xb gt boxorigx0 then begin
            ; (make sure right edge stays left of right border of image)
        if xb lt xmax then begin
            self.boxx1=xb
            self.boxx2=xb
        endif else begin
            self.boxx1=xmax
            self.boxx2=xmax
        endelse
    endif else begin
        self.boxx1=boxorigx1
        self.boxx2=boxorigx2
    endelse
    change=1
    if (yb-dy2 gt ymin) and (yb+dy1 lt ymax) then begin
        self.boxy1=yb+dy1
        self.boxy2=yb-dy2
    endif
endif else if (xa gt boxorigx3+3) and (xa lt boxorigx1-3) and $
  (ya lt (boxorigy3 + float(xa-boxorigx3)*boxorigslope)+3) and $
  (ya gt (boxorigy3 + float (xa-boxorigx3)*boxorigslope)-3) then begin
    ;************top line -> move top line************
    if (yb lt ymin) then dy=ymin-ya else if (yb gt ymax) then dy=ymax-ya $
    else dy=yb-ya
    if (boxorigy3+dy gt boxorigy0+2) then begin
         ; (make sure top edge stays below top of image)
         if (boxorigy3+dy lt ymax) and ((boxorigy1+dy) lt ymax)$
           then begin
             self.boxy3=boxorigy3+dy
             self.boxy1=boxorigy1+dy
         endif else if (boxorigy3+dy gt ymax) or $
           (boxorigy1+dy gt ymax) then begin
             dytop=ymax-max([boxorigy1,boxorigy3])
             self.boxy1=boxorigy1+dytop
             self.boxy3=boxorigy3+dytop
         endif else begin
             self.boxy3=boxorigy3
             self.boxy1=boxorigy1
         endelse
     endif
     change=1
endif else if (xa gt boxorigx0+3) and (xa lt boxorigx2-3) and $
  (ya lt (boxorigy0 + float(xa-boxorigx0)*boxorigslope)+3) and $
  (ya gt (boxorigy0 + float (xa-boxorigx0)*boxorigslope)-3) then begin
    ;************bottom line -> move bottom line************
    if (yb lt ymin) then dy=ymin-ya else if (yb gt ymax) then dy=ymax-ya $
    else dy=yb-ya
    if (boxorigy0+dy lt boxorigy3-2) then begin
         ; (make sure bottom edge stays above bottom of image)
         if (boxorigy0+dy gt ymin) and ((boxorigy2+dy) gt ymin)$
           then begin
             self.boxy0=boxorigy0+dy
             self.boxy2=boxorigy2+dy
         endif else if (boxorigy0+dy lt ymin)or $
           (boxorigy2+dy lt ymin) then begin
             dybottom=ymin-min([boxorigy2,boxorigy0])
             self.boxy2=boxorigy2+dybottom
             self.boxy0=boxorigy0+dybottom
         endif else begin
             self.boxy0=boxorigy0
             self.boxy2=boxorigy2
         endelse
     endif
     change=1
 endif else if (xa gt boxorigx0+3) and (xa lt boxorigx1-3) and $
   (ya lt (boxorigy3 + float(xa-boxorigx3)*boxorigslope)-3) and $
   (ya gt (boxorigy0 + float(xa-boxorigx0)*boxorigslope)+3) then begin
    ; inside -> move box arround
    ; move horizontally
    if (xb lt xmin) then dx=xmin-xa else if (xb gt xmax) then dx=xmax-xa $
    else dx=xb-xa
    if (boxorigx0+dx gt xmin) then begin
        self.boxx0=boxorigx0+dx
        self.boxx3=boxorigx3+dx
        self.boxx2=boxorigx2+dx
        self.boxx1=boxorigx2+dx
    endif else begin
        self.boxx0=xmin
        self.boxx3=xmin
    endelse
    if (boxorigx1+dx lt xmax) then begin
        self.boxx1=boxorigx1+dx
        self.boxx2=boxorigx2+dx
    endif else begin
        self.boxx1=xmax
        self.boxx2=xmax
    endelse
    ; move vertically
    if (yb lt ymin) then dy=ymin-ya else if (yb gt ymax) then dy=ymax-ya $
    else dy=yb-ya
    ; move bottom points
    if (boxorigy0+dy lt ymin) or (boxorigy2+dy lt ymin) then begin
        ; bottom points hit window bottom
        dybottom=ymin-min([boxorigy0,boxorigy2])
        self.boxy0=boxorigy0+dybottom
        self.boxy2=boxorigy2+dybottom
    endif else if (boxorigy0+dy gt ymax-2) or $
    (boxorigy2+dy gt ymax-2) then begin
        ; bottom points hit window top-2
        dybottom=ymax-2-max([boxorigy0,boxorigy2])
        self.boxy0=boxorigy0+dybottom
        self.boxy2=boxorigy2+dybottom
    endif else begin
        ; move bottom points
        self.boxy0=boxorigy0+dy
        self.boxy2=boxorigy2+dy
    endelse
    ; move top points
    if (boxorigy1+dy gt ymax) or (boxorigy3+dy gt ymax) then begin
       ;top points hit window top
        dytop=ymax-max([boxorigy1,boxorigy3])
        self.boxy1=boxorigy1+dytop
        self.boxy3=boxorigy3+dytop
    endif else if (boxorigy1+dy lt ymin+2) or $
    (boxorigy3+dy lt ymin+2) then begin
        ;top points hit window bottom+2
        dytop=ymin-min([boxorigy1,boxorigy3])+2
        self.boxy1=boxorigy1+dytop
        self.boxy3=boxorigy3+dytop
    endif else begin
        ;move top points
        self.boxy1=boxorigy1+dy
        self.boxy3=boxorigy3+dy
    endelse
    change=1
endif

if change ne 0 then begin
    ; get new positions in image coordinates boxnewu/v0/1 (round)
    boxnewu0=round(float(self.boxx0)/zoom)
    boxnewv0=round(float(self.boxy0)/zoom)
    boxnewu1=round(float(self.boxx1)/zoom)
    boxnewv1=round(float(self.boxy1)/zoom)
    boxnewu2=round(float(self.boxx2)/zoom)
    boxnewv2=round(float(self.boxy2)/zoom)
    boxnewu3=round(float(self.boxx3)/zoom)
    boxnewv3=round(float(self.boxy3)/zoom)
    ; derive new box postions in display coordinates
    self.boxx0=round(float(boxnewu0)*zoom)
    self.boxy0=round(float(boxnewv0)*zoom)
    self.boxx1=round(float(boxnewu1)*zoom)
    self.boxy1=round(float(boxnewv1)*zoom)
    self.boxx2=round(float(boxnewu2)*zoom)
    self.boxy2=round(float(boxnewv2)*zoom)
    self.boxx3=round(float(boxnewu3)*zoom)
    self.boxy3=round(float(boxnewv3)*zoom)

    if keyword_set(fin) then begin
        ; update data framesize to draw framesize
        self.boxu0=boxnewu0
        self.boxv0=boxnewv0
        self.boxu1=boxnewu1
        self.boxv1=boxnewv1
        self.boxu2=boxnewu2
        self.boxv2=boxnewv2
        self.boxu3=boxnewu3
        self.boxv3=boxnewv3
    endif
    return, 1
endif else return, 0
end


;****************************************************************************
;     SETUP - makes columns for data display
;             !!! needs to be called at start !!!
;****************************************************************************

;; function drip_anal_extract::setup, upwid

;; ;** make widgets
;; common gui_os_dependent_values, largefont, smallfont
;; ; header (with logall)
;; basewid=widget_base(upwid, /column, /frame)
;; headwid=widget_base(basewid,/row,/align_left)
;; title=widget_label(headwid, value='Extract:', font=largefont)
;; newbutton=widget_button(headwid, value='New Box')
;; extbutton=widget_button(headwid, value='Extract')
;; multi=widget_button(headwid, value='Multi-Order')

;; ;read in buttons
;; readbutton=widget_button(headwid, value='Read',/menu)
;; ;widget_control,readbutton,sensitive=0
;; readasc=widget_button(readbutton, value='ASCII...',$
;;                       uvalue={object:self.xplot,$
;;                               method:'rwevent', uval:'read ascii'},$
;;                       event_pro='drip_anal_extract_eventhand')
;; readfits=widget_button(readbutton, value='FITS...',$
;;                       uvalue={object:self.xplot,$
;;                               method:'rwevent', uval:'read fits'},$
;;                       event_pro='drip_anal_extract_eventhand')
;; ;save buttons
;; savebutton=widget_button(headwid, value='Save',/menu)
;; saveasc=widget_button(savebutton, value='ASCII...',$
;;                       uvalue={object:self.xplot,$
;;                               method:'rwevent', uval:'save ascii'},$
;;                       event_pro='drip_anal_extract_eventhand')
;; savefits=widget_button(savebutton, value='FITS...',$
;;                       uvalue={object:self.xplot, $
;;                               method:'rwevent', uval:'save fits'},$
;;                       event_pro='drip_anal_extract_eventhand')
;; saveps=widget_button(savebutton, value='PostScript...',$
;;                       uvalue={object:self.xplot, $
;;                               method:'rwevent', uval:'save ps'},$
;;                       event_pro='drip_anal_extract_eventhand')

;; ;-- table
;; table=widget_base(basewid, /row)
;; ; label
;; label=widget_base(table, /column)
;; labellabel=widget_label(label, value='Box#')
;; ; show
;; show=widget_base(table, /column)
;; showlabel=widget_label(show, value='Show')
;; ; top
;; top=widget_base(table, /column)
;; toplabel=widget_label(top, value='Top')
;; ;plot
;; plot=widget_base(table, /column)
;; plotlabel=widget_label(plot, value='Plot')
;; ; close
;; close=widget_base(table, /column)
;; closelabel=widget_label(close, value='Close')
;; ; color
;; color=widget_base(table, /column)
;; colorlabel=widget_label(color, value='Color')
;; ;display
;; display=widget_base(table,/column)
;; displaylabel=widget_label(display,value='Display')
;; ;coordinate
;; coord=widget_base(table,/column)
;; coordLabel=widget_label(coord,value='Coordinates')

;; ;** create structure and fill in
;; widlist={drip_anal_extract_wids, label:label, show:show, top:top, plot:plot, $
;;          close:close, color:color,display:display,coord:coord, obj:self, $
;;          ext:{drip_anal_extract_wids_ext, new:newbutton, extract:extbutton,$
;;               multi:multi,readasc:readasc,readfits:readfits,$
;;               saveasc:saveasc,savefits:savefits,saveps:saveps} }
;; wids=ptr_new(/allocate_heap)
;; wids=[widlist]
;; return,wids
;; end

;****************************************************************************
;     SETALLWID - gives widgets to analobjs
;     Comment: analobjs must be objects of right type only!
;****************************************************************************

;; pro drip_anal_extract::setallwid, analobjs, wids

;; ;** go through list of widgets: check, assign wigets (ev. create new ones)
;; ; set variables
;; id=65 ; identifer of display of last analysis object
;; objcnt=0 ; count how many objects for this display
;; widn=(size(*wids))[1] ; number of widget entries (highest valid is widn-1)
;; widi=1 ; index of next valid widget entry (get new widgets if > widn-1)
;; colwids=(*wids)[0]
;; ;print,'SETALLWID: widn=',widn
;; objn=(size(analobjs))[1]-1 ; number of analobjs (valid are 1..objn)
;; ; go through list
;; for obji=1,objn do begin
;;     ; if object in focus or shown
;;     if analobjs[obji]->isfocus() or analobjs[obji]->isshow() then begin
;;         ; create widgets if necessary
;;         ;print,'  widi=',widi
;;         if widi ge widn then begin
;;             ; get largefont
;;             common gui_os_dependent_values, largefont, smallfont
;;             ; make new structure
;;             newwids={drip_anal_extract_wids}
;;             ; make new widgets
;;             newwids.label=widget_label(colwids.label,value='A-1', $
;;                                        font=largefont, ysize=25)
;;             newwids.show=widget_button(colwids.show, value=' ', ysize=25)
;;             newwids.top=widget_button(colwids.top, value=' ', ysize=25)
;;             newwids.plot=widget_button(colwids.plot, value='P', ysize=25)
;;             newwids.close=widget_button(colwids.close, value='Cls', ysize=25)
;;             newwids.color=cw_color_sel(colwids.color, [0b,0b,0b], $
;;                                        xsize=32, ysize=19)
;;             newwids.display=widget_button(colwids.display, value='Display')
;;             newwids.coord=widget_button(colwids.coord, value='Coordinates')
;;             ; append them to wids
;;             *wids=[*wids,newwids]
;;             ;print,'  Creating new widget label=',newwids.label
;;         endif
;;         ; check if still same display
;;         newid=(analobjs[obji]).disp->getdata(/disp_id)
;;         ;print,'  newid=',newid
;;         if id ne newid then begin
;;             id=newid
;;             objcnt=1
;;         endif else objcnt=objcnt+1
;;         ; make title
;;         title=string(string(byte(id)),objcnt,format='(A,"-",I1)')
;;         ; pass widgets to object
;;         analobjs[obji]->setwid, title, (*wids)[widi]
;;         ; increase widi
;;         widi=widi+1
;;     endif
;; endfor
;; ;** kill leftover widgets
;; ;print,'  widget sets needed=',widi
;; if widi lt widn then begin
;;     ; kill widgets
;;     while widi lt widn do begin
;;         ;print,'  killing widget ',widn-1
;;         oldwids=(*wids)[widn-1]
;;         widget_control, oldwids.label, /destroy
;;         widget_control, oldwids.show, /destroy
;;         widget_control, oldwids.top, /destroy
;;         widget_control, oldwids.plot, /destroy
;;         widget_control, oldwids.close, /destroy
;;         widget_control, oldwids.color, /destroy
;;         widget_control, oldwids.display,/destroy
;;         widget_control, oldwids.coord, /destroy
;;         widn=widn-1
;;     end
;;     ; shorten wids
;;     *wids=(*wids)[0:widn-1]
;; endif
;; end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal_extract::setwid, wids, title

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
                set_uvalue={object:self.analman, method:'closeanal', obj:self}
; showwid
widget_control, self.showwid, event_pro='drip_anal_extract_eventhand', $
                set_uvalue={object:self, method:'input'}
if self.show then begin
    widget_control, self.showwid, set_value=' X '
endif else begin
    widget_control, self.showwid, set_value='   '
endelse
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
widget_control, self.colorwid, event_pro='drip_anal_extract_eventhand', $
                        set_uvalue={object:self, method:'input'}, $
                        set_value=self.color
;extract widget
widget_control, self.displaywid, event_pro='drip_anal_extract_eventhand', $
                        set_uvalue={object:self, method:'display'}

;coordiate widget
widget_control, self.coordwid, event_pro='drip_anal_extract_eventhand',$
                        set_uvalue={object:self, method:'coord'}
end

;****************************************************************************
;     SETTOP - to set widget on top
;****************************************************************************

pro drip_anal_extract::settop, top
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

pro drip_anal_extract::setplot, plot
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

pro drip_anal_extract::setfocus, focus
if focus ne self.focus then begin
    self.focus=focus
endif
end

;****************************************************************************
;     ISSHOW - to querry if widget shown if display is not in focus
;****************************************************************************

function drip_anal_extract::isshow
return, self.show
end

;****************************************************************************
;     ISFOCUS - to querry if widget in focus
;****************************************************************************

function drip_anal_extract::isfocus
return, self.focus
end

;****************************************************************************
;    SETDATA - to set the data in the object
;****************************************************************************
pro drip_anal_extract::setdata,owave=owave, oflux=oflux
  if keyword_set(owave) then *self.owave = owave
  if keyword_set(oflux) then *self.oflux = oflux
end
;****************************************************************************
;    GETDATA - to retrive data outside the object
;****************************************************************************
function drip_anal_extract::getdata, plot=plot, title=ti,$
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

function drip_anal_extract::init, disp, analman, wid

; same as parent
self.disp=disp
self.analman=analman
self.extman=analman.extman
self.mw=(self.extman).mw
self.xplot=analman.xplot
self.wid=wid
self.top=0
self.plot=1
; get display sizes
xsize=disp->getdata(/xsize)
ysize=disp->getdata(/ysize)
; set box size and location (8 pix from border)
self.focus=0
self.boxu0=8
self.boxv0=8
self.boxu1=xsize-8
self.boxv1=ysize-8
self.boxu2=xsize-8
self.boxv2=8
self.boxu3=8
self.boxv3=ysize-8
self.boxx0=self.boxu0
self.boxy0=self.boxv0
self.boxx1=self.boxu1
self.boxy1=self.boxv1
self.boxx2=self.boxu2
self.boxy2=self.boxv2
self.boxx3=self.boxu3
self.boxy3=self.boxv3
self.color=[255,0,0]
self.oflux=ptr_new(/allocate_heap)
self.owave=ptr_new(/allocate_heap)

return, 1
end

;****************************************************************************
;     CW Features: EVENTHANDLER
;****************************************************************************

pro drip_anal_extract_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
end


;****************************************************************************
;     DRIP_ANAL_EXTRACT__DEFINE
;****************************************************************************

pro drip_anal_extract__define

struct={drip_anal_extract, $
        $;objects
        extman:obj_new(),$      ;extraction data manager object
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
        $;coordinate
        cobase:0l,$             ; widget id for coordiante base
        cotextx0:0l,$           ; widget id for x0
        cotexty0:0l,$           ; widget id for y0
        cotextx1:0l,$           ; widget id for x1
        cotexty1:0l,$           ; widget id for y1
        cotextx2:0l,$           ; widget id for x2
        cotexty2:0l,$           ; widget id for y2
        cotexth:0l,$            ; widget id for height
        $; box characteristics
        boxu0:0, boxv0:0, $     ;box frame positions:   lower left corner
        boxu1:0, boxv1:0, $     ;(in image coordinates) upper right corner
        boxu2:0, boxv2:0, $     ; box positions: lower right corner
        boxu3:0, boxv3:0, $     ;box positions: upper left corner
        $;(legal indices from x0 to x1)
        boxx0:0, boxy0:0, $     ;box frame positions:      lower left corner
        boxx1:0, boxy1:0, $     ;(in display coordinates)  upper right corner
        boxx2:0, boxy2:0, $     ; box positions: lower right corner
        boxx3:0, boxy3:0, $     ; box positions : upper left corner
        $; boxu/v0/1~boxx/y0/1 except when frame moved
        color:bytarr(3), $      ; array for color values
        wid:0B, $               ; window id of display
        $; settings
        show:0, $               ; 1 if numbers shown when display not in focus
        plot:0, $               ; 1 if it is plotted in xplot
        owave:ptr_new(),$       ; plotted data
        oflux:ptr_new(),$
        inherits drip_anal} ; child object of drip_anal
end

