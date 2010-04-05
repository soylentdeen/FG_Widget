
;******************************************************************************
;     Get Data - Send new sets of data 
;******************************************************************************
function drip_extdataman::getdata,data=data,$
                             extract=ext

if keyword_set(data) then  return, self.data
if keyword_set(ext) then return, self.extract

end
;******************************************************************************
;     Covert Coordinates
;******************************************************************************

pro drip_extdataman::convcoord
self.boxx0= self.boxu0
self.boxy0= self.boxv0
self.boxx1= self.boxu1
self.boxy1= self.boxv1
end

;******************************************************************************
;     Extract - Extract from the data 
;******************************************************************************
pro drip_extdataman::extract
if (self.boxx1 eq 0) and (self.boxy1 eq 0) then begin
    datasize=size(*self.data)
    self.boxx1= datasize(1)-1
    self.boxy1= datasize(2)-1
endif
print,size(*self.data),self.boxx0,self.boxx1,self.boxy0,self.boxy1
help,*self.data
;extract
data=*self.data
;*self.extract=total(*self.data(100:150,100:150),2)
help,data
*self.extract = total(data(self.boxx0:self.boxx1,self.boxy0:self.boxy1),2)

end

;******************************************************************************
;     NEWDATA - Sets new sets of data 
;******************************************************************************

pro drip_extdataman::newdata,data=data,$
                             boxu0=boxu0, boxv0=boxv0,$
                             boxu1=boxu1, boxv1=boxv1

if keyword_set(data) then  self.data= ptr_new(data)
if keyword_set(boxu0) then self.boxu0= boxu0
if keyword_set(boxv0) then self.boxv0= boxv0
if keyword_set(boxu1) then self.boxu1= boxu1
if keyword_set(boxv1) then self.boxv1= boxv1

end
;******************************************************************************
;     SETDATA - Adjust the SELF structure elements
;******************************************************************************

pro drip_extdataman::setdata, disp_channels=disp_channels
if keyword_set(disp_channels) then self.disp_channels= disp_channels
end


;******************************************************************************
;      CLEANUP
;******************************************************************************

pro drip_extdataman::cleanup
;free pointers
ptr_free, self.data
ptr_free,self.extract
ptr_free,self.fileinfoval
end


;******************************************************************************
;      INIT
;******************************************************************************

function drip_extdataman::init,mw

self.mw = mw
;memory for fileinfo values
self.fileinfoval=ptr_new(/allocate_heap)
self.data=ptr_new(/allocate_heap)
self.extract=ptr_new(/allocate_heap)
self.boxx0=0
self.boxy0=0
self.boxx1=0
self.boxy1=0
return,1
end


;******************************************************************************
;      DRIP_EXTDATAMAN__DEFINE
;******************************************************************************
pro drip_extdataman__define

struct={drip_extdataman,$
        boxu0:0,boxv0:0,$           ;lower left corner (device coordinates)
        boxu1:0,boxv1:0,$           ;top right corner (device coordinates)
        boxx0:0,boxy0:0,$           ;lower left corner (data coordinates)
        boxx1:0,boxy1:0,$           ;top rgith corner (data coordinates)
        disp_channels:objarr(4),$
        data:ptr_new(),$
        extract:ptr_new(),$
        mw:obj_new(),$              ;wid of file information table
        fileinfo:0L,$               ;wid of file information table
        fileinfoval:ptr_new(),$     ;file information table
        n:0}
end
