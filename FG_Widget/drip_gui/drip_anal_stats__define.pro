; NAME:
;     DRIP_ANAL_STATS__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Statistics Analysis Objects for the GUI. This analysis object
;     displays statistics about selected regions of the image.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_ANAL_STATS inherits DRIP_ANAL
;     DRIP_ANALMAN_STATS: This object creates ANAL_STATS and
;                          assigns it screen widgets. ANALMAN_STATS
;                          also creates and destroys ANAL_STATS
;                          objects.
;     CW_DRIP_DISP: DISPlays inform ANAL_STATS of changes in focus,
;                   request updates redraws. ANAL_STATS draws the
;                   corresponding box on the display. DISP also
;                   notifies ANAL_STATS of potential mouse actions,
;                   moving the stats box is done by ANAL_STATS::MOVE.
;
; PROCEDURE:
;     Beyond the normal analysis object functions (focus, title)
;     ANAL_STATS allows the user to use an interactive frame to set
;     the color scale of the image. The three possible scaling options
;     are Min-Max (highest / lowest value in the frame or user set),
;     N-Sigma (Set scale from median-N*stddev . . . median+N*stddev)
;     and Percent (same as Min-Max but ignore (100-Percentage)/2
;     pixels with highest and lowest values.
;
; RESTRICTIONS:
;     In developement
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

;****************************************************************************
;     UPDATE - updates the displayed data
;****************************************************************************

pro drip_anal_stats::update
common gui_os_dependent_values, largefont, smallfont
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
        ; get stats
        image_statistics,img,mean=mean,stddev=stddev, $
                         minimum=min,maximum=max
        med=median(img)
        npix=long(self.boxu1-self.boxu0+1)*long(self.boxv1-self.boxv0+1)
                       
        ; fix format for all
        all = [ mean,med,stddev,min,max,npix ]
        text = strarr(6)
        for i= 0,5 do begin
           x = all[i]
           case 1 of
              (abs(x) gt 999999) : fmt = '(e10.0)'
              (abs(x) lt 0.1) : fmt = '(e10.1)'
              else : fmt = '(f10.1)'
           endcase
           text[i]=string(x,format=fmt)
        endfor
        self.datatext=text
        for i=1,6 do begin
           widget_control, self.datawid[i], set_value=text[i-1]
        endfor
        
    endif else begin ; we don't have data
       g=string(findgen(6))
        for i=1,6 do begin
           widget_control, self.datawid[i], set_value=g[i-1]
        endfor
    endelse
    widget_control, self.colorwid, set_value=self.color
endif
end

;****************************************************************************
;     DRAW - draws screen signs
;****************************************************************************

pro drip_anal_stats::draw
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

pro drip_anal_stats::input, event
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

function drip_anal_stats::move, xa, ya, xb, yb, final=fin

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
        ; (make sure left edge stays left of right edge)
        if xb lt boxorigx1 then begin
            ; (make sure left edge stays right of right border of image)
            if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
        endif else self.boxx0=boxorigx0
        change=1
    endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; bottom right corner -> move right line
        ; (make sure right edge stays right of left edge)
        if xb gt boxorigx0 then begin
            ; (make sure right edge stays left of right border of image)
            if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
        endif else self.boxx1=boxorigx1
        change=1
    endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
        ; bottom line -> move bottom line
        change=1
    endif
    if change then begin
        ; move bottom line
        ; (make sure bottom edge stays below top edge)
        if yb lt boxorigy1 then begin
            ; (make sure bottom edge stays above bottom of image)
            if yb gt ymin then self.boxy0=yb else self.boxy0=ymin
        endif else self.boxy0=boxorigy0
    endif
endif else if (ya gt boxorigy1-3) and (ya lt boxorigy1+3) then begin
    ; close to top line
    if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
        ; top left corner -> move left line
        ; (make sure left edge stays left of right edge)
        if xb lt boxorigx1 then begin
            ; (make sure left edge stays right of left border of image)
            if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
        endif else self.boxx0=boxorigx0
        change=1
    endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; top right corner -> move right line
        ; (make sure right edge stays right of left edge)
        if xb gt boxorigx0 then begin
            ; (make sure right edge stays left of right border of image)
            if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
        endif else self.boxx1=boxorigx1
        change=1
    endif else if (xa gt boxorigx0+2) and (xa lt boxorigx1-2) then begin
        ; top line -> move top line
        change=1
    endif
    if change then begin
        ; move top line
        ; (make sure top edge stays above bottom edge)
        if yb gt boxorigy0 then begin
            ; (make sure top edge stays below top of image)
            if yb lt ymax then self.boxy1=yb else self.boxy1=ymax
        endif else self.boxy1=boxorigy1
    endif
endif else if (ya gt boxorigy0+2) and (ya lt boxorigy1-2) then begin
    ; between top and bottom line
    if (xa gt boxorigx0-3) and (xa lt boxorigx0+3) then begin
        ; left line -> change width of box
        ; (make sure left edge stays left of right edge)
        if xb lt boxorigx1 then begin
            ; (make sure left edge stays right of left border of image)
            if xb gt xmin then self.boxx0=xb else self.boxx0=xmin
        endif else self.boxx0=boxorigx0
        change=1
    endif else if (xa gt boxorigx1-3) and (xa lt boxorigx1+3) then begin
        ; right line -> change width of box
        ; (make sure right edge stays right of left edge)
        if xb gt boxorigx0 then begin
            ; (make sure right edge stays left of right border of image)
            if xb lt xmax then self.boxx1=xb else self.boxx1=xmax
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
;     LOG - log data to file
;****************************************************************************

pro drip_anal_stats::log
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
  'X0  Y0  X1  Y1    Mean      Median    StdDev    Min       Max      Pixels '
; get data
image=self.disp->getdata(/dataraw)
imgsize=size(*image)
if (imgsize[0] gt 0) then begin ; we have data
    img=(*image)[self.boxx0:self.boxx1,self.boxy0:self.boxy1]
    ; get stats
    image_statistics,img,mean=mean,stddev=stddev, $
      minimum=min,maximum=max
    med=median(img)
    npix=long(self.boxx1-self.boxx0+1)*long(self.boxy1-self.boxy0+1)
    ; display
    text=string(self.boxx0,self.boxy0,self.boxx1,self.boxy1, $
                mean,med,stddev,min,max,npix, $
                format='(I3,I4,I4,I4,F10.2,F10.2,F10.2,F10.2,F10.2,I7)')
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

pro drip_anal_stats::setwid, wids, title

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
for i=1,6 do begin
   widget_control, self.datawid[i], set_value=self.datatext[i-1]
endfor
end

;****************************************************************************
;     SETTOP - to set widget on top
;****************************************************************************

pro drip_anal_stats::settop, top
if self.top ne top then begin
    self.top=top
    if top gt 0 then text=' X ' else text='   '
    if self.focus gt 0 then widget_control, self.topwid, set_value=text
endif
end

;****************************************************************************
;     SETFOCUS - puts object in and out of focus
;****************************************************************************

pro drip_anal_stats::setfocus, focus
if focus ne self.focus then begin
    self.focus=focus
endif
end

;****************************************************************************
;     ISSHOW - to querry if widget shown if display is not in focus
;****************************************************************************

function drip_anal_stats::isshow
return, self.show
end

;****************************************************************************
;     INIT - to create analysis object
;****************************************************************************

function drip_anal_stats::init, disp, analman, title, wid

; same as parent
self.disp=disp
self.analman=analman
self.title=title
self.wid=wid
self.top=0
self.datatext=string(indgen(6))
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
self.color=[255,0,0]
return, 1
end

;****************************************************************************
;     DRIP_ANAL_STATS__DEFINE
;****************************************************************************

pro drip_anal_stats__define

struct={drip_anal_stats, $
        ; widgets
        topwid:0L, $        ; widget id for top indicator
        closewid:0L, $      ; widget id for close button
        showwid:0L, $       ; widget id for show button
        logwid:0L, $        ; widget id for log button
        colorwid:0L, $      ; widget id for color selector
        datawid:lonarr(7), $; widget id for data display
        datatext:strarr(6),$; text for data display
        ; box characteristics
        boxu0:0, boxv0:0, $ ;box frame positions:   lower left corner
        boxu1:0, boxv1:0, $ ;(in image coordinates) upper right corner
                            ;(legal indices from x0 to x1)
        boxx0:0, boxy0:0, $ ;box frame positions:      lower left corner
        boxx1:0, boxy1:0, $ ;(in display coordinates)  upper right corner
                            ; boxu/v0/1~boxx/y0/1 except when frame moved
        color:bytarr(3), $  ; array for color values
        wid:0B, $           ; window id of display
        ; settings
        show:0, $          ; 1 if nubers shown when display not in focus
        inherits drip_anal} ; child object of drip_anal
end

