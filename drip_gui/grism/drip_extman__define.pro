pro drip_extman::setmap,mode
; mode - grism mode
;         0 - g1xg2
;         1 - g3xg4
;         2 - g5xg6

case mode of
    0:*self.map=[[164,214],[131,177],[100,144],[72,114],[47,88],[23,65],[0,42]]
    1:*self.map=[[217,176],[189,146],[158,115],[127,79],[96,47],[68,17]]
    2:*self.map=[[217,176],[189,146],[158,115],[127,79],[96,47],[68,17]]
endcase

self.orders=[4,(size(*self.map))[2] + 4 - 1]

end
;******************************************************************************
;    Multiple order
;******************************************************************************
pro drip_extman::multi_order,mode

;sz=n_elements(*self.data)
;print,'size:',sz
;if (sz gt 0) then begin
data=*self.data
dy=15                           ; height
self->setmap,mode
map=*self.map
readcol,'drip_gui/order_calb.txt',orders,lam_low,lam_high,format='i,f,f'
help,orders,self.orders
len=(size(map))[2]                ; number of extractions/orders
pos=where(orders eq self.orders(0))
avg=0
for i=0,len-1 do begin
    ;slope
    slope= float(map(1,i)-map(0,i))/float(255-0)
    ;xvalues
    xvalue=findgen(256)
    mx=float((lam_high(pos+i)-lam_low(pos+i)))/float(256)
    wave=mx(0)*xvalue + (lam_low(pos+i))(0)
    ;yvalues
    yvalue=round(slope*(xvalue))+map(0,i)
    ;extracted data
    extract=total(data[xvalue[0],yvalue[0]:(yvalue[0]+dy)],2)
    for n= 1,255 do begin
        extract=[extract,total(data[xvalue[n],yvalue[n]:(yvalue[n]+dy)],2)]
    end
    if (i eq 0) then avg1=mean(extract)
    avg=mean(extract)
    davg=avg-avg1
    print,avg1,avg,davg
    extract=extract-davg
    *self.allwave[i]=wave
    *self.allflux[i]=extract
endfor
;endif
end
;******************************************************************************
;     Get Data - Send new sets of data
;******************************************************************************
function drip_extman::getdata,data=data,$
                    extract=ext,dapsel_name=dapn,$
                    wave_num=wave_num, flux_num=flux_num,$
                    orders=orders

if keyword_set(data) then  return, self.data
if keyword_set(ext) then return, self.extract
if keyword_set(dapn) then return, self.dapsel_name
if keyword_set(wave_num) then return, *self.allwave[wave_num-self.orders(0)]
if keyword_set(flux_num) then return, *self.allflux[flux_num-self.orders(0)]
if keyword_set(orders) then return, self.orders

end
;******************************************************************************
;     Covert Coordinates
;******************************************************************************

pro drip_extman::convcoord
self.boxx0= self.boxu0
self.boxy0= self.boxv0
self.boxx1= self.boxu1
self.boxy1= self.boxv1
end

;******************************************************************************
;     Extract - Extract from the data
;******************************************************************************
pro drip_extman::extract

;;needs work
;dataman=self.dataman
;self.dapsel=self.dataman->getdap(dataman.dapsel)
;dapsel=*self.dapsel
;*self.data=readfits(dapsel.path+dapsel.file0)
;if (self.boxx1 eq 0) and (self.boxy1 eq 0) then begin
;    datasize=size(*self.data)
;    self.boxx1= datasize(1)-1
;    self.boxy1= datasize(2)-1
;endif

;extract
data=*self.data

dy=self.boxy1-self.boxy2 ; height

slope= float(self.boxy2-self.boxy0)/float(self.boxx2-self.boxx0) ;slope

xvalue=round(findgen(self.boxx2-self.boxx0+1) + self.boxx0)

;yvalue=[self.boxy0]
;for i=1,(self.boxx2-self.boxx0) do begin
;    yvalue=[yvalue,round((xvalue[i]-self.boxx0)*slope+yvalue[0])]
;endfor

yvalue=round(slope*(xvalue-self.boxx0))+self.boxy0

print,'xend:',xvalue(n_elements(xvalue)-1),xvalue(0)
print,'yend:',yvalue(n_elements(yvalue)-1),yvalue(0)
print,'dy:',dy,self.boxy1,self.boxy2

extract=total(data[xvalue[0],yvalue[0]:(yvalue[0]+dy)],2)
for i= 1,(self.boxx2-self.boxx0) do begin
    extract=[extract,total(data[xvalue[i],yvalue[i]:(yvalue[i]+dy)],2)]
endfor

*self.extract=extract

print,'extman'
help,*self.extract
end

;******************************************************************************
;     NEWDATA - Sets new sets of data
;******************************************************************************

pro drip_extman::newdata,data=data,$
                         boxx0=boxx0, boxy0=boxy0,$
                         boxx1=boxx1, boxy1=boxy1,$
                         boxx2=boxx2, boxy2=boxy2,map=map


print,'SETTING DATA IN EXTMAN'
if keyword_set(data) then self.data=data
if keyword_set(boxx0) then self.boxx0=boxx0 else self.boxx0=0
if keyword_set(boxy0) then self.boxy0=boxy0 else self.boxy0=0
if keyword_set(boxx1) then self.boxx1= boxx1
if keyword_set(boxy1) then self.boxy1= boxy1
if keyword_set(boxx2) then self.boxx2=boxx2 else self.boxx2=0
if keyword_set(boxy2) then self.boxy2=boxy2 else self.boxy2=0
if keyword_set(map) then begin
    *self.map=map
endif

end
;******************************************************************************
;     SETDATA - Adjust the SELF structure elements
;******************************************************************************

pro drip_extman::setdata, disp_channels=disp_channels
if keyword_set(disp_channels) then self.disp_channels= disp_channels
end


;******************************************************************************
;     RESET - Reset the object
;******************************************************************************
pro drip_extman::reset

;free memory


end



;******************************************************************************
;      CLEANUP
;******************************************************************************

pro drip_extman::cleanup
;free pointers
ptr_free,self.extract
ptr_free,self.fileinfoval
end


;******************************************************************************
;      INIT
;******************************************************************************

function drip_extman::init,mw, dataman

self.mw = mw
self.dataman=dataman
;memory for fileinfo values
self.fileinfoval=ptr_new(/allocate_heap)
self.dapsel=ptr_new(/allocate_heap)
self.extract=ptr_new(/allocate_heap)
self.allflux=ptrarr(100,/allocate_heap)
self.allwave=ptrarr(100,/allocate_heap)
self.map=ptr_new(/allocate_heap)
self.boxx0=0
self.boxy0=0
self.boxx1=0
self.boxy1=0
self.boxy2=0
self.boxx2=0

return,1
end


;******************************************************************************
;      DRIP_EXTMAN__DEFINE
;******************************************************************************
pro drip_extman__define

struct={drip_extman,$
        dataman:obj_new(), $    ;data manager
        boxx0:0,boxy0:0,$       ;lower left corner (data coordinates)
        boxx1:0,boxy1:0,$       ;top right corner (data coordinates)
        boxx2:0, boxy2:0,$      ;lower right corner
        disp_channels:objarr(4),$ ;display channels
        dapsel_name:'',$        ;name of currently selected dap
        dapsel:ptr_new(),$      ;selected dap
        data:ptr_new(),$        ;from currently selected dap
        extract:ptr_new(),$     ;extracted data
        mw:obj_new(),$          ;wid of file information table
        fileinfo:0L,$           ;wid of file information table
        fileinfoval:ptr_new(),$ ;file information table
        allflux:ptrarr(100),$   ;all flux data
        allwave:ptrarr(100),$   ;all wave data
        map:ptr_new(),$         ;list of y-coordinates for extraction
        orders:[0,0],$          ;[least order, highest order]
        n:0}
end
