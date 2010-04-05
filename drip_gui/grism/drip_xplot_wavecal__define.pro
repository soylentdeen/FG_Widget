;************************************************************************
;    Save Solutions
;************************************************************************
pro drip_xplot_wavecal::save
end

;************************************************************************
;     Wave Length Calibration
;************************************************************************
pro drip_xplot_wavecal::wavecal,event

;self->event

print,'user_value',*self.user_value
print,'x_value',*self.x_value
user_value=*self.user_value
x_value=*self.x_value

;get end values to not let the fit blow upt
;do linear fit to get the end values
order=1
coeff=fg_poly_fit(x_value,user_value,order,status=status)
fit=0
for i=0,order do begin
    fit = fit + coeff[i]*(*(self.allwave[0])^i)
endfor
num=n_elements(*self.allwave[0])-1
x_value=[(*self.allwave[0])[0],x_value,(*self.allwave[0])[num]]
user_value=[fit[0],user_value,fit[num]]

;now do a 3rd order fit to fit the user values
order=3
coeff=fg_poly_fit(x_value,user_value,order,status=status)
self.mw->print,'Wave Length Calibration'
self.mw->print,'Coefficients (in increasing order): '
self.mw->print,string(coeff,/PRINT)
fit=0
for n=0,self.oplotn do begin
   for i=0,order do begin
      fit = fit + coeff[i]*(*(self.allwave[n])^i)
   endfor
   *(self.allwave[n])=fit
   endfor
self.xplot->fullwave_maker,*(self.allpixel[0]),*(self.allwave[0]),/reset
for n=1,self.oplotn do begin
   self.xplot->fullwave_maker,*(self.allpixel[n]),*(self.allwave[n])
endfor


self.xplot->setdata,plotabsxrange=[min(*(self.allwave[0]),max=max),max]
self.xplot->setdata,plotxrange=[min(*(self.allwave[0]),max=max),max]
self.xplot->setdata,xtitle='Wavelength (!7l!Xm)'
self.xplot->plotspec
self.xplot->setdata,cursormode='None'

;freeing pointers for new run
ptr_free,self.user_value
self.user_value=ptr_new(/allocate_heap)
ptr_free,self.x_value
self.x_value=ptr_new(/allocate_heap)

self->cancel

end

;*** Comments by MB ***
;for i=0,oplotn-1 do begin
;    *(allwave[i])=(*(allwave[i])-cf1(0))/cf1(1)
;endfor
;{name='specdata', oplotn:2, pixel1:[0.0,1.0 . . .],
; pixel2:[albadlfasdf], wave1:[ 29035739457 ], wave2, flux1, flux2,
; flux3
;wave=dataman->getelement('specdata','wave'+strtrim(string(i),2))
;datamen->setelement,'specdata','wave'+strtrim(string(i),2),wave

;************************************************************************
;     Undo
;************************************************************************
pro drip_xplot_wavecal::undo
  if n_elements(*self.user_value) eq 1 then begin
     ;removing the last dotted line
     ;last to pixel map
     wset,self.pixmap_wid
     device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                   self.lastmap]
     ;pixelmap to plot window
     wset,self.plotwin_wid          
     device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                   self.pixmap_wid]
     ;freeing and remaking pointer
     ptr_free,self.user_value
     self.user_value=ptr_new(/allocate_heap)
     ptr_free,self.x_value
     self.x_value=ptr_new(/allocate_heap)
     ;making display sensitive again
     widget_control,self.plotwin,/SENSITIVE,/INPUT_FOCUS
     self.xplot->setdata,reg=!values.f_nan
  endif else if n_elements(*self.user_value) gt 1 then begin
     ;removing the last dotted line
     ;last to pixel map
     wset,self.pixmap_wid
     device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                   self.lastmap]
     ;pixelmap to plot window
     wset,self.plotwin_wid
     device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                   self.pixmap_wid]
     ;removing last data points
     n=n_elements(*self.user_value)
     *self.user_value=(*self.user_value)[0:n-2]
     *self.x_value=(*self.x_value)[0:n-2]
     ;making display sensitive again
     widget_control,self.plotwin,/SENSITIVE,/INPUT_FOCUS
     self.xplot->setdata,reg=!values.f_nan
     widget_control,self.undo_button, sensitive=0
  endif
  

end

;************************************************************************
;     Button Event
;************************************************************************
pro drip_xplot_wavecal::button_event,event

  widget_control,event.id,get_uvalue=uvalue
  
  case uvalue.uval of
     'Cancel':begin
        self->cancel
     end
     'WaveCal Undo':begin
        self->undo
     end
     
  endcase
  
end

;************************************************************************
;     Events
;************************************************************************
pro drip_xplot_wavecal::event,event
  widget_control,self.wc_fld[0], get_value=wave
  if keyword_set(wave[0]) then begin
                                ;user input of the wavelength
     if n_elements(*self.user_value) eq 0 then begin
        self.user_value=ptr_new(double(wave))
     endif else begin
        *self.user_value=[*self.user_value,double(wave)]
     endelse
                                ;x value of where the user clicked
     if n_elements(*self.x_value) eq 0 then begin
        self.x_value=ptr_new(self.xy[0])
     endif else begin
        *self.x_value=[*self.x_value, self.xy[0]]
     endelse
     print,'x_value',*self.x_value
     last=n_elements(*self.user_value)
     ;plotting the wavelength as label for the line
     linecolor=self.xplot->getdata(/linecolor)
     wset,self.pixmap_wid
     xyouts,self.eventxy[0], self.eventxy[1], wave,$
            COLOR=linecolor,/DEVICE
     wset,self.plotwin_wid
     device, COPY=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                   self.pixmap_wid]
     widget_control,self.plotwin,/SENSITIVE,/INPUT_FOCUS
     self.xplot->setdata,reg=!values.f_nan
     widget_control, self.undo_button, /sensitive
     if (last gt 1) then $
        widget_control, self.cal_button, /sensitive
  endif else begin
     error=dialog_message('You must enter a valid wave length',/ERROR,$
                          dialog_parent=self.wc_base)
  endelse
  widget_control, self.store_button, sensitive=0
  widget_control, self.wc_fld, set_value=''
  
end

;************************************************************************
;     Cancel
;************************************************************************
pro drip_xplot_wavecal::cancel,event

;freeing pointers for new run
ptr_free,self.user_value
self.user_value=ptr_new(/allocate_heap)
ptr_free,self.x_value
self.x_value=ptr_new(/allocate_heap)

;setting defaults
widget_control,self.wc_base,/DESTROY
widget_control,self.plotwin,/SENSITIVE,/INPUT_FOCUS
self.xplot->setdata,reg=!values.f_nan
self.xplot->setdata,cursormode='None'
self.xplot->plotspec

end
;************************************************************************
;     Create
;************************************************************************
pro drip_xplot_wavecal::create,type

;get font string from common block
common gui_os_dependent_values, largefont

case type of
   0:begin

                                ;WaveCal Widgets
      self.wc_base = widget_base(self.xzoomplot_base,$
                                 /COLUMN,$
                                 TITLE='Wave Calibration',$
                                 /Align_Center)
      wc_title=widget_label(self.wc_base,$
                            VALUE='Wavelength Calibration',$
                            FONT=largefont,$
                            /ALIGN_CENTER)
      
      wc_input=widget_base(self.wc_base,$
                           /ROW,/ALIGN_LEFT)
      wc_label=widget_label(wc_input,$
                            VALUE='Enter Corresponding Wavelength')
      wc_text=widget_text(wc_input,$
                          /Editable,$
                          /KBRD_FOCUS_EVENTS,$
                          /SENSITIVE)
      self.wc_fld = [wc_text]
      
      wc_buttonbase=widget_base(self.wc_base,$
                                /ROW,/ALIGN_CENTER)
      ;Store button
      self.store_button = widget_button(wc_buttonbase,$
                                        event_pro='drip_xplot_eventhand',$
                                        Value='Store',$
                                        XSIZE=100,$
                                        uvalue={object:self,$
                                                method:'event',$
                                                uval:'WaveCal Store'})
      self.undo_button = widget_button(wc_buttonbase,$
                                       event_pro='drip_xplot_eventhand',$
                                       Value='Undo Last',$
                                       XSIZE=100,$
                                       uvalue={object:self,$
                                               method:'button_event',$
                                               uval:'WaveCal Undo'})
      ;Calibrate button
      self.cal_button = widget_button(wc_buttonbase,$
                                event_pro='drip_xplot_eventhand',$
                                value='Calibrate',$
                                XSIZE=100,$
                                uvalue={object:self,$
                                        method:'wavecal',$
                                        uval:'WaveCal Calibrate'})
      ;Cancel button
      wc_button=widget_button(wc_buttonbase,$
                              event_pro='drip_xplot_eventhand',$
                              value='Cancel',$
                              xsize=100,$
                              uvalue={object:self,$
                                      method:'button_event',$
                                      uval:'Cancel'})
   end
   else:
endcase
    
 ;widget_control,self.wc_fld[0],/SENSITIVE,/INPUT_FOCUS
end
;************************************************************************
;     Create Start
;************************************************************************
pro drip_xplot_wavecal::start
  self.xplot->setdata,cursormode='Wave Cal'
  widget_control,self.plotwin,SENSITIVE=1,INPUT_FOCUS=1
  self->create,0
  widget_control, self.undo_button, sensitive=0
  widget_control, self.store_button, sensitive=0
  widget_control, self.cal_button, sensitive=0
  ;undo pixmap
  device,RETAIN=2
  window, /Free, /pixmap, xsize=self.plotsize[0],$
          ysize=self.plotsize[1]
  self.lastmap=!d.window
end


;******************************************************************************
;     Set Data
;******************************************************************************
pro drip_xplot_wavecal::setdata, xy=xy,eventxy=eventxy,$
                      user_value=user_value, x_value=x_value,mw=mw

if keyword_set(xy) then self.xy=xy
if keyword_set(eventxy) then self.eventxy=eventxy
if keyword_set(user_value) then self.user_value= user_value
if keyword_set(x_value) then self.x_value= x_value
if keyword_set(mw) then self.mw=mw

end

;******************************************************************************
;     Setup
;******************************************************************************

pro drip_xplot_wavecal::setup

self->setinitialdata

end

;******************************************************************************
;     INIT
;******************************************************************************

function drip_xplot_wavecal::INIT,xplot

;data
self.user_value=ptr_new(/allocate_heap)
self.x_value=ptr_new(/allocate_heap)

;;same as parent;;
;data
self.allwave=ptrarr(100,/allocate_heap)
self.allpixel=ptrarr(100,/allocate_heap)
self.allflux=ptrarr(100,/allocate_heap)

;objects
self.xplot=xplot

return, 1

end

;******************************************************************************
;     DRIP_XPLOT_WAVECAL__DEFINE
;******************************************************************************

pro drip_xplot_wavecal__define

struct={drip_xplot_wavecal,$
        $;widget ids
        wc_base:0L,$            ;base widget id
        wc_fld:0L,$             ;id for text box
        store_button:0L,$       ;id for store button
        cal_button:0L,$         ;id for calibrate button
        $;undo stuff
        lastmap:0L,$            ;last pixmap
        undo_button:0L,$        ;undo button widget id
        $;data pointers
        user_value:ptr_new(),$  ;calibrations entered by user for the points
        x_value:ptr_new(),$     ;x value of where you clicked
        inherits drip_xplot_mode}

end
