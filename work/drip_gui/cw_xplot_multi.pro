;******************************************************************************
;     Save
;******************************************************************************
pro xplot_multi::save

;print,'Now we save'
; I need to make it save fits using sm_wrfits.pro
; information about orders are in self.orders
; check self->draw to see how i get the data to plot it properly

file=dialog_pickfile(/write,$
                             Dialog_parent=self.xplot_multi_base,$
                             file='Spectra01',$
                             path=self.prevPath,$
                             get_path=prevPath,$
                             filter='*.fits',/fix_filter)

if keyword_set(file) then begin
    if not(strmatch(file,'*.fits')) then file=file+'.fits'
    
    n=0
    wave=self.extman->getdata(wave_num=(self.orders(0)+n))
    flux=self.extman->getdata(flux_num=(self.orders(0)+n))
    len=n_elements(wave)
    orders=intarr(len)+(self.orders[0]+n)
    error= dblarr(len)
    for i=self.orders(0),self.orders(1)-1 do begin
        n=n+1
        wave=[wave, self.extman->getdata(wave_num=(self.orders(0)+n))]
        flux=[flux, self.extman->getdata(flux_num=(self.orders(0)+n))]
        len=n_elements(self.extman->getdata(wave_num=(self.orders(0)+n)))
        orders=[orders, intarr(len)+(self.orders[0]+n)]
        error=[error, dblarr(len)]
    endfor
    data=[transpose(wave),$
          transpose(flux),$
          transpose(error),$
          transpose(orders)]
    collabels=['wavelength', 'flux', 'flux_error','order']
    self.mw->print,'Written file '+file
    sz=size(data)
    wr_spfits,file,data, sz(2), collabels=collabels
endif

end


;******************************************************************************
;     EVENTS
;******************************************************************************
pro xplot_multi::events,event

widget_control, event.id, get_uvalue=uvalue

case uvalue.uval of
    'plot':begin
        self->draw
    end
    'save fits':begin
        self->save
    end
    'exit':begin
        self->exit,event
    end
    else:
endcase

end


;******************************************************************************
;    CHECKBOX EVENTS
;******************************************************************************
pro xplot_multi::checkbox_events,event

widget_control,event.id,get_uvalue=uvalue
if (uvalue.uval eq 'all') then begin
    for i=0,self.checkn do begin
        self.chk_status(i)=event.select
        widget_control,self.checkbox(i),set_button=event.select
    endfor
endif else begin
    widget_control,self.checkbox(0),set_button=0
    ;self.chk_status(0)=0
    self.chk_status(fix(uvalue.uval)-self.orders(0))=event.select
endelse

selected=0
for i=0,self.checkn-1 do begin
    if (self.chk_status(i) eq 1) then begin
        selected=[selected,i+self.orders(0)]
    endif
endfor

if keyword_set(selected) then begin
    *self.selected=selected(1:*)
endif

end
;******************************************************************************
;     DRAW
;******************************************************************************
pro xplot_multi::draw,nums=nums,all=all

orders=self.orders
if keyword_set(all) then begin
    *self.selected=indgen(orders(1)-orders(0)+1)+orders(0)
    ;set all checkboxes to selected??
    for i=0,self.checkn do begin
        widget_control,self.checkbox(i),set_button=1
    endfor
endif

;selected checkboxes
selected=*self.selected
;get colors
colors=*self.colors
nc=(size(colors))[2]            ;number of colors

;set no plot
self.xplot->setdata,/no_oplotn
;set color
n=selected(0)-orders(0)
linecolor=colors[0,n]+256L*(colors[1,n]+256L*colors[2,n])
self.xplot->setdata,linecolor=linecolor

;get data from extraction data manager
wave=self.extman->getdata(wave_num=selected(0))
flux=self.extman->getdata(flux_num=selected(0))
self.xplot->draw,wave,flux 
for i=1,n_elements(selected)-1 do begin
    self.xplot->setdata,/oplotn
    n=selected(i)-orders(0)
    linecolor=colors[0,(n mod nc)]$
              +256L*(colors[1,(n mod nc)]$
                     +256L*colors[2,(n mod nc)])
    self.xplot->setdata,linecolor=linecolor
    wave=self.extman->getdata(wave_num=selected(i))
    flux=self.extman->getdata(flux_num=selected(i))
    self.xplot->draw,wave,flux,/oplot
endfor
self.xplot->setdata,xtitle='Wavelength (!7l!Xm)'
self.xplot->plotspec

end
;******************************************************************************
;    Exit
;******************************************************************************
pro xplot_multi::exit,event
widget_control,event.top,/destroy

end
;******************************************************************************
;     START
;******************************************************************************
pro xplot_multi::start,dispman

self.xplot->start,dispman

end

;******************************************************************************
;     SETDATA
;******************************************************************************

pro xplot_multi::setdata,xplot=xplot,$
               checkbox=checkbox,mw=mw,$
               extman=extman,orders=orders,$
               top_base=top_base

if keyword_set(xplot) then self.xplot=xplot
if keyword_set(checkbox) then self.checkbox=checkbox
if keyword_set(mw) then self.mw=mw
if keyword_set(extman) then self.extman=extman
if keyword_set(orders) then begin
    self.orders=orders
    self.checkn=orders(1)-orders(0)+1
endif
if keyword_set(top_base) then self.xplot_multi_base=top_base

end

;******************************************************************************
;     INIT
;******************************************************************************

function xplot_multi::INIT

self.allflux=ptrarr(100,/allocate_heap)
self.allwave=ptrarr(100,/allocate_heap)
self.selected=ptr_new(/allocate_heap)
self.colors=ptr_new(/allocate_heap)
*self.colors=[[255,0,0],[255,255,0],[255,0,255],$
              [0,255,0],[0,255,255],$
              [0,0,255],$
              [255,255,255]]
common gui_config_info, config
self.prevPath=getpar(config,'loadfitspath')

return,1

end


;******************************************************************************
;     XPLOT_MULTI__DEFINE
;******************************************************************************



pro xplot_multi__define

struct={xplot_multi,$
        allflux:ptrarr(100),$   ;all orders flux extracted
        allwave:ptrarr(100),$   ;all orders wave
        checkbox:lonarr(100),$  ;id for checkboxes
        xplot_multi_base:0l,$   ;base widget id
        checkn:0,$              ;no. of checkboxes
        chk_status:intarr(100),$ ;checkbox status
        prevPath:'',$           ;previous path
        xplot:obj_new(),$       ;xplot
        extman:obj_new(),$      ;extraction data manager
        mw:obj_new(), $         ;message window
        orders:[0,0],$          ;string order and last order
        selected:ptr_new(),$    ;orders that are selected
        colors:ptr_new()$       ;color bank
       }

end


;******************************************************************************
;     CW Definition: EVENTHANDLER / CLEANUP / CREATING FUNCTION
;******************************* ***********************************************

pro xplot_multi_cleanup, id
widget_control, id, get_uvalue=obj
obj_destroy, obj
end


pro xplot_multi_eventhand, event
Widget_Control, event.id, Get_UValue=cmd
Call_Method, cmd.method, cmd.object, event
;print,'event handled'
end


function cw_xplot_multi,learder, xsize=xs, ysize=ys,id=id,mw=mw,orders=orders,$
                        extman=extman

if not(keyword_set(xs)) then xs=640
if not(keyword_set(ys)) then ys=480
common gui_os_dependent_values, largefont
;the associated object
xplot_multi=obj_new('xplot_multi')

;top level base
tlb=widget_base($;group_leader=leader,$
                title='Cross-Disperssed',$
                /column,/align_center,mbar=mbar)
;base widget to pass the object reference
;base=widget_base(tlb,$
;                 kill_notify='xplot_multi_cleanup')

baseTitle=widget_base(tlb,/column,/align_center)
title=widget_label(baseTitle,$
                   value='Multiple Order Mode',$
                   /align_center,$
                   font=largefont)
;check boxes
file=widget_button(mbar,$
                   value='File',$
                   /menu)
open=widget_button(file,$
                   value='Open...')
save=widget_button(file,$
                   value='Save...',$
                   event_pro='xplot_multi_eventhand',$
                   uvalue={object:xplot_multi,$
                           method:'events',$
                           uval:'save fits'})
close=widget_button(file,$
                    value='Close',$
                    event_pro='xplot_multi_eventhand',$
                    uvalue={object:xplot_multi,$
                                  method:'events',$
                                  uval:'exit'})
checkMain=widget_base(tlb,/column,/frame,/align_center)
orderLabel=widget_label(checkMain,value='Select Orders',/align_center)
chck_base=widget_base(checkMain,/row,/nonexclusive)
n=0
checkbox=lonarr(orders(1)-orders(0)+2)
checkbox(n) = widget_button(chck_base,$
                            value='all',$
                            event_pro='xplot_multi_eventhand',$
                            uvalue={object:xplot_multi,$
                                    method:'checkbox_events',$
                                    uval:'all'})
for i=orders(0),orders(1) do begin
    n = n+1
    checkbox(n) = widget_button(chck_base,$
                                value=strcompress(string(i)),$
                                event_pro='xplot_multi_eventhand',$
                                uvalue={object:xplot_multi,$
                                        method:'checkbox_events',$
                                        uval:strcompress(string(i))})
endfor
;the display
extDisp = cw_drip_xplot(tlb,xsize=xs,ysize=ys,mw=mw)
id = widget_info(extDisp,/child)
widget_control,id,get_uvalue=obj
xplot = obj

;buttons
btn_base = widget_base(tlb,/row,/frame,/align_center)
plot_btn = widget_button(btn_base,$
                         value='Plot',$
                         event_pro='xplot_multi_eventhand',$
                         xsize=150,$
                         font=largefont,$
                         uvalue={object:xplot_multi,$
                                        method:'events',$
                                        uval:'plot'})
Close_btn = widget_button(btn_base,$
                          value='Close',$
                          event_pro='xplot_multi_eventhand',$
                          xsize=150,$
                          font=largefont,$
                          uvalue={object:xplot_multi,$
                                  method:'events',$
                                  uval:'exit'})

;setdata into the associated object
xplot_multi->setdata,$
  xplot=xplot,$
  checkbox=checkbox,mw=mw,$
  orders=orders,extman=extman,top_base=tlb

widget_control,mbar,set_uvalue=xplot_multi
widget_control,tlb,/realize

xmanager,'xplot_multi',tlb,/no_block

return,tlb
end
