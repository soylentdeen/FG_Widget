; NAME:
;     DRIP_ANAL_POINT__DEFINE - Version 1.7.0
;
; PURPOSE:
;     Point Source Analysis Objects for the GUI. This analysis object
;     alows the user to analyze point sources.
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     DRIP_ANAL_POINT inherits DRIP_ANAL
;     DRIP_ANALMAN_POINT: This object creates ANAL_POINT and
;                          assigns it screen widgets. ANALMAN_POINT
;                          also creates and destroys ANAL_POINT
;                          objects.
;     CW_DRIP_DISP: DISPlays inform ANAL_POINT of changes in focus,
;                   request updates redraws. ANAL_POINT draws the
;                   corresponding circles on the display. DISP also
;                   notifies ANAL_POINT of potential mouse actions,
;                   moving the pointsource circles is done by
;                   ANAL_POINT::MOVE.
;
; PROCEDURE:
;     Beyond the normal analysis object functions (focus, title)
;     ANAL_POINT allows the user to use an interactive point source
;     analysis tool to determine the souce strength and S/N.
;
; RESTRICTIONS:
;     In developement
;
; MODIFICATION HISTORY:
;     Written by: Marc Berthoud, Cornell University, June 2005
;                 Adapted from drip_anal_stats__define.pro
;     Modified: Nirbhik Chitarkar, Ithaca College, 2008
;               Changed point to aperture photometry with sky annulus
;     Modified: Luke Keller, Ithaca College, February 2010
;               Update photometry and S/N calculation to be in
;               electrons
;     Modified: Keller / Berthoud, Ithaca College, March 2010
;               use gauss2dfit for calculating FWHM
;     Modified: Berthoud, Yerkes Observatory, March 2010
;               Change FWHM field to FWHM (x/y)

;****************************************************************************
;     UPDATE - updates the displayed data
;****************************************************************************
PRO drip_anal_point::update

  ;check if in focus
  if self.focus or self.show then begin
     ; get raw image
     image=self.disp->getdata(/dataraw)
     imgsize=size(*image)
     if (imgsize[0] gt 0) then begin ; we have data
        ; update locations of box in image coordinates
        zoom=self.disp->getdata(/zoom)
        self.centu=round(float(self.centx)/zoom)
        self.centv=round(float(self.centy)/zoom)
        self.apradw=round(float(self.apradz)/zoom)
        self.isradw=round(float(self.isradz)/zoom)
        self.osradw=round(float(self.osradz)/zoom)
        self.skyu=round(float(self.skyx)/zoom)
        self.skyv=round(float(self.skyy)/zoom)


        ; check circle locations (if nesessary change display circle)
        ;  if ((self.centu+self.osradw) gt imgsize[1]-2) then begin
        ;     diff=[self.osradw-self.isradw, self.osradw-self.apradw]
        ;     self.osradw=imgsize[1]-2-self.centu
        ;     self.isradw=self.osradw-diff[0]
        ;     self.apradw=self.osradw-diff[1]
        ;  endif
        ;  if ((self.centv+self.osradw) gt imgsize[2]-2) then begin
        ;     diff=[self.osradw-self.isradw, self.osradw-self.apradw]
        ;     self.osradw=imgsize[2]-2-self.centv
        ;     self.isradw=self.osradw-diff[0]
        ;     self.apradw=self.osradw-diff[1]
        ;  endif
        ; update circle positions in display coordinates
        self.centx=round(float(self.centu)*zoom)
        self.centy=round(float(self.centv)*zoom)
        self.apradz=round(float(self.apradw)*zoom)
        self.isradz=round(float(self.isradw)*zoom)
        self.osradz=round(float(self.osradw)*zoom)
        self.skyx=round(float(self.skyu)*zoom)
        self.skyy=round(float(self.skyv)*zoom)

        ;** calculations and photometry

        ; get image of all inside outer ring
        x0=self.centu-self.osradw > 0
        x1=self.centu+self.osradw < imgsize[1] -1
        y0=self.centv-self.osradw > 0
        y1=self.centv+self.osradw < imgsize[2] -1

        ; crop the image
        buffer=(*image)[x0:x1,y0:y1]
        ; size of buffer
        bsz=size(buffer)

        ; center coordinates of the buffer relative to center of buffer
        xc=self.osradw < bsz[1]-1
        yc=self.osradw < bsz[2]-1

        ; find the r-coordinate for all the points in buffer
        r=fltarr(bsz[1],bsz[2])
        for i=0,bsz[1]-1 do begin
            for j=0,bsz[2]-1 do begin
                r[i,j]=sqrt((xc-i)^2+(yc-j)^2)-0.5
            endfor
        endfor
        apid=where(r lt self.apradw)
        

        ; get buffer and center for noise
        if self.skymode eq 'cent' then begin
            skybuffer=buffer
            skyid=where((r gt self.isradw) and (r lt self.osradw))
            
        endif else begin
            ; get image of all inside outer ring
            x0=self.skyu-self.osradw > 0
            x1=self.skyu+self.osradw < imgsize[1] -1
            y0=self.skyv-self.osradw > 0
            y1=self.skyv+self.osradw < imgsize[2] -1

            ; crop the image
            skybuffer=(*image)[x0:x1,y0:y1]
            ; size of buffer
            skybsz=size(skybuffer)

            ; center coordinates of the buffer
            skyxc=self.osradw < skybsz[1]-1
            skyyc=self.osradw < skybsz[2]-1
            
            ; find the r-coordinate for all the points in buffer
            r=fltarr(skybsz[1],skybsz[2])
            for i=0,skybsz[1]-1 do begin
                for j=0,skybsz[2]-1 do begin
                    r[i,j]=sqrt((skyxc-i)^2+(skyyc-j)^2)-0.5
                endfor
            endfor
            skyid=where(r lt self.osradw)
            
        endelse

        ;gain=float(drip_getpar(*self.basehead,'EPERADU')) ;get gain from header
        eperadu=1294 ; SWC and LWC electrons per A/D unit
        
        source=total(buffer[apid],/nan)/n_elements(buffer[apid])    ;-total(skybuffer[skyid],/nan) * $
               ;n_elements(apid)/n_elements(skyid)
        
        ;gcntrd, buffer,xc, yc, x, y, 4.0   ; Seems to work
             
        photon_noise=sqrt(source)
        noise = stdev(skybuffer[skyid])
        ; Calculate noise in photometry anulus
        ; Calulate sum of source pixel values (in electrons)
        
        ;source_electrons=source ;*1e6
        ;source*=1e6   ; to get e-/s in the 'Coadded' frame
        
        ; Calculate photon noise of source by taking sqrt
        ;photon_noise=sqrt(source)
        ; Total noise is std of sky anulus + photon noise
        ;noise =  sqrt((stdev(skybuffer[skyid])*1e6)^2 + (photon_noise)^2)
        ;noise = sqrt((stdev(skybuffer[skyid]))^2+(photon_noise)^2)
        ;noise = stdev(skybuffer[skyid])
        
        ;noise_electrons=noise
        
        ;noise_electrons=sqrt(n_elements(apid) * (stdev(skybuffer[skyid] * eperadu))^2 $
        ;           + photon_noise)
                   
        ;s2n=source_electrons/noise_electrons ; calculate S/N ratio
        s2n=source/noise   ; S/N ratio in counts (e- conversion now done in drip_stack)
        
        ; Centroid and FWHM
        ;find centroid (xcen,ycen)
        
        ;gcntrd,buffer[(xc-self.apradw):xc+(self.apradw), $
        ;              (yc-self.apradw):yc+(self.apradw)], $
        ;  xc,yc,xcen,ycen,self.apradw
        ; row and column intersecting the center of the aperture
        rowx=buffer[xc,((yc-self.apradw)>0): ((yc+self.apradw)<bsz[2]-1)]
        rowy=buffer[((xc-self.apradw)>0):((xc+self.apradw)<bsz[1]-1),yc]
        ;in x direction
        ;x=findgen(n_elements(rowx))
        ;gauss=gaussfit(x,rowx,coeff,nterms=6)
        ;fwhmx=2*SQRT(2*ALOG(2))*coeff[2]
        ;in y direction
        ;x=findgen(n_elements(rowy))
        ;gauss=gaussfit(x,rowy,coeff,nterms=6)
        ;fwhmy=2*SQRT(2*ALOG(2))*coeff[2]
        ;final fwhm is the average of fwhmx and fwhmy
        ;fwhm=(fwhmx+fwhmy)/2
        
        ;** NEW fit with gauss2dfit

        ; boxsize = mean of inscribed and outer square of aperture circle
        boxsize=fix(0.85*float(self.apradw)+0.5)
        ; get the image
        fitimg=buffer[((xc-boxsize)>0):((xc+boxsize)<bsz[1]-1), $
                      ((yc-boxsize)>0): ((yc+boxsize)<bsz[2]-1)]
        ; do gauss fit (make sure we fit positive or negative bump)
        imean=mean(fitimg)
        imed=median(fitimg)
        if imean gt imed then res=gauss2dfit(fitimg,ans) $
          else if imean lt imed then res=gauss2dfit(fitimg,ans,/negative) $
          else ans=[0.0,0.0,100.0,100.0,0.0,0.0]
        ; extract values
        self.fitu=float(self.boxu0)+ans[4]
        self.fitv=float(self.boxv0)+ans[5]
        self.fitdu=ans[2]
        self.fitdv=ans[3]
        self.fitampl=ans[1]
        self.fitoff=ans[0]
        ; calculate FWHM = 2*sqrt(2*ln(2))*sigma
        fwhm=2*SQRT(2*ALOG(2))*(self.fitdu+self.fitdv)/2.0
        fwhmx=2*SQRT(2*ALOG(2))*self.fitdu
        fwhmy=2*SQRT(2*ALOG(2))*self.fitdv

        ; fix format for table numbers
        all = [ fwhmx, fwhmy, source, noise, s2n ]
        text = strarr(5)
        for i= 0,4 do begin
           x = all[i]
           case 1 of
              (abs(x) gt 999999) : fmt = '(e10.1)'
              (abs(x) lt 0.1) : fmt = '(e10.1)'
              else : fmt = '(f10.1)'
           endcase
           text[i]=string(x,format=fmt)
        endfor
        ; adjust text[1] to contain fwhmx / fwhmy
        fwhmtext=' '+strtrim(text[0],2)+'  /  '+strtrim(text[1],2)
        ;print,'Texts='+fwhmtext+'='
        text[1]=fwhmtext
        ; set datatext
        self.datatext=text[1:4]

        ; fill table values to labels
        for i=1,4 do begin
           widget_control, self.datawid[i], set_value=text[i]
        endfor

     endif else begin           ; we dont have data
        g=string(findgen(4))
        for i=1,4 do begin
           widget_control, self.datawid[i], set_value=g[i-1]
        endfor
     endelse
     widget_control, self.colorwid, set_value=self.color
  endif
END


;****************************************************************************
;     DRAW - draws screen signs
;****************************************************************************

pro drip_anal_point::draw
; set display
wset, self.wid

; get color
color=self.color[0]+256L*(self.color[1]+256L*self.color[2])
color1=0+256L*(255+256L*0)
color2=0+256L*(0+256L*255)
; draw circles
; aperture
tvcircle, self.apradz, self.centx, self.centy, color=color
; sky circles
if self.skymode eq 'cent' then begin
    ; inner sky
   tvcircle, self.isradz, self.centx, self.centy, color=color1
   ; outer sky
   tvcircle, self.osradz, self.centx, self.centy, color=color2
endif else begin
   ; outer sky
   tvcircle, self.osradz, self.skyx, self.skyy, color=color2
endelse

; draw diamonds
d=3  ; size of diamond
; for aperture
; center of the diamond
ax=self.centx & ay=self.centy+self.apradz
;coordinates for the diamond
dax=[ax-d,ax+d,ax+d,ax-d] & day=[ay+d,ay+d,ay-d,ay-d]
; draw diamonds
polyfill,dax,day,color=color,/device

if self.skymode eq 'cent' then begin
    ; for inner sky
    ; center of the diamond
    ix=self.centx & iy=self.centy-self.isradz
    ;coordinates of the diamond
    dix=[ix-d,ix+d,ix+d,ix-d] & diy=[iy+d,iy+d,iy-d,iy-d]
    ;draw diamonds
    polyfill,dix,diy,color=color1,/device
    ; outer sky diamond center
    ox=self.centx & oy=self.centy+self.osradz
endif else begin
    ; outer sky diamond center
    ox=self.skyx & oy=self.skyy+self.osradz
    ; if sky is offset, draw connecting line between circles 
    dx=self.skyx-self.centx
    dy=self.skyy-self.centy
    dr=sqrt(dx*dx+dy*dy)
    plots, self.centx+dx*self.apradz/dr, self.centy+dy*self.apradz/dr, /device
    rn=(dr-self.osradz)/dr
    plots, self.centx+dx*rn, self.centy+dy*rn, /continue, color=color2, /device
 endelse

; for outer sky
;coordinates of the diamond
dox=[ox-d,ox+d,ox+d,ox-d] & doy=[oy+d,oy+d,oy-d,oy-d]
;draw diamonds
polyfill,dox,doy,color=color2,/device

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
    self.skywid:begin
        ; if center -> offset
        if self.skymode eq 'cent' then begin
            self.skymode='off'
            widget_control, self.skywid, set_value='Off'
        endif else begin
            self.skymode='cent'
            widget_control, self.skywid, set_value='Cent'
            ; make sure sky_out > sky_in > aperture
            zoom=self.disp->getdata(/zoom)
            if self.apradz+3 gt self.isradz then begin
                self.isradz = self.apradz+3
                self.isradw = round(float(self.isradz)/zoom)
            endif
            if self.osradz lt self.isradz+3 then begin
                self.osradz = self.isradz+3
                self.osradw = round(float(self.osradz)/zoom)
            endif
        endelse
        self.disp->draw
    end
    self.logwid:begin
        ; if log
        self->log
    end
    else:
endcase
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
                self.fitu, self.fitv, self.fitdu*ff, self.fitdv*ff, $
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
;     MOVE - reaction to moving screen sign
;****************************************************************************
function drip_anal_point::move, xa, ya, xb, yb, final=fin

; u/v/w is image coordinates, x/y/z is display coordinates
; a is for aperture, i for inner sky circle, o for outer sky circle

; get u/v/w values of image boundary (all float)
zoom=self.disp->getdata(/zoom)
imgsize=size(*(self.disp->getdata(/dataraw)))
if imgsize[0] eq 0 then begin
    imgsize=[0,self.disp->getdata(/xsize),self.disp->getdata(/ysize)]
    zoom=1.0
endif
xmin=0.0
ymin=0.0
xmax=float(imgsize[1])*zoom-1
ymax=float(imgsize[2])*zoom-1
; get u/v/w values of original box location (from u/v/w values)
origcentx=round(float(self.centu)*zoom)
origcenty=round(float(self.centv)*zoom)
origapradz=round(float(self.apradw)*zoom)
origisradz=round(float(self.isradw)*zoom)
origosradz=round(float(self.osradw)*zoom)
origskyx=round(float(self.skyu)*zoom)
origskyy=round(float(self.skyv)*zoom)

; find the radii from the center
rada=sqrt((xa-origcentx)^2 + (ya-origcenty)^2)
radb=sqrt((xb-origcentx)^2 + (yb-origcenty)^2)
radsky=sqrt((xa-origskyx)^2 + (ya-origskyy)^2)
radx=((xmax-origcentx) < origcentx)
rady=((ymax-origcenty) < origcenty)
radmax=(radx < rady)
radx=((xmax-origskyx) < origskyx)
rady=((ymax-origskyy) < origskyy)
radmaxsky=(radx < rady)
; center of diamonds
; aperture
ax=self.centx & ay=self.centy+self.apradz
; inner sky
ix=self.centx & iy=self.centy-self.isradz
; outer sky
if self.skymode eq 'cent' then begin
   ox=self.centx & oy=self.centy+self.osradz
endif else begin
   ox=self.skyx & oy=self.skyy+self.osradz
endelse
; size of diamond
d=5

;print,'a=',ax,ay,' i=',ix,iy,' o=',ox,oy
;print,'init=',xa,ya, ' mode=',self.mode

; set change variable
change=0
; If no ongoing change -> look if object is changed by user
if (self.mode eq 'none') then begin
    ;inside aperture diamond
    if (((xa gt ax-d) and (xa lt ax+d)) $
        and ((ya gt ay-d) and (ya lt ay+d))) then begin
        ; set mode to aperture resize
        self.mode='apsz'
    endif
    ; inside inner sky diamond (only in skycenter mode)
    if(((xa gt ix-d) and (xa lt ix+d)) and ((ya gt iy-d) and (ya lt iy+d)) $
            and (self.skymode eq 'cent')) then begin
        ; set mode to inner sky resize
        self.mode='issz'
    endif
    ; inside outer sky diamond
    if (((xa gt ox-d) and (xa lt ox+d)) $
             and ((ya gt oy-d) and (ya lt oy+d))) then begin
        ; set mode to outer sky resize
        self.mode='ossz'
    endif
    ; inside the circles and not on the diamonds (only if mode is still none)
    if self.mode eq 'none' then begin
        if self.skymode eq 'cent' then begin
            ; if center mode, check center distance 
            if (rada lt origosradz) then begin
                ; set mode to move
                self.mode='move'
                self.centx= (xa > (xmin+2)) < (xmax-2)
                self.centy= (ya > (ymin+2)) < (ymax-2)
                change=1
            endif
        endif else begin
            ; check aperture movement
            if (rada lt origapradz) then begin
                ; set mode to move (aperture)
                self.mode='move'
                self.centx= (xa > (xmin+2)) < (xmax-2)
                self.centy= (ya > (ymin+2)) < (ymax-2)
                change=1
            endif
            ; check sky movement
            if (radsky lt origosradz) then begin
                ; set mode to move (aperture)
                self.mode='movesky'
                self.skyx= (xa > (xmin+2)) < (xmax-2)
                self.skyy= (ya > (ymin+2)) < (ymax-2)
                change=1
            endif
        endelse
    endif
endif

case (self.mode) of
    'apsz':begin
        if self.skymode eq 'cent' then begin
            self.apradz=((yb-origcenty) > 5) < (self.isradz -3)
        endif else begin
            self.apradz=((yb-origcenty) > 5) < radmax
        endelse
        change=1
    end
    'issz':begin
        self.isradz=((origcenty-yb) > (self.apradz+3)) < (self.osradz-3)
        change=1
    end
    'ossz':begin
        if self.skymode eq 'cent' then begin
            self.osradz= ((yb-origcenty) > (self.isradz+3)) < radmax
        endif else begin
            self.osradz= ((yb-origskyy) > 5) < radmaxsky
        endelse
        change=1
    end
    'move':begin
        dx=xb-xa
        dy=yb-ya
        self.centx= ((xb+2) > (xmin+2)) < (xmax-2)
        self.centy= ((yb+2) > (ymin+2)) < (ymax-2)
        change=1
    end
    'movesky':begin
        dx=xb-xa
        dy=yb-ya
        self.skyx= ((xb+2) > (xmin+2)) < (xmax-2)
        self.skyy= ((yb+2) > (ymin+2)) < (ymax-2)
        change=1
    end
    'none':
endcase

if keyword_set(fin) then self.mode='none'
;if there is change
if (change ne 0) then begin
    ;get new positions in image coordinates
    newcentu=round(float(self.centx)/zoom)
    newcentv=round(float(self.centy)/zoom)
    newapradw=round(float(self.apradz)/zoom)
    newisradw=round(float(self.isradz)/zoom)
    newosradw=round(float(self.osradz)/zoom)
    newskyu=round(float(self.skyx)/zoom)
    newskyv=round(float(self.skyy)/zoom)
    ; derive new circle positions in display coordinates
    self.centx=round(float(newcentu)*zoom)
    self.centy=round(float(newcentv)*zoom)
    self.apradz=round(float(newapradw)*zoom)
    self.isradz=round(float(newisradw)*zoom)
    self.osradz=round(float(newosradw)*zoom)
    self.skyx=round(float(newskyu)*zoom)
    self.skyy=round(float(newskyv)*zoom)
    if keyword_set(fin) then begin
        self.centu=newcentu
        self.centv=newcentv
        self.apradw=newapradw
        self.isradw=newisradw
        self.osradw=newosradw
        self.skyu=newskyu
        self.skyv=newskyv
    endif
    return,1
endif else return,0

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
self.skywid=wids.sky
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
; skywid
widget_control, self.skywid, $
  set_uvalue={object:self, method:'input'}
if self.skymode eq 'cent' then begin
    widget_control, self.skywid, set_value='Cent'
endif else begin
    widget_control, self.skywid, set_value='Off'
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
for i=1,4 do begin
   widget_control, self.datawid[i], set_value=self.datatext[i-1]
endfor
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
self.datatext=string(indgen(4))
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
;circle location and sizes
self.centx=xsize/2
self.centy=ysize/2
self.apradz=10
self.isradz=20
self.osradz=30
self.centu=self.centx
self.centv=self.centy
self.apradw=self.apradz
self.isradw=self.isradz
self.osradw=self.osradz
self.skyx=xsize/4
self.skyy=ysize/2
self.mode='none'
self.skymode='cent'
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
        skywid:0L, $            ; widget id for sky button
        logwid:0L, $            ; widget id for log button
        colorwid:0L, $          ; widget id for color selector
        datawid:lonarr(5), $    ; widget ids for data displays (row, wid1, . .
        datatext:strarr(4), $   ; text for data display
        ; fit box and fit display characteristics
        boxu0:0, boxv0:0, $     ; box frame positions:   lower left corner
        boxu1:0, boxv1:0, $     ; (in image coordinates) upper right corner
                                ; (legal indices from x0 to x1)
                                ; (box is always <= 20pix)
        boxx0:0, boxy0:0, $     ; box frame positions:      lower left corner
        boxx1:0, boxy1:0, $     ; (in display coordinates)  upper right corner
                                ; boxu/v0/1~boxx/y0/1 except when
                                ; frame moved it has temporary values
        ; circle characteristics (aperture, inner sky, outer sky)
        centu:0, centv:0, $     ; center of the circles (image coordinates)
        centx:0, centy:0, $     ; center of the circles (display coordinates)
        apradw:0,apradz:0, $    ; aperture radius (image , display)
        isradw:0,isradz:0, $    ; inner sky circle radius
        osradw:0,osradz:0, $    ; outer sky circle radius
        skyu:0, skyv:0, $       ; center of sky circle (img coords)
        skyx:0, skyy:0, $       ; center of sky circle (disp coords)
        mode:'',$               ; resize/move
        skymode:'', $           ; sky circle centered or offset ('cent' / 'off')
                                ;
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

