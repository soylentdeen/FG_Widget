; NAME:
;     DRIP_ANAL_POINT__DEFINE - Version .7.0
;
; PURPOSE:
;     Point Source Analysis Objects for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANAL_POINT', MW)
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
;     X0, Y0 - position of box
;     SIZE - width and height of box
;     COLOR - array for color values
;     WID - window id of display
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
;     Written by: Marc Berthoud, Cornell University, June 2005
;                 Adapted from drip_anal_stats__define.pro

;****************************************************************************
;     UPDATE - updates the displayed data
;****************************************************************************

pro drip_anal_point::update

; check if in focus
if self.focus or self.show then begin
    ; get data
    image=self.disp->getdata(/dataraw)
    imgsize=size(*image)
    if (imgsize[0] gt 0) then begin ; we have data
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
        ; check fit peak if (mean>median) fit valley if (mean<median)
        mean=mean(img)
        med=median(img)
        ; fit gaussian
        if mean gt med then res=gauss2dfit(img,ans) $
          else if mean lt med then res=gauss2dfit(img,ans,/negative) $
          else ans=[0.0,0.0,100.0,100.0,0.0,0.0]
        ; extract values
        self.fitu=float(self.boxu0)+ans[4]
        self.fitv=float(self.boxv0)+ans[5]
        self.fitdu=ans[2]
        self.fitdv=ans[3]
        self.fitampl=ans[1]
        self.fitoff=ans[0]
        ; display
        ff=2.0*sqrt(alog(4.0))
        text=string(self.fitu, self.fitv, self.fitdu*ff, self.fitdv*ff, $
                    self.fitampl, self.fitoff, $
                    format='(F8.2,F8.2,F6.2,F6.2,F11.3,F10.3)')
        self.datatext=text
        widget_control, self.datawid, set_value=text
        ; check if fit reasonable
        fitgood=1
        boxdu=self.boxu1-self.boxu0
        boxdv=self.boxv1-self.boxv0
        if ( self.fitu lt self.boxu0 ) or ( self.fitu gt self.boxu1 ) then $
          fitgood=0
        if ( self.fitv lt self.boxv0 ) or ( self.fitv gt self.boxv1 ) then $
          fitgood=0
        if ( self.fitdu gt boxdu ) or ( self.fitdv gt boxdv ) then fitgood=0
        if fitgood eq 0 then begin
            self.fitu=(self.boxu0+self.boxu1)/2.0
            self.fitv=(self.boxv0+self.boxv1)/2.0
            self.fitdu=-10.0
            self.fitdv=-10.0
        endif
    endif else begin ; we don't have data
        self.fitu=(self.boxu0+self.boxu1)/2.0
        self.fitv=(self.boxv0+self.boxv1)/2.0
        self.fitdu=-10.0
        self.fitdv=-10.0
        widget_control, self.datawid, set_value='No Data in this Window'
    endelse
    widget_control, self.colorwid, set_value=self.color
endif
end

;****************************************************************************
;     DRAW - draws screen signs
;****************************************************************************

pro drip_anal_point::draw
; draw box
wset, self.wid
color=self.color[0]+256L*(self.color[1]+256L*self.color[2])
plots, self.boxx0+2, self.boxy0+2, /device
plots, self.boxx1+2, self.boxy0+2, /continue, color=color, /device
plots, self.boxx1+2, self.boxy1+2, /continue, color=color, /device
plots, self.boxx0+2, self.boxy1+2, /continue, color=color, /device
plots, self.boxx0+2, self.boxy0+2, /continue, color=color, /device
; get display locations in image
zoom=self.disp->getdata(/zoom)
; get fit ellipse location and size
fitx=self.fitu*zoom
fity=self.fitv*zoom
fitdx=self.fitdu*zoom
fitdy=self.fitdv*zoom
ang=[!pi/10.0*indgen(20,/float),0.0]
ellx=fitx+cos(ang)*fitdx+2.0
elly=fity+sin(ang)*fitdy+2.0
; plot ellipse
plots, ellx[0],elly[0], /device
for i=1,20 do plots, ellx[i], elly[i], /continue, color=color, /device
end

;****************************************************************************
;     INPUT - reacts to user input
;****************************************************************************

pro drip_anal_point::input, event
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
                ; redraw display
                self.disp->draw
            endelse                
        endif else begin
            ; make show and set button
            self.show=1
            widget_control, self.showwid, set_value='X'
            self.disp->draw
        endelse
    end
    self.logwid:begin
        ; if log
        self->log
    end
    else:
endcase
end

;****************************************************************************
;     MOVE - reaction to moving screen sign
;****************************************************************************

function drip_anal_point::move, xa, ya, xb, yb, final=fin

; u/v is image coordinates, x/y is display coordinates

; get u/v (display coords) values of image boundary (all float)
zoom=self.disp->getdata(/zoom)
imgsize=size(*(self.disp->getdata(/dataraw)))
if imgsize[0] eq 0 then begin
    imgsize=[0,self.disp->getdata(/xsize),self.disp->getdata(/ysize)]
    zoom=1.0
endif
xmin=0.0 ; until I move things around, this will be that easy
ymin=0.0
xmax=float(imgsize[1])*zoom-1
ymax=float(imgsize[2])*zoom-1
; get u/v (display coords) values of original box location boxorigx/y0/1
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
        ; (make sure left edge stays >5pix left of right edge
        if xb lt boxorigx1-5 then begin
            ; (make sure left edge stays right of left border of image)
            if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
            ; (make sure box doesn't get wider than 20 pix)
            if boxorigx1-self.boxx0 gt 20 then $
              self.boxx1=self.boxx0+20 else self.boxx1=boxorigx1
        endif else self.boxx0=boxorigx1-5
        change=1
    endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; bottom right corner -> move right line
        ; (make sure right edge stays >5pix right of left edge)
        if xb gt boxorigx0+5 then begin
            ; (make sure right edge stays left of right border of image)
            if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
            ; (make sure box doesn't get wider than 20 pix)
            if self.boxx1-boxorigx0 gt 20 then $
              self.boxx0=self.boxx1-20 else self.boxx0=boxorigx0
        endif else self.boxx1=boxorigx0+5
        change=1
    endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
        ; bottom line -> move bottom line
        change=1
    endif
    if change then begin
        ; move bottom line
        ; (make sure bottom edge stays >5pix below top edge)
        if yb lt boxorigy1-5 then begin
            ; (make sure bottom edge stays above bottom of image)
            if yb gt ymin then self.boxy0=yb else self.boxy0=ymin
            ; (make sure box doesn't get taller than 20 pix)
            if boxorigy1-self.boxy0 gt 20 then $
              self.boxy1=self.boxy0+20 else self.boxy1=boxorigy1
        endif else self.boxy0=boxorigy1-5
    endif
endif else if (ya gt boxorigy1-3) and (ya lt boxorigy1+3) then begin
    ; close to top line
    if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
        ; top left corner -> move left line
        ; (make sure left edge stays >5pix left of right edge)
        if xb lt boxorigx1-5 then begin
            ; (make sure left edge stays right of left border of image)
            if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
            ; (make sure box doesn't get wider than 20 pix)
            if boxorigx1-self.boxx0 gt 20 then $
              self.boxx1=self.boxx0+20 else self.boxx1=boxorigx1
        endif else self.boxx0=boxorigx1-5
        change=1
    endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; top right corner -> move right line
        ; (make sure right edge stays >5pix right of left edge)
        if xb gt boxorigx0+5 then begin
            ; (make sure right edge stays left of right border of image)
            if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
            ; (make sure box doesn't get wider than 20 pix)
            if self.boxx1-boxorigx0 gt 20 then $
              self.boxx0=self.boxx1-20 else self.boxx0=boxorigx0
        endif else self.boxx1=boxorigx0+5
        change=1
    endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
        ; top line -> move top line
        change=1
    endif
    if change then begin
        ; move top line
        ; (make sure top edge stays >5pix above bottom edge)
        if yb gt boxorigy0+5 then begin
            ; (make sure top edge stays below top of image)
            if yb lt ymax then self.boxy1=yb else self.boxy1=ymax
            ; (make sure box doesn't get taller than 20 pix)
            if self.boxy1-boxorigy0 gt 20 then $
              self.boxy0=self.boxy1-20 else self.boxy0=boxorigy0
        endif else self.boxy1=boxorigy0+5
    endif
endif else if (ya gt boxorigy0+2) and (ya lt boxorigy1-2) then begin
    ; between top and bottom line
    if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
        ; left line -> change width of box
        ; (make sure left edge stays >5pix left of right edge)
        if xb lt boxorigx1-5 then begin
            ; (make sure left edge stays right of left border of image)
            if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
            ; (make sure box doesn't get wider than 20 pix)
            if boxorigx1-self.boxx0 gt 20 then $
              self.boxx1=self.boxx0+20 else self.boxx1=boxorigx1
        endif else self.boxx0=boxorigx1-5
        change=1
    endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; right line -> change width of box
        ; (make sure right edge stays >5pix right of left edge)
        if xb gt boxorigx0+5 then begin
            ; (make sure right edge stays left of right border of image)
            if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
            ; (make sure box doesn't get wider than 20 pix)
            if self.boxx1-boxorigx0 gt 20 then $
              self.boxx0=self.boxx1-20 else self.boxx0=boxorigx0
        endif else self.boxx1=boxorigx0+5
        change=1
    endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
        ; inside -> move box arround
        ; move horizontally
        ; ( make sure box edges don't get closer than opposite image borders ) 
        if xb lt xmin then dx=xmin-xa else if xb gt xmax then dx=xmax-xa $
          else dx=xb-xa
        if boxorigx0+dx lt xmin then self.boxx0=xmin else $
          if boxorigx0+dx gt xmax-5 then self.boxx0=xmax-5 else $
            self.boxx0=boxorigx0+dx
        if boxorigx1+dx gt xmax then self.boxx1=xmax else $
          if boxorigx1+dx lt xmin+5 then self.boxx1=xmin+5 else $
            self.boxx1=boxorigx1+dx
        ; move vertically
        if yb lt ymin then dy=ymin-ya else if yb gt ymax then dy=ymax-ya $
          else dy=yb-ya
        if boxorigy0+dy lt ymin then self.boxy0=ymin else $
          if boxorigy0+dy gt ymax-5 then self.boxy0=ymax-5 else $
            self.boxy0=boxorigy0+dy
        if boxorigy1+dy gt ymax then self.boxy1=ymax else $
          if boxorigy1+dy lt ymin+5 then self.boxy1=ymin+5 else $
            self.boxy1=boxorigy1+dy
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
;     LOG - log data to file
;****************************************************************************

pro drip_anal_point::log
; get filename
common gui_config_info, guiconf
logfname=getpar(guiconf,'LOGFILE')
if (size(logfname))[1] ne 7 then begin
    logfname=dialog_pickfile()
    setpar,guiconf,'LOGFILE',logfname
end
; open file
openw,logfunit,logfname,/get_lun,/append
; if empty file add header
logfstat=fstat(logfunit)
if logfstat.cur_ptr lt 10 then printf,logfunit, $
  'X0  Y0  X1  Y1    XPos    YPos   FWHM_X  FWHM_Y     Ampl       OffSet'
; get data
image=self.disp->getdata(/dataraw)
imgsize=size(*image)
if (imgsize[0] gt 0) then begin ; we have data
    ; display
    ff=2.0*sqrt(alog(4.0))
    text=string(self.boxx0, self.boxy0, self.boxx1, self.boxy1, $
                self.fitx, self.fity, self.fitdx*ff, self.fitdy*ff, $
                self.fitampl, self.fitoff, $
                format='(I3,I4,I4,I4,F8.2,F8.2,F6.2,F6.2,F11.3,F10.3)')
endif else begin                ; we don't have data
    text='No Data in this Window'
endelse
; add line
printf,logfunit,text
; close file
close,logfunit
end

;****************************************************************************
;     SETWID - set widgets for interaction
;****************************************************************************

pro drip_anal_point::setwid, wids, title

;** set widget variables
self.title=title ; what will be put in label
self.labelwid=wids.label
self.showwid=wids.show
self.topwid=wids.top
self.closewid=wids.close
self.logwid=wids.log
self.colorwid=wids.color
self.datawid=wids.data
;** set widgets
; label
widget_control, self.labelwid, set_value=self.title
; closewid
widget_control, self.closewid, $
                set_uvalue={object:self.analman, method:'closeanal', obj:self}
; showwid
widget_control, self.showwid, $
                set_uvalue={object:self, method:'input'}
if self.show then begin
    widget_control, self.showwid, set_value=' X '
endif else begin
    widget_control, self.showwid, set_value='   '
endelse
; topwid
widget_control, self.topwid, $
  set_uvalue={object:self, method:'input'}
if self.top then begin
    widget_control, self.topwid, set_value=' X '
endif else begin
    widget_control, self.topwid, set_value='   '
endelse
; logwid
widget_control, self.logwid, $
  set_uvalue={object:self, method:'input'}
widget_control, self.logwid, set_value='  '
; colorwid (color)
widget_control, self.colorwid, $
                        set_uvalue={object:self, method:'input'}, $
                        set_value=self.color
; datawid
widget_control, self.datawid, set_value=self.datatext
end

;****************************************************************************
;     SETTOP - to set widget on top
;****************************************************************************

pro drip_anal_point::settop, top
if self.top ne top then begin
    self.top=top
    if top gt 0 then text=' X ' else text='   '
    if self.focus gt 0 then widget_control, self.topwid, set_value=text
endif
end

;****************************************************************************
;     SETFOCUS - puts object in and out of focus
;****************************************************************************

pro drip_anal_point::setfocus, focus
if focus ne self.focus then begin
    self.focus=focus
endif
end

;****************************************************************************
;     ISSHOW - to querry if widget shown if display is not in focus
;****************************************************************************

function drip_anal_point::isshow
return, self.show
end

;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal_point::init, disp, analman, title, wid

; same as parent
self.disp=disp
self.analman=analman
self.title=title
self.wid=wid
self.top=0
self.datatext=''
; get display sizes
xsize=disp->getdata(/xsize)
ysize=disp->getdata(/ysize)
; set box size and location (8 pix from border)
self.focus=0
self.boxx0=xsize/2-9
self.boxy0=ysize/2-9
self.boxx1=xsize/2+9
self.boxy1=ysize/2+9
self.boxu0=self.boxx0
self.boxv0=self.boxy0
self.boxu1=self.boxx1
self.boxv1=self.boxy1
self.color=[255,0,0]
; set fit locations
self.fitu=float(xsize/2)
self.fitv=float(ysize/2)
self.fitdu=-1.0
self.fitdv=-1.0
return, 1
end

;****************************************************************************
;     DRIP_ANAL_POINT__DEFINE
;****************************************************************************

pro drip_anal_point__define

struct={drip_anal_point, $
        ; widgets
        topwid:0L, $            ; widget id for top indicator
        closewid:0L, $          ; widget id for close button
        showwid:0L, $           ; widget id for show button
        logwid:0L, $            ; widget id for log button
        colorwid:0L, $          ; widget id for color selector
        datawid:0L, $           ; widget id for data display
        datatext:'', $          ; text for data display
        ; fit box and fit display characteristics
        boxu0:0, boxv0:0, $     ; box frame positions:   lower left corner
        boxu1:0, boxv1:0, $     ; (in image coordinates) upper right corner
                                ; (legal indices from x0 to x1)
                                ; (box is always <= 20pix)
        boxx0:0, boxy0:0, $     ; box frame positions:      lower left corner
        boxx1:0, boxy1:0, $     ; (in display coordinates)  upper right corner
                                ; boxu/v0/1~boxx/y0/1 except when
                                ; frame moved it has temporary values
        color:bytarr(3), $      ; array for color values
        wid:0B, $               ; window id of display
        ; fitted values
        fitu:0.0, fitv:0.0, $   ; location of best fit in image (float)
        fitdu:0.0, fitdv:0.0, $ ; sigma width of fit (float)
                                ; negative fitdx/y means no fit available
        fitampl:0.0, $          ; fit amplitude
        fitoff:0.0, $           ; fit offset
                                ; fit values are not updated while box moves
        ; settings
        show:0, $               ; 1 if nubers shown when display not in focus
        inherits drip_anal}     ; child object of drip_anal
end

