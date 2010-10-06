; NAME:
;     CW_DRIP_XPLOT - Version 0.4
;
; PURPOSE:
;     Extraction Plot  Window compound widget
;
; CALLING SEQUENCE:
;     WidgetID = CW_DRIP_XPLOT( TOP, EXT_ID=ID, XSIZE=XS, YSIZE=YS, _EXTRA=EX)
;
; INPUTS:
;     TOP - Widget ID of the parent widget.
;     EXT_ID - Assigned index for the display
;     XSIZE - X dimension of the display windows
;     YSIZE - Y dimension of the display windows
;
; STRUCTURE:
;     {DRIP_QL, IMAGE, PROCESS, DISPMAN, LABEL, DROP_SUM, SUM, DRAW, WID,
;      DROP_FRAME, FRAME, BUTTON, XSIZE, YSIZE, INDEX}
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
;     Ext_ID - Identification of each CW created
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
;     Written by: Nirbhik Chitrakar, Ithaca College, 2006
;                  (based on xzoomplot.pro written by M. Cushing,
;                  Institute of Astronomy, UH)

;************************************************************************
;     Read files
;************************************************************************
pro drip_xplot::readfile,fits=fits,txt=txt

if keyword_set(fits) then begin
endif

if keyword_set(txt) then begin
    file=dialog_pickfile(/READ,$
                         DIALOG_PARENT=self.xzoomplot_base,$
                         Path=self.prevPath,$
                         Get_Path=prevPath,$
                         Filter='*.*')
    if keyword_set(file) then begin
        readcol,file,wave,flux
        self.prevPath=prevPath
     endif
    
endif

end

;************************************************************************
;     Save files
;************************************************************************
pro drip_xplot::writefile,fits=fits,txt=txt,ps=ps

if n_elements(*self.allwave[0]) gt 0 then begin
    if keyword_set(txt) then begin

        file=dialog_pickfile(/WRITE,$
                             DIALOG_PARENT=self.xzoomplot_base,$
                             File='Spectra01.txt',$
                             Path=self.prevPath,$
                             Get_Path=prevPath,$
                             Filter='*.*')
        if keyword_set(file) then begin
            fg_writecol,file,*self.allwave[0],*self.allflux[0]
            self.prevPath=prevPath
        endif

    endif

    if keyword_set(fits) then begin
        file=dialog_pickfile(/write,$
                             Dialog_parent=self.xzoomplot_base,$
                             file='Spectra01',$
                             path=self.prevPath,$
                             get_path=prevPath,$
                             filter='*.fits',/fix_filter)
        if keyword_set(file) then begin
            if not(strmatch(file,'*.fits')) then file=file+'.fits'
            self.prevPath=prevPath
            len=n_elements(*self.allflux[0])
            orders=(intarr(len))+1
            error=dblarr(len)
            data=[transpose(*self.allwave[0]),$
                  transpose(*self.allflux[0]),$
                  transpose(error),$
                  transpose(orders)]
            collabels=['wavelength', 'flux', 'flux_error','order']
            self.mw->print,'Written file '+file
            wr_spfits,file,data, len, collabels=collabels
        endif

    
    endif

    if keyword_set(ps) then begin

        file=dialog_pickfile(/WRITE,$
                             DIALOG_PARENT=self.xzoomplot_base,$
                             File='Spectra01',$
                             Path=self.prevPath,$
                            Get_Path=prevPath,$
                             Filter='*.ps',/Fix_FILTER)
        if keyword_set(file) then begin
            self.prevPath=prevPath
            if (strmatch(file,'*.ps')) then begin
                file=strmid(file,0,strpos(file,'.ps'))
            endif
            ps_open,file,THICK=2
            self->plotspec,/ps
            ps_close
        endif

    endif

endif

end

;************************************************************************
;     HELP
;************************************************************************
pro drip_xplot::help
;if keyword_set(nobase) then begin
;    a=a(1:*)
;    yfit = curvefit(x,y,wght,a,sigmaa,function_name = "multigaus_fnb")
;    a=[0.,a]
;endif else begin
;    yfit = curvefit(x,y,wght,a,sigmaa,function_name = "multigaus_f")
;endelse


if not xregistered('self->help') then begin

    ;get font string from common block
    common gui_os_dependent_values, largefont

    help_base = widget_base(GROUP_LEADER=self.xzoomplot_base, $
                            /COLUMN, $
                            TITLE='Extract Window Help')

    h = [['Keyboard commands:'],$
         [' '],$
         ["a - Sets the 'a'bsolute range to the current x and y range"],$
         [' '],$
         ['c - Clear mouse mode.'],$
         ['    Use to clear a zoom, fix, or remove session.'],$
         [' '],$
         ['f - Manual fit to continuum or spectral feature'],$
         [' '],$
         ['h - To lauch the help window.'],$
         [' '],$
         ['i - To zoom IN in whatever zoom mode the cursor is currently'],$
         ['    in.'],$
         [' '],$
         ["l - Manual wavelength calibration"],$
         [' '],$
         ['m - To open the control panel.  The plot parameters can then '],$
         ['    be Modified.'],$
         [' '],$
         ['o - To zoom OUT in whatever zoom mode the cursor is currently'],$
         ['    in.'],$
         [' '],$
         ['p - To plot the spectrum to a postscript file.'],$
         [' '],$
         ['w - To plot the entire spectrum'],$
         [' '],$
         ['x - Enters x zoom mode'],$
         ['    Press left mouse button at lower x value and then at upper'],$
         ['    x value.'],$
         ['y - Enters y zoom mode'],$
         ['    Press left mouse button at lower y value and then at upper'],$
         ['    y value.'],$
         ['z - Enters zoom mode'],$
         ['    Press the left mouse button in one corner of the zoom box '],$

         ['    and then move the cursor to the other corner and press the '],$
         ['    the left mouse button.'],$

         ['s - To save the extracted spectrum (note: it saves the whole'],$
         ['    extracted region and not the zoomed in)'],$
         [' ']]

    help_text = widget_text(help_base, $
                            /SCROLL, $
                            VALUE=h, $
                            XSIZE=70, $
                            YSIZE=24)

    quit = widget_button(help_base,$
                         VALUE='Done',$
                         FONT=largefont,$
                         UVALUE={object:self, method:'event',uval:'Done'},$
                         event_pro='drip_xplot_eventhand')

    ;centertlb,help_base

    widget_control, help_base, /REALIZE


; Start the Event Loop. This will be a non-blocking program.

    XManager,'help', help_base

endif

end

;************************************************************************
;     MINMAX_EVENT
;************************************************************************
pro drip_xplot::minmax_event,event

xmin = cfld(self.xmin_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return
xmin2 = crange(xmin,self.plotxrange[1],'X Min',/KLT,$
               WIDGET_ID=self.xzoomplot_base,CANCEL=cancel)
if cancel then begin

    widget_control, self.xmin_fld[0],SET_VALUE=self.plotxrange[0]
    return

endif else self.plotxrange[0] = xmin2

xmax = cfld(self.xmax_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return
xmax2 = crange(xmax,self.plotxrange[0],'X Max',/KGT,$
               WIDGET_ID=self.xzoomplot_base,CANCEL=cancel)
if cancel then begin

    widget_control, self.xmax_fld[0],SET_VALUE=self.plotxrange[1]
    return

endif else self.plotxrange[1] = xmax2

xmax = cfld(self.xmax_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return
xmax2 = crange(xmax,self.plotxrange[0],'X Max',/KGT,$
               WIDGET_ID=self.xzoomplot_base,CANCEL=cancel)
if cancel then begin

    widget_control, self.xmax_fld[0],SET_VALUE=self.plotxrange[1]
    return

endif else self.plotxrange[1] = xmax2

ymin = cfld(self.ymin_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return
ymin2 = crange(ymin,self.plotyrange[1],'Y Min',/KLT,$
               WIDGET_ID=self.xzoomplot_base,CANCEL=cancel)
if cancel then begin

    widget_control, self.ymin_fld[0],SET_VALUE=self.plotyrange[0]
    return

endif else self.plotyrange[0] = ymin2

ymax = cfld(self.ymax_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return
ymax2 = crange(ymax,self.plotyrange[0],'Y Max',/KGT,$
               WIDGET_ID=self.xzoomplot_base,CANCEL=cancel)
if cancel then begin

    widget_control, self.ymax_fld[0],SET_VALUE=self.plotyrange[1]
    return

endif else self.plotyrange[1] = ymax2

self->plotspec

end



;************************************************************************
;     WRITEDATA
;************************************************************************
pro drip_xplot::writedata

filename = dialog_pickfile(DIALOG_PARENT=self.xzoomplot_base,$
                           FILTER='*.dat',/WRITE,$
                           FILE='data.dat')

if filename ne '' then  begin

    z = where(*self.allwave[0] ge self.plotxrange[0] and $
              *self.allwave[0] le self.plotxrange[1],cnt)


    openw, lun, filename,/GET_LUN

    for i = 0,cnt-1 do printf, lun, $
      (*self.allwave[0])[z[i]],(*self.allflux[0])[z[i]]

    free_lun, lun

endif

end




;************************************************************************
;     EVENT
;************************************************************************
pro drip_xplot::event, event

widget_control, event.id,  GET_UVALUE = uvalue

case uvalue.uval of

    'CharSize': begin

        val = cfld(self.charsize_fld,4,/EMPTY,CANCEL=cancel)
        if cancel then return
        self.charsize=val
        self->plotspec

    end

    'Keyboard': begin
       if event.type eq 0 then begin
        case strtrim(event.ch,2) of

            '?': self->help

            'a': begin

                self.plotabsxrange = self.plotxrange
                self.plotabsyrange=self.plotyrange

            end

            'c': begin ; Clear

                self.cursormode = 'None'
                self.reg = !values.f_nan
                self->plotspec

            end

            'i': self->zoom,/IN

            'h': self->help ; Help

            ;'m': self->cp

            'o': self->zoom,/OUT

            'p': begin          ; Plot

;;                 {forminfo = CMPS_FORM(/INITIALIZE,$
;;                                      SELECT='Full Landscape (color)')

;;                 formInfo = CMPS_FORM(CANCEL=canceled, CREATE=create, $
;;                                      DEFAULTS=forminfo,$
;;                                      BUTTON_NAMES = ['Create PS File'],$
;;                                      PARENT=self.xzoomplot_base)

;;                 IF NOT canceled THEN BEGIN

;;                     thisDevice = !D.Name
;;                     Set_Plot, "PS"
;;                     Device, _EXTRA=formInfo
;;                     self->plotspec,/PS
;;                     Device, /CLOSE
;;                     Set_Plot, thisDevice
                        
;;                 ENDIF

               self->writefile,/ps

            end

            ;'r': self->writedata

            'w': begin

                self.plotxrange = self.plotabsxrange
                self.plotyrange = self.plotabsyrange
                self->plotspec
                self->setminmax

            end

            'x': begin

                self.cursormode = 'XZoom'
                self.reg = !values.f_nan

            end

            'y': begin

                self.cursormode = 'YZoom'
                self.reg = !values.f_nan

            end

            'z': begin ; Zoom

                self.cursormode = 'Zoom'
                self.reg = !values.f_nan

            end

            's': begin

                self->writefile,/txt

            end

            'l': begin
                ;self.cursormode='Wave Cal'
                ;print,'wavecal'
                ;self.reg=!values.f_nan
                self.wc_obj->setup
                ;widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
                self.wc_obj->start
                self.reg=!values.f_nan
            end

            'f': begin
                if (self.cursormode eq 'None') then begin
                    self.cf_obj->setup
                    self.cf_obj->create,0
                    widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
                    self.reg=!values.f_nan
                endif
            end

            else:

        endcase
        endif

    end

    'Done': widget_control, event.top, /DESTROY

    'Spectrum Color': begin

        self.color = event.index+1
        self->plotspec

    end

    'Thick': begin

        label = cfld(self.thick_fld,7,/EMPTY,CANCEL=cancel)
        if cancel then return
        self.thick = label
        self->plotspec

    end


    'Title': begin

        label = cfld(self.title_fld,7,/EMPTY,CANCEL=cancel)
        if cancel then return
        self.title = label
        self->plotspec

    end

    'X Title': begin

        label = cfld(self.xtitle_fld,7,/EMPTY,CANCEL=cancel)
        if cancel then return
        self.xtitle = label
        self->plotspec

    end

    'Y Title': begin

        label = cfld(self.ytitle_fld,7,/EMPTY,CANCEL=cancel)
        if cancel then return
        self.ytitle = label
        self->plotspec

    end

endcase

cont:

end

;************************************************************************
;     ZOOM
;************************************************************************
pro drip_xplot::zoom,IN=in,OUT=out

delabsx = self.plotabsxrange[1]-self.plotabsxrange[0]
delx    = self.plotxrange[1]-self.plotxrange[0]

delabsy = self.plotabsyrange[1]-self.plotabsyrange[0]
dely    = self.plotyrange[1]-self.plotyrange[0]

xcen = self.plotxrange[0]+delx/2.
ycen = self.plotyrange[0]+dely/2.

case self.cursormode of

    'XZoom': begin

        z = alog10(delabsx/delx)/alog10(2)
        if keyword_set(IN) then z = z+1 else z=z-1
        hwin = delabsx/2.^z/2.
        self.plotxrange = [xcen-hwin,xcen+hwin]
        self->plotspec

    end

    'YZoom': begin

        z = alog10(delabsy/dely)/alog10(2)
        if keyword_set(IN) then z = z+1 else z=z-1
        hwin = delabsy/2.^z/2.
        self.plotyrange = [ycen-hwin,ycen+hwin]
        self->plotspec

    end

    'Zoom': begin

        z = alog10(delabsx/delx)/alog10(2)
        if keyword_set(IN) then z = z+1 else z=z-1
        hwin = delabsx/2.^z/2.
        self.plotxrange = [xcen-hwin,xcen+hwin]

        z = alog10(delabsy/dely)/alog10(2)
        if keyword_set(IN) then z = z+1 else z=z-1
        hwin = delabsy/2.^z/2.
        self.plotyrange = [ycen-hwin,ycen+hwin]

        self->plotspec

    end

    else:

endcase
self->setminmax

end

;************************************************************************
;     PLOTWIN_EVENT
;************************************************************************

pro drip_xplot::plotwin_event, event

common gui_os_dependent_values, largefont

widget_control, event.id,  GET_UVALUE = uvalue

device,decomposed=1

;  Check to see if it is a TRACKING event.

if strtrim(tag_names(event,/STRUCTURE_NAME),2) eq 'WIDGET_TRACKING' then begin

    if event.enter eq 0 then widget_control, self.keyboard, SENSITIVE=0
    goto, cont

endif

widget_control, self.keyboard, /INPUT_FOCUS, /SENSITIVE
wset, self.plotwin_wid

!p = self.pscale
!x = self.xscale
!y = self.yscale
x  = event.x/float(self.plotsize[0])
y  = event.y/float(self.plotsize[1])
xy = convert_coord(x,y,/NORMAL,/TO_DATA)

if event.type eq 1 then begin

    if self.cursormode eq 'None' then goto, cont
    z = where(finite(self.reg) eq 1,count)
    if count eq 0 then begin

        wset, self.pixmap_wid
        self.reg[*,0] = xy[0:1]
        case self.cursormode of

            'XZoom': plots, [event.x,event.x],$
              [0,self.plotsize[1]],COLOR=self.linecolor[0],$
              /DEVICE,LINESTYLE=1,THICK=2

            'YZoom': plots, [0,self.plotsize[0]],$
              [event.y,event.y],COLOR=self.linecolor[0],$
              /DEVICE,LINESTYLE=1,THICK=2

            'Wave Cal' : begin
               wset,(self.wc_obj).lastmap
               device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                      self.pixmap_wid]
               wset, self.pixmap_wid
               plots, [event.x,event.x],$
                      [0,self.plotsize[1]],COLOR=self.linecolor[0],$
                      /DEVICE,LINESTYLE=1,THICK=2
               widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
               self.wc_obj->setdata,eventxy=[event.x,event.y]
               tabinv, *self.fullwave,xy[0],idx
               idx = round(idx)
               self.wc_obj->setdata,xy=[(*self.fullpixel)[idx],xy[1]]
               print,'xy',xy
               widget_control,(self.wc_obj).store_button, /sensitive
               widget_control,(self.wc_obj).wc_fld,/input_focus
               
            end
            'Click Fit':begin
                plots,[event.x-5,event.x+5],$
                  [event.y,event.y],$
                  /DEVICE,THICK=2
                plots, [event.x,event.x],$
                  [event.y-5,event.y+5],$
                  /DEVICE,THICK=2
                ;widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
                self.cf_obj->setdata,clickx=xy[0]
                self.cf_obj->setdata,clicky=xy[1]
                self.reg=!values.f_nan
             end
            else:

        endcase
        wset, self.plotwin_wid
        device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                      self.pixmap_wid]

    endif else begin

        self.reg[*,1] = xy[0:1]
        case self.cursormode of

            'XZoom': self.plotxrange = [min(self.reg[0,*],MAX=max),max]

            'YZoom': self.plotyrange = [min(self.reg[1,*],MAX=max),max]

            'Zoom': begin

                self.plotxrange = [min(self.reg[0,*],MAX=max),max]
                self.plotyrange = [min(self.reg[1,*],MAX=max),max]

            end

            'Wave Cal' : begin
            end

            'Gauss Fit': begin
                widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
                box_xy=[[0,0],[0,0]]
                for i=0,1 do begin
                    tabinv,*self.allwave[0],self.reg[0,i],indx
                    indx=round(indx)
                    box_xy[0,i]=indx
                    tabinv,*self.allwave[0],self.reg[1,i],indx
                    indx=round(indx)
                    box_xy[1,i]=indx
                endfor
                
                self.cf_obj->setdata, box_xy=[[min(box_xy[0,*],max=maxx),$
                                               min(box_xy[1,*],max=maxy)],$
                                              [maxx,maxy]]
                self.cf_obj->findVal
            end

            'Base Fit':begin
                widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
                box_xy=[[0,0],[0,0]]

                for i=0,1 do begin
                    tabinv,*self.allwave[0],self.reg[0,i],indx
                    indx=round(indx)
                    box_xy[0,i]=indx
                    tabinv,*self.allwave[0],self.reg[1,i],indx
                    indx=round(indx)
                    box_xy[1,i]=indx
                endfor
                
                self.cf_obj->setdata, box_xy=[[min(box_xy[0,*],max=maxx),$
                                               min(box_xy[1,*],max=maxy)],$
                                              [maxx,maxy]]
                self.cf_obj->basefit
                
            end
;if keyword_set(nobase) then begin
;    a=a(1:*)
;    yfit = curvefit(x,y,wght,a,sigmaa,function_name = "multigaus_fnb")
;    a=[0.,a]
;endif else begin
;    yfit = curvefit(x,y,wght,a,sigmaa,function_name = "multigaus_f")
;endelse

            'Click Fit':begin                                   
            end

            else:

        endcase
        if (self.cursormode ne 'Gauss Fit'and $
            self.cursormode ne 'Base Fit') then begin
            self->plotspec
            self->setminmax
        end

        case self.cursormode of
            'Wave Cal':
            'Gauss Fit':
            'Click Fit':
            else: self.cursormode='None'
        end

    endelse

endif

;  Copy the pixmaps and draw the cross hair or zoom lines.

wset, self.plotwin_wid
device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
              self.pixmap_wid]

case self.cursormode of

    'XZoom': plots, [event.x,event.x],[0,self.plotsize[1]],$
      COLOR=self.linecolor[0],/DEVICE

    'YZoom': plots, [0,self.plotsize[0]],[event.y,event.y],$
      COLOR=self.linecolor[0],/DEVICE

    'Zoom': begin

        plots, [event.x,event.x],[0,self.plotsize[1]],$
          COLOR=self.linecolor[0],/DEVICE
        plots, [0,self.plotsize[0]],[event.y,event.y],$
          COLOR=self.linecolor[0],/DEVICE
        xy = convert_coord(event.x,event.y,/DEVICE,/TO_DATA)
        plots,[self.reg[0,0],self.reg[0,0]],[self.reg[1,0],xy[1]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
        plots, [self.reg[0,0],xy[0]],[self.reg[1,0],self.reg[1,0]],$
          LINESTYLE=2,COLOR=self.linecolor[0]

    end
;if keyword_set(nobase) then begin
;    a=a(1:*)
;    yfit = curvefit(x,y,wght,a,sigmaa,function_name = "multigaus_fnb")
;    a=[0.,a]
;endif else begin
;    yfit = curvefit(x,y,wght,a,sigmaa,function_name = "multigaus_f")
;endelse

    'Wave Cal':begin
        plots, [event.x,event.x],[0,self.plotsize[1]],$
          COLOR=self.linecolor[0],/DEVICE
    end

    'Gauss Fit': begin
        plots, [event.x,event.x],[0,self.plotsize[1]],$
          COLOR=self.linecolor[0],/DEVICE
        plots, [0,self.plotsize[0]],[event.y,event.y],$
          COLOR=self.linecolor[0],/DEVICE
        xy = convert_coord(event.x,event.y,/DEVICE,/TO_DATA)
        plots,[self.reg[0,0],self.reg[0,0]],[self.reg[1,0],xy[1]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
        plots, [self.reg[0,0],xy[0]],[self.reg[1,0],self.reg[1,0]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
    end
    'Base Fit': begin
        plots, [event.x,event.x],[0,self.plotsize[1]],$
          COLOR=self.linecolor[0],/DEVICE
        plots, [0,self.plotsize[0]],[event.y,event.y],$
          COLOR=self.linecolor[0],/DEVICE
        xy = convert_coord(event.x,event.y,/DEVICE,/TO_DATA)
        plots,[self.reg[0,0],self.reg[0,0]],[self.reg[1,0],xy[1]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
        plots, [self.reg[0,0],xy[0]],[self.reg[1,0],self.reg[1,0]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
    end
    'Click Fit':begin
         plots, [event.x,event.x],[0,self.plotsize[1]],$
          COLOR=self.linecolor[0],/DEVICE
        plots, [0,self.plotsize[0]],[event.y,event.y],$
          COLOR=self.linecolor[0],/DEVICE
        xy = convert_coord(event.x,event.y,/DEVICE,/TO_DATA)
        plots,[self.reg[0,0],self.reg[0,0]],[self.reg[1,0],xy[1]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
        plots, [self.reg[0,0],xy[0]],[self.reg[1,0],self.reg[1,0]],$
          LINESTYLE=2,COLOR=self.linecolor[0]
    end

    else: begin

        plots, [event.x,event.x],[0,self.plotsize[1]],$
          COLOR=self.linecolor[0],/DEVICE
        plots, [0,self.plotsize[0]],[event.y,event.y],$
          COLOR=self.linecolor[0],/DEVICE
    end
endcase

;  Update cursor position.

if self.cursor then begin
    idx = 0
    tabinv, *self.fullwave,xy[0],idx
    tabinv,*self.allwave[0],xy[0],idy
    idx = round(idx)
    idy = round (idy)
    label = 'Pixels X: '+strtrim( (*self.fullpixel)[idx],2)+$
      ', Y:'+strtrim( (*self.allflux[0])[idy],2)
    label = label+'   Spectrum X: '+strtrim( (*self.fullwave)[idx],2)+$
      ', Y:'+strtrim( (*self.allflux[0])[idy],2)
    widget_control,self.message,SET_VALUE=label

endif

cont:

device,decomposed=0

end


;******************************************************************************
;     SETMINMAX
;******************************************************************************

pro drip_xplot::setminmax

widget_control, self.xmin_fld[1],SET_VALUE=strtrim(self.plotxrange[0],2)
widget_control, self.xmax_fld[1],SET_VALUE=strtrim(self.plotxrange[1],2)
widget_control, self.ymin_fld[1],SET_VALUE=strtrim(self.plotyrange[0],2)
widget_control, self.ymax_fld[1],SET_VALUE=strtrim(self.plotyrange[1],2)

end

;******************************************************************************
;     PlotSpec
;******************************************************************************
pro drip_xplot::plotspec,PS=ps

!p.multi = 0
device,decomposed=1

;for ps plot ignoring for now.
color=self.color
if color eq 1 then color=(keyword_set(PS) eq 1) ? 0:1

if keyword_set(PS) then begin

    plot,*self.allwave[0],*self.allflux[0],/XSTY,/YSTY,$
      YRANGE=self.plotyrange,XRANGE=self.plotxrange,PSYM=10,$
      XTITLE=self.xtitle,YTITLE=self.ytitle,TITLE=self.title,$
      /NODATA,CHARTHICK=self.thick,THICK=self.thick,$
      CHARSIZE=self.charsize,XTHICK=self.thick,YTHICK=self.thick
    for i=0,self.oplotn do begin
        oplot, *self.allwave[i],*self.allflux[i],COLOR=color,THICK=self.thick,$
          PSYM=10
    endfor
    goto, cont

    endif
if keyword_set(num) then begin
    ;setting up the axes
    num=num-1
    plot,*self.allwave[num],*self.allflux[num],$
      /XSTY,/YSTY,YRANGE=self.plotyrange,$
      XRANGE=self.plotxrange,/NODATA,CHARTHICK=self.thick,$
      THICK=self.thick,PSYM=10,XTITLE=self.xtitle,YTITLE=self.ytitle,$
      TITLE=self.title,CHARSIZE=self.charsize,XTHICK=self.thick,$
      YTHICK=self.thick

    ;ploting one or more spectrum
    oplot, *self.allwave[num],*self.allflux[num],COLOR=self.linecolor[i],$
          THICK=self.thick,PSYM=10
endif

wset, self.pixmap_wid
erase

;setting up the axes
plot,*self.allwave[0],*self.allflux[0],/XSTY,/YSTY,YRANGE=self.plotyrange,$
  XRANGE=self.plotxrange,/NODATA,CHARTHICK=self.thick,$
  THICK=self.thick,PSYM=10,XTITLE=self.xtitle,YTITLE=self.ytitle,$
  TITLE=self.title,CHARSIZE=self.charsize,XTHICK=self.thick,$
  YTHICK=self.thick

;ploting one or more spectrum
for i=0,self.oplotn do begin
    oplot, *self.allwave[i],*self.allflux[i],COLOR=self.linecolor[i],$
      THICK=self.thick,PSYM=10
endfor

wset, self.plotwin_wid
erase
device, copy=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
              self.pixmap_wid]
self.xscale = !x
self.yscale = !y
self.pscale = !p
self.cursor = 1

self->setminmax

cont:

device,decomposed=0

end
;******************************************************************************
;     Set Data
;******************************************************************************
function drip_xplot::getdata, buffer=buffer,$
                   plotwin_wid=plotwin_wid, pltwin=plotwin, $
                   pixmap_wid=pixmap_wid, $
                   xmin_fld=xmin_fld, xmax_fld=xmax_fld, $
                   ymin_fld=ymin_fld, ymax_fld=ymax_fld, $
                   message=message, keyboard=keyboard, $
                   xzoomplot_base=xzoomplot_base, plotsize=plotsize,$
                   linecolor=linecolor, oplotn=oplotn, no_oplotn=no_oplotn,$
                   allwave=allwave, allpixel=allpixel, allflux=allflux,$
                   mw=mw,cursormode=cursormode


if keyword_set(buffer) then return, self.buffer

if keyword_set(plotwin_wid) then return, self.plotwin_wid
if keyword_set(plotwin) then return, self.plotwin
if keyword_set(pixmap_wid)  then return, self.pixmap_wid

if keyword_set(xmin_fld) then return, self.xmin_fld
if keyword_set(xmax_fld) then return, self.xmax_fld
if keyword_set(ymin_fld) then return, self.ymin_fld
if keyword_set(ymax_fld) then return, self.ymax_fld

if keyword_set(message) then return, self.message
if keyword_set(keyboard) then return, self.keyboard
if keyword_set(xzoomplot_base) then return, self.xzoomplot_base
if keyword_set(plotsize) then return, self.plotsize
if keyword_set(linecolor) then return, self.linecolor[0]

if keyword_set(allwave) then return, self.allwave
if keyword_set(oplotn) then return, self.oplotn
if keyword_set(allflux) then return, self.allflux
if keyword_set(allpixel) then return, self.allpixel
if keyword_set(mw) then return,self.mw
if keyword_set(cursormode) then return, self.cursormode

end

;******************************************************************************
;     Set Data
;******************************************************************************
pro drip_xplot::setdata, buffer=buffer,$
              plotwin_wid=plotwin_wid, pltwin=plotwin, $
              pixmap_wid=pixmap, $
              xmin_fld=xmin_fld, xmax_fld=xmax_fld, $
              ymin_fld=ymin_fld, ymax_fld=ymax_fld, $
              message=message, keyboard=keyboard, $
              xzoomplot_base=xzoomplot_base, plotsize=plotsize,$
              opixel=opixel, owave=owave, oflux=oflux, $
              linecolor=linecolor, oplotn=oplotn, no_oplotn=no_oplotn, $
              xtitle=xtitle,ytitle=ytitle,title=title,cursormode=cursormode,$
              plotabsxrange=plotabsxrange,plotxrange=plotxrange,$
              reg=reg,mw=mw,$
              tempflux=tempflux,tempwave=tempwave



if keyword_set(buffer) then self.buffer= buffer
if keyword_set(reg) then self.reg=reg
if keyword_set(plotwin_wid) then self.plotwin_wid=plotwin_wid
if keyword_set(plotwin) then self.plotwin=plotwin
if keyword_set(pixmap_wid)  then self.pixmap=pixmap
if keyword_set(xmin_fld) then self.xmin_fld= xmin_fld
if keyword_set(xmax_fld) then self.xmax_fld=xmax_fld
if keyword_set(ymin_fld) then self.ymin_fld=ymin_fld
if keyword_set(ymax_fld) then self.ymax_fld=ymax_fld
if keyword_set(message) then self.message=message
if keyword_set(keyboard) then self.keyboard=keyboard
if keyword_set(xzoomplot_base) then self.xzoomplot_base=xzoomplot_base
if keyword_set(plotsize) then self.plotsize=plotsize
if keyword_set(xtitle) then self.xtitle=xtitle
if keyword_set(ytitle) then self.ytitle=ytitle
if keyword_set(title) then self.title=title
if keyword_set(cursormode) then self.cursormode=cursormode
if keyword_set(plotabsxrange)then self.plotabsxrange=plotabsxrange
if keyword_set(plotxrange) then self.plotxrange=plotxrange
if keyword_set(mw) then self.mw=mw
if keyword_set(owave) then begin
    self.allwave[0]=owave
endif else if keyword_set(opixel) and not(keyword_set(owave)) then begin
    self.allwave[0]=opixel
endif

if keyword_set(opixel) then begin
    self.allpixel[0]=opixel
endif else if keyword_set(owave) and not(keyword_set(opixel)) then begin
    self.allpixel[0]=owave
endif

if keyword_set(oflux) then self.allflux[0]=oflux
if keyword_set(linecolor) then self.linecolor[self.oplotn]=linecolor
if keyword_set(oplotn) then self.oplotn=self.oplotn+1
if keyword_set(no_oplotn) then self.oplotn=0
if keyword_set(tempflux) then self.tempflux=tempflux
if keyword_set(tempwave) then self.tempwave=tempwave
;if keyword_set(allwave) then *self.allwave[0]=allwave
end
;******************************************************************************
;     CLEANUP
;******************************************************************************

pro drip_xplot::cleanup
ptr_free, self.allflux
ptr_free, self.allwave
ptr_free, self.allpixel
obj_destroy, self.wc_obj
end


;******************************************************************************
;     Fullwave_maker
;******************************************************************************
pro drip_xplot::fullwave_maker,opixel,owave,reset=reset

if (n_elements(*self.fullwave) eq 0) or keyword_set(reset) then begin
   *self.fullpixel=opixel
   *self.fullwave=owave
endif else begin
   ;pixels
   fpixel=*self.fullpixel
   if (fpixel(0) lt opixel(0)) then begin
      n=n_elements(fpixel)
      where=where(opixel gt fpixel(n-1))     
      if (where[0] ne -1) then newfpixel=[fpixel,opixel(where)]
   endif else begin
      n=n_elements(opixel)
      where=where(fpixel gt opixel(n-1))     
      print,'full: ',fpixel(0),opixel(0),owave(0)
      if (where[0] ne -1) then newfpixel=[opixel,fpixel(where)]
   endelse
   if keyword_set(newfpixel) then begin
      *self.fullpixel=newfpixel
   endif else *self.fullpixel=opixel

   ;wave
   fwave=*self.fullwave
   if (fwave(0) lt owave(0)) then begin
      n=n_elements(fwave)
      where=where(owave gt fwave(n-1))     
      if (where[0] ne -1) then newfwave=[fwave,owave(where)]
   endif else begin
      n=n_elements(owave)
      where=where(fwave gt owave(n-1))     
      if (where[0] ne -1) then newfwave=[owave,fwave(where)]
   endelse
   if keyword_set(newfwave) then begin
      *self.fullwave=newfwave
   endif else *self.fullwave=owave
endelse



end

;******************************************************************************
;     DRAW
;******************************************************************************

pro drip_xplot::draw,opixel,oflux,OPLOT=oplot, analobj= anal

  device,decomposed=1
  
  if self.oplotn gt 0 then begin
     *self.allpixel[self.oplotn]=opixel
     *self.allwave[self.oplotn]=opixel
     *self.allflux[self.oplotn]=oflux
     if keyword_set(anal) then begin
        self.analobj[self.oplotn]=anal
     endif else begin
        if keyword_set(self.analobj[0]) then begin
           self.analobj[self.oplotn]->setdata,owave=opixel, oflux=oflux
        endif
     endelse

  endif else begin
     *self.allpixel[0]=opixel
     *self.allwave[0]=opixel
     *self.allflux[0]=oflux
     if keyword_set(anal) then begin
        self.analobj[0]=anal
     endif else begin
        if keyword_set(self.analobj[0]) then begin
           self.analobj[0]->setdata,owave=opixel, oflux=oflux
           endif
     endelse
  endelse
  
  if self.oplotn eq 0 then begin
     self.xtitle='Pixels'
     self.ytitle='Intensity'
     self.plotabsxrange = [min(opixel,MAX=xmax,/NAN),xmax]
     min=min(oflux,MAX=max,/NAN)
     ;to make the plot not tight on the axis
     dy=(max-min)*.05
     self.plotabsyrange = [min-dy,max+dy]
     self.plotxrange = self.plotabsxrange
     self.plotyrange = self.plotabsyrange
     self->fullwave_maker,opixel,opixel,/reset
  endif else begin
     ;check if the new data has wider range
     xmin=min(opixel,max=xmax,/NAN)
     ymin=min(oflux,max=ymax,/NAN)
     if (self.plotabsxrange(0) gt xmin) then self.plotabsxrange(0)=xmin
     if (self.plotabsxrange(1) lt xmax) then self.plotabsxrange(1)=xmax
     if (self.plotabsyrange(0) gt ymin) then self.plotabsyrange(0)=ymin
     if (self.plotabsyrange(1) lt ymax) then self.plotabsyrange(1)=ymax
     self.plotxrange = self.plotabsxrange
     self.plotyrange = self.plotabsyrange
     self->plotspec
     self->setminmax
     self->fullwave_maker,opixel,opixel
  endelse


  wset, self.pixmap_wid
  if self.oplotn eq 0 then begin
     erase
     plot,*self.allwave[0],*self.allflux[0],/XSTY,/YSTY,YRANGE=self.plotyrange,$
          XRANGE=self.plotxrange,/NODATA,CHARTHICK=self.thick,$
          THICK=self.thick,PSYM=10,XTITLE=self.xtitle,YTITLE=self.ytitle,$
          TITLE=self.title,CHARSIZE=self.charsize,XTHICK=self.thick,$
          YTHICK=self.thick
  endif
  
  for i=0,self.oplotn do begin
     oplot, *self.allwave[i],*self.allflux[i],COLOR=self.linecolor[i],$
            THICK=self.thick, $
            PSYM=10
  endfor
  
  wset, self.plotwin_wid
  erase

  device, copy=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                self.pixmap_wid]
  
  self.xscale = !x
  self.yscale = !y
  self.pscale = !p
  self.cursor = 1
  
  self->setminmax
  widget_control,self.plotwin,/SENSITIVE,/INPUT_FOCUS

  device,decomposed=0
end

;******************************************************************************
;     START
;******************************************************************************
pro drip_xplot::start,something

device,RETAIN=2
window, /Free, /pixmap, xsize=self.plotsize[0], ysize=self.plotsize[1]
self.pixmap_wid=!d.window

widget_control,self.plotwin,get_value=wid
self.plotwin_wid=wid
widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0

;create object
self.wc_obj=obj_new('drip_xplot_wavecal', self)
self.cf_obj=obj_new('drip_xplot_clickfit',self)

end

;******************************************************************************
;     INIT
;******************************************************************************
function drip_xplot::INIT

;r
self.cursormode='none'

;data
self.allwave=ptrarr(20,/allocate_heap)
self.allflux=ptrarr(20,/allocate_heap)
self.allpixel=ptrarr(20,/allocate_heap)
self.fullwave=ptr_new(/allocate_heap)
self.fullpixel=ptr_new(/allocate_heap)
self.tempflux=ptr_new(/allocate_heap)
self.tempwave=ptr_new(/allocate_heap)

;properties
self.charsize=1.0
self.pscale=!p
self.xscale=!x
self.yscale=!y
self.thick=1
self.reg=[[!values.f_nan,!values.f_nan],[!values.f_nan,!values.f_nan]]

common gui_config_info, config
self.prevPath=getpar(config,'loadfitspath')

self.cursormode='None'

return, 1

end


;******************************************************************************
;     DRIP_EXT__DEFINE
;******************************************************************************

pro drip_xplot__define

struct={drip_xplot, $
        $;widget ids
        charsize_fld:[0L,0L],$  ;widget id for character size field
        keyboard:0L,$           ;widget id for invisible keyboard field
        message:0L,$            ;widget id for message field
        plotwin:0,$             ;widget id for the draw widget
        pixmap_wid:0L,$         ;widget id for the pixmap
        plotwin_wid:0L,$        ;widget id for plot window
        speccolor_dl:0,$        ;widget id and value for speccolor field
        thick_fld:[0L,0L],$     ;widget id and value for thickness field
        title_fld:[0L,0L],$     ;widget id and value for title field
        xtitle_fld:[0L,0L],$    ;widget id and value for xtitle field
        ytitle_fld:[0L,0L],$    ;widget id and value for ytitle field
        xzoomplot_base:0L,$     ;widget id for the base that holds all
        xmin_fld:[0L,0L],$      ;widget id and value for xmin field
        xmax_fld:[0L,0L],$      ;widget id and value for xmax field
        ymin_fld:[0L,0L],$      ;widget id and value for ymin field
        ymax_fld:[0L,0L],$      ;widget id and value for ymax field
        ylog_bg:0L,$
        $;r
        cursormode:'',$         ;cursor mode
        oplotn:0,$              ;number of oplots
        $;data pointers
        allflux:ptrarr(20),$    ;all y data
        allwave:ptrarr(20),$    ;all x data in wavelengths (initially pixels)
        allpixel:ptrarr(20),$   ;all x data in pixels
        fullpixel:ptr_new(),$   ;single array of pixels
        fullwave:ptr_new(),$    ;single array of wavelengths
        tempflux:ptr_new(),$    ;temp y data pointer
        tempwave:ptr_new(),$    ;temp x data pointer
        $;properties
        buffer:[0.,0.],$        ;buffer
        charsize:0,$            ;character size
        color:0L,$              ;color for ps plot(***ignore)
        linecolor:lonarr(100),$ ;color of the plot and lines
        cursor:0,$              ;***cursor
        plotabsxrange:[0.,0.],$ ;default x-range
        plotabsyrange:[0.,0.],$ ;default y-range
        plotxrange:[0.,0.],$    ;current x-range
        plotyrange:[0.,0.],$    ;current y-range
        plotsize:[0,0],$        ;plot window size
        pscale:!p,$             ;!p system variable
        xscale:!x,$             ;!x system variable
        yscale:!y,$             ;!y system variable
        thick:0,$               ;line thickness
        title:'',$              ;title of the graph
        xtitle:'',$             ;x-axis title
        ytitle:'',$             ;y-axis title
        prevPath:'',$           ;previous location where saved
        reg:[[!values.f_nan,!values.f_nan],[!values.f_nan,!values.f_nan]],$
        $                       ;registry to hold values for x/y/zoom
        $;objects
        analobj:objarr(20),$    ;corresponding anal objects
        wc_obj:obj_new(),$      ;wave callibration object
        cf_obj:obj_new(),$      ;click fit object
        mw:obj_new()$           ;message window
       }

end


;******************************************************************************
;     CW Definition: EVENTHANDLER / CLEANUP / CREATING FUNCTION
;******************************************************************************

pro drip_xplot_cleanup, id
widget_control, id, get_uvalue=obj
obj_destroy, obj
end


pro drip_xplot_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
;print,'event handled'
end


function cw_drip_xplot, top, xsize=xs, ysize=ys, ext_id=id,_extra=ex,mw=mw

obj= obj_new('drip_xplot') ;associated object
help,obj

;get font string from common block
common gui_os_dependent_values, largefont
;lay out widgets
tlb = widget_base(top, /frame, /column)

base1=widget_base(tlb, $
                  kill_notify='drip_xplot_cleanup', $
                  /frame)

keyboard = widget_text (tlb, $
                        /all_events, $
                        scr_xsize=1, $
                        scr_ysize=1, $
                        event_pro='drip_xplot_eventhand', $
                        uvalue={object:obj,method:'event',uval:'Keyboard'},$
                        value = '')

message = widget_text (tlb, $
                       ysize=1)

col_base = widget_base (tlb, $
                        /column, $
                        /align_center)

plotwin = widget_draw (col_base, $
                       xsize=xs, $
                       ysize=ys, $
                       /tracking_events, $
                       /button_events, $
                       /motion_events, $
                       uvalue={object:obj,$
                               method:'plotwin_event',$
                               uval:'plotwin1'},$
                       event_pro='drip_xplot_eventhand')

row_base = widget_base (col_base, $
                        /frame, $
                        /row)
;x
xmin = coyote_field2(row_base, $
                     title = 'X Min:', $
                     xsize = 8, $
                     event_pro='drip_xplot_eventhand', $
                     /cr_only, $
                     uvalue={object:obj,$
                             method:'minmax_event',$
                             uval:'xmin'},$
                     textid = textid)
xmin_fld = [xmin, textid]

xmax = coyote_field2(row_base, $
                     title = 'X Max:', $
                     xsize = 8, $
                     event_pro='drip_xplot_eventhand', $
                     /cr_only, $
                     uvalue={object:obj,$
                             method:'minmax_event',$
                             uval:'xmax'},$
                     textid = textid)
xmax_fld = [xmax, textid]
;y
ymin = coyote_field2(row_base, $
                     title = 'Y Min:', $
                     xsize = 8, $
                     event_pro='drip_xplot_eventhand', $
                     /cr_only, $
                     uvalue={object:obj,$
                             method:'minmax_event',$
                             uval:'ymin'},$
                     textid = textid)
ymin_fld = [ymin, textid]

ymax = coyote_field2(row_base, $
                     title = 'Y Max:', $
                     xsize = 8, $
                     event_pro='drip_xplot_eventhand', $
                     /cr_only, $
                     uvalue={object:obj,$
                             method:'minmax_event',$
                             uval:'ymax'},$
                     textid = textid)
ymax_fld = [ymax, textid]

;get plotwin id
widget_control, plotwin, get_value=x
plotwin_wid = x

;plotsize
plotsize=findgen(2)
plotsize=[xs,ys]

;get sizes for things
widget_geom=widget_info(tlb, /geometry)
buffer=findgen(2)
buffer[0]= widget_geom.xsize-xs
buffer[1]= widget_geom.ysize-ys


obj-> setdata, buffer=buffer,$
  plotwin_wid=plotwin_wid, pltwin=plotwin, $
  xmin_fld=xmin_fld, xmax_fld=xmax_fld, $
  ymin_fld=ymin_fld, ymax_fld=ymax_fld, $
  message=message, keyboard=keyboard, $
  xzoomplot_base=tlb, plotsize=plotsize,mw=mw

widget_control,base1,set_uvalue=obj



return, tlb
end
