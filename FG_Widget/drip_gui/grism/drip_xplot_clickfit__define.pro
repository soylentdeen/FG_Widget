;************************************************************************
;     BaseFit - Accept
;************************************************************************

pro drip_xplot_clickfit::base_accept,event

;saving the data for undo purposes
self.xplot->setdata,tempwave=ptr_new(*self.allwave[0])
self.xplot->setdata,tempflux=ptr_new(*self.allflux[0])

;setting no oplot
self.xplot->setdata,/no_oplotn

;drawing the new fitted data
self.xplot->draw,*self.wavefit,(*self.fluxfit-*self.polyfit)

;exit
self->exit

end

;************************************************************************
;     BaseFit - Subtract
;************************************************************************
pro drip_xplot_clickfit::base_subtract,event

subs=*self.fluxfit-*self.polyfit

wset,self.pixmap_wid
;plot,*self.wavefit,*self.fluxfit
plot,*self.wavefit,subs
wset,self.plotwin_wid
device,copy=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                  self.pixmap_wid]

end


;************************************************************************
;     FitClicksData
;************************************************************************

pro drip_xplot_clickfit::fitClicksData

clickx=*self.clickx
clicky=*self.clicky
wave=*self.allwave[0]
flux=*self.allflux[0]
for i=0,n_elements(clicky)-1 do begin
    tabinv,wave,clickx[i],indx
    clicky[i]=flux[indx]
endfor
*self.clicky=clicky
self->fitClicks

end

;************************************************************************
;     FitClicks
;************************************************************************

pro drip_xplot_clickfit::fitClicks,event

wave=*self.allwave[0]
flux=*self.allflux[0]

*self.wavefit=wave
*self.fluxfit=flux

fit=spline(*self.clickx,*self.clicky,wave)
*self.polyfit=fit

print,fit
help,wave
print,*self.clickx

;wset,self.pixmap_wid
oplot,*self.wavefit,*self.polyfit
;wset,self.plotwin_wid
;device,copy=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
;                 self.pixmap_wid]
widget_control,self.cf_base,/DESTROY
self->create,5
end

;************************************************************************
;     BaseFit - Fit polynomial to data
;************************************************************************

pro drip_xplot_clickfit::basefit,event

wave=*self.allwave[0]
flux=*self.allflux[0]
order=9

;croping the data
*self.wavefit=wave[self.box_xy[0,0]:self.box_xy[0,1]]
*self.fluxfit=flux[self.box_xy[0,0]:self.box_xy[0,1]]
;fit=spline(*self.wavefit,*self.fluxfit,*self.wavefit)
coeff=fg_poly_fit(*self.wavefit, *self.fluxfit,order)
wf=*self.wavefit
fit=0
for i=0,order do begin
    fit = fit + coeff(i)*(wf^i)
endfor

*self.polyfit=fit

;plot,*self.wavefit,*self.fluxfit

wset,self.pixmap_wid
;plot,*self.wavefit,*self.fluxfit
oplot,*self.wavefit,*self.polyfit
wset,self.plotwin_wid
device,copy=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                  self.pixmap_wid]
widget_control,self.cf_base,/DESTROY
self->create,2
end


;************************************************************************
;     FitGauss
;************************************************************************
pro drip_xplot_clickfit::fitGauss

a=[median(*self.fluxfit),self.height,self.centroid,self.width]

;fitting gauss
*self.gauss=gaussfit(*self.wavefit,*self.fluxfit,a)

;fwhm
self.width=2*sqrt(2*alog(2))*a[2]

;table to display coefficients
self.table_base=widget_base(self.cf_base,/column)
                            
;headers for the table
xs=80
;base
head_base=widget_base(self.table_base,/row,/align_left)
h_base=widget_base(head_base,/column, /align_left,/frame)
cen_base=widget_base(head_base,/column,/align_left,/frame)
fwhm_base=widget_base(head_base,/column,/align_left,/frame)
;cnst_base=widget_base(head_base,/column,/align_left,/frame)
;lin_base=widget_base(head_base,/column,/align_left,/frame)
;quad_base=widget_base(head_base,/column,/align_left,/frame)
;labels
height=widget_label(h_base,value='Height',Xsize=xs,/align_left)
centroid=widget_label(cen_base,value='Centrd',Xsize=xs,/align_left)
fwhm=widget_label(fwhm_base,value='FWHM',Xsize=xs,/align_left)
;const=widget_label(cnst_base,value='Const',Xsize=xs,/align_left)
;linear=widget_label(lin_base,value='Lin',Xsize=xs,/align_left)
;quad=widget_label(quad_base,value='Quad',Xsize=xs,/align_left)

;coefficients
;coeff_base=widget_base(self.table_base,/row,/align_left)
A0=widget_label(h_base,value=string(a[0]),Xsize=xs,/align_left)
A1=widget_label(cen_base,value=string(a[1]),Xsize=xs,/align_left)
FWHM=widget_label(fwhm_base,value=string(self.width),Xsize=xs,/align_left)
;A3=widget_label(cnst_base,value=string(a[3]),Xsize=xs,/align_left)
;A4=widget_label(lin_base,value=string(a[4]),Xsize=xs,/align_left)
;A5=widget_label(quad_base,value=string(a[5]),Xsize=xs,/align_left)

wset,self.pixmap_wid
oplot,*self.wavefit,*self.gauss
wset,self.plotwin_wid
device,copy=[0,0,self.plotsize[0],self.plotsize[1],0,0,$
                  self.pixmap_wid]

end

;************************************************************************
;     FindVal
;************************************************************************
pro drip_xplot_clickfit::findVal,event

wave=*self.allwave[0]
flux=*self.allflux[0]

;croping the data
print,self.box_xy
*self.wavefit=wave[self.box_xy[0,0]:self.box_xy[0,1]]
*self.fluxfit=flux[self.box_xy[0,0]:self.box_xy[0,1]]

;find the peak
max=max(*self.fluxfit,min=min)
self.height = max-min
max=min
;linear search for position of centroid
n=n_elements(*self.fluxfit)
index=0

wavefit=*self.wavefit
fluxfit=*self.fluxfit
while (index lt n and not(max eq fluxfit[index])) do index=index+1

self.centindex=index
self.centroid=wavefit[index]

;find the width
ind1=0
halfmax=round(max/2)
while (ind1 lt self.centindex and not(halfmax eq round(fluxfit[ind1]))) do ind1=ind1+1

ind2=self.centindex

while (ind2 lt n-1 and not(halfmax eq round(fluxfit[ind2]))) do ind2=ind2+1

self.width=wavefit[ind2]-wavefit[ind1]


self->fitGauss


end


;************************************************************************
;     Cancel
;************************************************************************
pro drip_xplot_clickfit::exit,event

;freeing pointers for new run

;setting defaults
widget_control,self.cf_base,/DESTROY
;for multiple use of gauss fit
self.table_base=0L
widget_control,self.plotwin,/SENSITIVE,/INPUT_FOCUS
self.xplot->setdata,reg=!values.f_nan
self.xplot->setdata,cursormode='None'
self.xplot->plotspec

end

;************************************************************************
;     Create
;************************************************************************
pro drip_xplot_clickfit::create, type

;get font string from common block
common gui_os_dependent_values, largefont

case type of
    0: begin                    ;Starting Widgets
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please select the type of fit',$
                                      /ALIGN_CENTER)
        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)

        self.cf_gaussBtn=widget_button(btnBase,$
                                       value='Fit Gauss',$
                                       /Align_center,$
                                       event_pro='drip_xplot_eventhand',$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'gaussfit'})
        self.cf_basefBtn=widget_button(btnBase,$
                                       value='Baseline Fit',$
                                       /align_center,$
                                       event_pro='drip_xplot_eventhand',$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'basefit'})

        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end

    1:begin
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='BaseLine Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='BaseLine Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please select the type'+$
                                      ' of baseline fit',$
                                      /ALIGN_CENTER)

        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)

        self.cf_fitClicksBtn=widget_button(btnBase,$
                                          value='Fit Clicks',$
                                          /Align_center,$
                                          event_pro='drip_xplot_eventhand',$
                                          Xsize=100,$
                                          uvalue={object:self,$
                                                  method:'events',$
                                                  uval:'fit clicks'})
        self.cf_fitDataBtn=widget_button(btnBase,$
                                         value='Fit Data',$
                                         /align_center,$
                                         event_pro='drip_xplot_eventhand',$
                                         Xsize=100,$
                                         uvalue={object:self,$
                                                 method:'events',$
                                                 uval:'fit data'})
        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end

    2:begin
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='BaseLine Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='BaseLine Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please select the type'+$
                                      ' of baseline fit',$
                                      /ALIGN_CENTER)

        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)

        self.cf_subtractBtn=widget_button(btnBase,$
                                          value='Subtract',$
                                          /Align_center,$
                                          event_pro='drip_xplot_eventhand',$
                                          Xsize=100,$
                                          uvalue={object:self,$
                                                  method:'events',$
                                                  uval:'subtract'})
        self.cf_fitDataBtn=widget_button(btnBase,$
                                         value='Retry Fit',$
                                         /align_center,$
                                         event_pro='drip_xplot_eventhand',$
                                         Xsize=100,$
                                         uvalue={object:self,$
                                                 method:'events',$
                                                 uval:'fit data'})
        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end
    3:begin
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='BaseLine Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='BaseLine Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please select the type'+$
                                      ' of baseline fit',$
                                      /ALIGN_CENTER)

        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)

        self.cf_acceptBtn=widget_button(btnBase,$
                                          value='Accept',$
                                          /Align_center,$
                                          event_pro='drip_xplot_eventhand',$
                                          Xsize=100,$
                                          uvalue={object:self,$
                                                  method:'events',$
                                                  uval:'accept'})
        self.cf_fitDataBtn=widget_button(btnBase,$
                                         value='Retry Fit',$
                                         /align_center,$
                                         event_pro='drip_xplot_eventhand',$
                                         Xsize=100,$
                                         uvalue={object:self,$
                                                 method:'events',$
                                                 uval:'fit data'})
        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end
    4:begin
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='BaseLine Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='BaseLine Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please press the done button'+$
                                      ' to fit the clicks you made.',$
                                      /ALIGN_CENTER)

        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)
        self.cf_doneClickBtn=widget_button(btnBase,$
                                           value='Fit to Clicks',$
                                           /align_Center,$
                                           event_pro='drip_xplot_eventhand',$
                                           Xsize=100,$
                                           uvalue={object:self,$
                                                   method:'events',$
                                                   uval:'done clicks'})

        self.cf_doneDataBtn=widget_button(btnBase,$
                                      value='Fit to Data',$
                                      /Align_center,$
                                      event_pro='drip_xplot_eventhand',$
                                      Xsize=100,$
                                      uvalue={object:self,$
                                              method:'events',$
                                              uval:'done data'})
        self.cf_fitClicksBtn=widget_button(btnBase,$
                                           value='Reset Clicks',$
                                           /align_center,$
                                           event_pro='drip_xplot_eventhand',$
                                           Xsize=100,$
                                           uvalue={object:self,$
                                                   method:'events',$
                                                   uval:'fit clicks'})
        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end
    5:begin
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='BaseLine Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='BaseLine Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please select the type'+$
                                      ' of baseline fit',$
                                      /ALIGN_CENTER)

        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)

        self.cf_subtractBtn=widget_button(btnBase,$
                                          value='Subtract',$
                                          /Align_center,$
                                          event_pro='drip_xplot_eventhand',$
                                          Xsize=100,$
                                          uvalue={object:self,$
                                                  method:'events',$
                                                  uval:'subtract'})
        self.cf_fitClicksBtn=widget_button(btnBase,$
                                         value='Reset Clicks',$
                                         /align_center,$
                                         event_pro='drip_xplot_eventhand',$
                                         Xsize=100,$
                                         uvalue={object:self,$
                                                 method:'events',$
                                                 uval:'fit clicks'})
        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end
    6:begin
        self.cf_base = widget_base(self.xzoomplot_base,$
                                   /Column,$
                                   Title='BaseLine Fit Mode',$
                                   /align_center)
        self.cf_title= widget_label(self.cf_base,$
                                    VALUE='BaseLine Fit Mode',$
                                    FONT=largefont,$
                                    /ALIGN_CENTER)
        self.cf_message= widget_label(self.cf_base,$
                                      VALUE='Please select the type'+$
                                      ' of baseline fit',$
                                      /ALIGN_CENTER)

        btnBase=widget_base(self.cf_base,$
                            /align_center,$
                            /row)

        self.cf_acceptBtn=widget_button(btnBase,$
                                          value='Accept',$
                                          /Align_center,$
                                          event_pro='drip_xplot_eventhand',$
                                          Xsize=100,$
                                          uvalue={object:self,$
                                                  method:'events',$
                                                  uval:'accept'})
        self.cf_fitClicksBtn=widget_button(btnBase,$
                                         value='Reset Clicks',$
                                         /align_center,$
                                         event_pro='drip_xplot_eventhand',$
                                         Xsize=100,$
                                         uvalue={object:self,$
                                                 method:'events',$
                                                 uval:'fit clicks'})
        self.cf_exitBtn= widget_button(btnBase,$
                                       value='Exit Fit Mode',$
                                       event_pro='drip_xplot_eventhand',$
                                       /Align_center,$
                                       Xsize=100,$
                                       uvalue={object:self,$
                                               method:'events',$
                                               uval:'exit'})
    end
    else:
endcase

end

;******************************************************************************
;     Events - Handles the events
;******************************************************************************
pro drip_xplot_clickfit::events,event

widget_control, event.id, get_uvalue= uvalue

case(uvalue.uval)of
    'gaussfit': begin
        ;self->findVal
        self.xplot->setdata,cursormode='Gauss Fit'
        widget_control,self.plotwin,SENSITIVE=1,INPUT_FOCUS=1
        self.xplot->plotspec
        self.xplot->setminmax
        self.xplot->setdata,reg=!values.f_nan
        if(self.table_base ne 0L) then begin
            widget_control,self.table_base,/destroy
        endif
        widget_control,self.cf_message,set_value='Please select a peak to fit'
    end
    'basefit':begin
        widget_control,self.cf_base,/DESTROY
        self->create,1
        ;self.xplot->plotspec
        
    end
    'fit data':begin
        self.xplot->setdata,cursormode='Base Fit'
        widget_control,self.plotwin,SENSITIVE=1,INPUT_FOCUS=1
        self.xplot->plotspec
        self.xplot->setminmax
        self.xplot->setdata,reg=!values.f_nan
        widget_control,self.cf_base,/DESTROY
        self->create,1
        ;if(self.table_base ne 0L) then begin
        ;    widget_control,self.table_base,/destroy
        ;endif
        widget_control,self.cf_message,$
          set_value='Please select a region to fit'    
    end
    'subtract':begin
        self->base_subtract
        widget_control,self.cf_base,/DESTROY
        cm=self.xplot->getdata(/cursormode)
        if(cm eq 'Click Fit') then begin
            self->create,6
        endif else begin
            self->create,3
        endelse
    end
    'accept':begin
        self->base_accept
    end
    
    'fit clicks':begin
        self.xplot->setdata,cursormode='Click Fit'
        widget_control,self.plotwin,SENSITIVE=1,INPUT_FOCUS=1
        self.xplot->setdata,reg=!values.f_nan
        self.xplot->plotspec
        self.xplot->setminmax
        widget_control,self.cf_base,/DESTROY
        self->create,4
       ; if(self.table_base ne 0L) then begin
       ;     widget_control,self.table_base,/destroy
       ; endif
        *self.clickx=[!values.f_nan]
        *self.clicky=[!values.f_nan]
    end
    'done clicks':begin
        if(n_elements(*self.clickx) gt 2) then begin
            widget_control,self.plotwin,SENSITIVE=0,INPUT_FOCUS=0
            self->fitClicks
        endif
        
    end
    'done data':begin
        if (n_elements(*self.clickx) gt 2) then begin
            widget_control,self.plotwin, sensitive=0, input_focus=0
            self->fitClicksData
        endif
    end


    'exit':begin
        self->exit
    end
    else:
endcase


end

;******************************************************************************
;     SETDATA
;******************************************************************************
pro drip_xplot_clickfit::setdata,box_xy=box_xy,$
                       clickx=clickx,clicky=clicky

if keyword_set(box_xy) then self.box_xy=box_xy
if keyword_set(clickx) then begin
    x=*self.clickx
    z=where(finite(x) gt 0, count)
    if (count eq 0) then begin
        x(0)=clickx
    endif else begin
        x=[x,clickx]
    endelse
    *self.clickx=x
endif

if keyword_set(clicky) then begin
    y=*self.clicky
    z=where(finite(y) gt 0, count)
    if (count eq 0) then begin
        y(0)=clicky
    endif else begin
        y=[y,clicky]
    endelse
    *self.clicky=y
endif


end

;******************************************************************************
;     SETUP
;******************************************************************************
pro drip_xplot_clickfit::setup

self->setinitialdata

end

;******************************************************************************
;     INIT
;******************************************************************************
function drip_xplot_clickfit::INIT,xplot

;data
self.wavefit=ptr_new(/allocate_heap)
self.fluxfit=ptr_new(/allocate_heap)
self.gauss=ptr_new(/allocate_heap)
self.polyfit=ptr_new(/allocate_heap)
self.clickx=ptr_new(/allocate_heap)
*self.clickx=[!values.f_nan]
self.clicky=ptr_new(/allocate_heap)
*self.clicky=[!values.f_nan]

;same as parent;;
self.allwave=ptrarr(100,/allocate_heap)
self.allpixel=ptrarr(100,/allocate_heap)
self.allflux=ptrarr(100,/allocate_heap)

;objects
self.xplot=xplot


return,1
end


;******************************************************************************
;     DRIP_XPLOT_CLICKFIT__DEFINE
;******************************************************************************

pro drip_xplot_clickfit__define

struct={drip_xplot_clickfit,$
        $                       ;widget ids
        cf_base:0L,$            ;base
        cf_title:0L,$           ;title field
        cf_message:0L,$         ;message
        cf_gaussBtn:0L,$        ;fit gauss button
        cf_basefBtn:0L,$        ;baseline fit button
        cf_exitBtn:0L,$         ;exit button
        cf_fitClicksBtn:0L,$    ;base fit clicks (spline)
        cf_fitDataBtn:0L,$      ;base fit selected data
        cf_doneClickBtn:0L,$    ;spline clicking fit to clicked points
        cf_doneDataBtn:0L,$     ;spline clicking fit to data points
        cf_subtractBtn:0L,$     ;subtract the fit from data
        cf_acceptBtn:0L,$       ;accept the new data
        table_base:0L,$         ;base for result table
        numGauss_fld:[0l,0l],$  ;number of gaussians field
        $                       ;counters
        c:0,$                   ;
        $                       ;data
        centindex:0,$           ;index of centroid
        centroid:0.,$           ;centroid
        box_xy:[[0,0],[0,0]],$  ;coordinates of box
        clickx:ptr_new(),$      ;x coordinate of click
        clicky:ptr_new(),$      ;ycoordinate of click
        height:0.,$             ;height of gaussian
        width:0.,$              ;fwhm/2
        numGauss:0,$
        $                       ;data pointers
        wavefit:ptr_new(),$     ;wave data used for fiting
        fluxfit:ptr_new(),$     ;wave data used for fitting
        polyfit:ptr_new(),$     ;the actual fit
        gauss:ptr_new(),$       ;gaussian fit
        

inherits drip_xplot_mode}

end
