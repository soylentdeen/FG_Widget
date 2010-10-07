; NAME:
;     DRIP_EXTMAN__DEFINE - Version .7.0
;
; PURPOSE:
;     Analysis Object Manager for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_EXTMAN', BASEID)
;
; INPUTS:
;     BASEID - Widget ID of base to put widgets
;
; STRUCTURE:
;     TITLE - object title
;     FOCUS - focus status (1 if in focus else 0)
;     DISOBJ - display object
;     BASEWID - base widget
;
; HISTORY;
; =============================
; 7/23/10 - Josh Cheng and Casey Deen added nodding extraction mode

pro drip_extman::setmap,mode
; mode - grism mode
;         0 - G1xG2
;         1 - G3xG4
;         2 - G1
;         3 - G3
;         4 - G5
;         5 - G6

;  This case statement should actually come from the header file or master flat.
; 
case mode of
    0:begin            ; G1xG2
        ;   [ [ [y0_bottom_left, y0_bottom_right], [y1_bl, y1_br], ...], [ [x0_left, x0_right], [x1_l, x1_r], ... ] ]
         *self.map=[[[202, 233],[162,210],[127,173],[98,144],[69,110],[46,84],[20,58],[0,38]], $
         [[0,159],[0,255],[0,255],[0,255],[0,255],[0,255],[0,255], [0,255]]]
         *self.ord_height = [21, 21, 21, 21, 21, 21, 21, 18]
         *self.orders=[15, 16, 17, 18, 19, 20, 21, 22]
      end
    1:begin            ; G3xG4
         *self.map=[[[137,231],[80,164],[33,112],[0, 69],[1, 33]], $
         [[0,255],[0,255],[0,255],[24,255],[141,255]]] 
         *self.ord_height = [19, 19, 19, 19,17]
         *self.orders=[7, 8, 9, 10, 11]
      end
    2:begin           ; G1
         *self.map=[[[0,0]],[[0,255]]]
         *self.ord_height = [255]
         *self.orders=[1]
      end
    3:begin           ; G3
         *self.map=[[[0,0]],[[0,255]]]
         *self.ord_height = [255]
         *self.orders=[1]
      end
    4:begin           ; G5
         *self.map=[[[0,0]],[[0,255]]]
         *self.ord_height = [255]
         *self.orders=[1]
      end
    5:begin           ; G6
         *self.map=[[[0,0]],[[0,255]]]
         *self.ord_height = [255]
         *self.orders=[2]
      end
endcase

end

;**********************************
;    LORENTZ - lorentz function
;**********************************
function lorentz, x, x_c, gamma

; gamma = half-width at half-maximum

y = fltarr(n_elements(x))

for i = 0, n_elements(x)-1 DO BEGIN
   y[i] = (gamma/( (x[i]-x_c)^2.0 + gamma^2.0))/3.14159
ENDFOR

return, y

END

;******************************************************************************
;   Pre-defined extraction 
;******************************************************************************
pro drip_extman::predefined_extraction,mode,dapname

common drip_config_info, dripconf

data=*self.data
self->setmap,mode
map=*self.map

;readcol,'drip_gui/order_calb.txt',orders,lam_low,lam_high,format='i,f,f'  ; need to modify to include polynomial fits
;readcol, 'drip_gui/order_calb.txt', grism_mode, orders, lam_low, lam_high, FORMAT='A,I,F,F', comment = '#', delimiter=','
readcol, 'drip_gui/grism/order_calb.txt', grism_mode, orders, Coeff_0, Coeff_1, Coeff_2, Coeff_3, FORMAT='A,I,F,F,F,F', skipline = 1
;readcol, 'drip_gui/order_calb.txt', grism_mode, orders, lam_low, lam_high, FORMAT='A,I,F,F', skipline = 1

n_orders=(n_elements(*self.orders))                ; number of extractions/orders

; Gets information from the header
; print, dapname
header = self.dataman->getelement(dapname,'HEADER')
extraction_mode = drip_getpar(header, 'EXTMODE')
instrument_mode = drip_getpar(header, 'INSTMODE')

; print, self.dapsel_name
; print, extraction_mode, instrument_mode

;  Figures out which grism mode we are in
case mode of
   0: grmode_txt = 'G1xG2'
   1: grmode_txt = 'G3xG4'
   2: grmode_txt = 'G1'
   3: grmode_txt = 'G3'
   4: grmode_txt = 'G5'
   5: grmode_txt = 'G6'
endcase

case instrument_mode of
    'STARE': begin
         c = [1]
    END
    'NAS': begin
         c = [1, -1]
    END
endcase


avg=0
for i=0,n_orders-1 do begin
    ; calculates the slope
    pos = where( (orders eq (*self.orders)[i]) and (grism_mode eq grmode_txt) )
    print, 'Pos = '+string(pos)+' Order = '+string(orders[pos])+', '+string((*self.orders)[i])
    slope= float(map[1,i,0]-map[0,i,0])/float(map[1,i,1]-map[0,i,1])
    ;xvalues
    xvalue=findgen(map[1,i,1]-map[0,i,1])
    ;mx=float((lam_high(pos)-lam_low(pos)))/float(map[1,i,1]-map[0,i,1])     ; Wavelength cal?
    ;wave=mx(0)*xvalue + (lam_low(pos))(0)
    C0 = coeff_0[pos]
    C1 = coeff_1[pos]
    C2 = coeff_2[pos]
    C3 = coeff_3[pos]
    wave = C0[0] + C1[0]*xvalue + C2[0]*(xvalue)^2.0 + C3[0]*(xvalue)^3.0
    ;yvalues
    yvalue=round(slope*(xvalue))+map(0,i)
    ;extracted data
    dy = (*self.ord_height)[i]

    sub_array = fltarr(n_elements(xvalue),dy+1)
    for k= 0,n_elements(xvalue)-1 do begin
        sub_array[k,*]=data[xvalue[k],yvalue[k]:(yvalue[k]+dy)]
    endfor

    case extraction_mode of
      'OPTIMAL': begin
                            ; Optimal Extraction Begins here
                  extracted_spectrum = fltarr(n_elements(sub_array[*,0]))
                  ;original = sub_array
                  for j = 0, n_elements(c)-1 DO BEGIN
                     n_segments = 16
                     sub_array *= c[j]
                     segment_size=floor(n_elements(sub_array[*,0])/n_segments)
                     
                     xx = intarr(n_segments)
                     yy = intarr(n_segments)
                     fit_status = intarr(n_segments)
                     
                     for k = 0,n_segments-1 do begin
                        ;print, k*segment_size
                        ;print, (k+1)*segment_size-1
                        piece = sub_array[k*segment_size:(k+1)*segment_size-1,*]
                        collapsed = total(piece,1)
                        
                        positive = where(collapsed ge 0)
                        xcoord = findgen(n_elements(collapsed))
                        ;Used MPFITPEAK instead of gaussfit.Need to give credit
                        collapse_fit = mpfitpeak(xcoord[positive],$
                            collapsed[positive], A, NTERMS=3, STATUS=status)
                        xx[k] = (k+0.5)*segment_size
                        yy[k] = A[1]
                        fit_status[k] = status
                     endfor

                     ;print, fit_status
                     good_fits = where(fit_status ne 5)
                     fit_result = POLY_FIT(xx[good_fits],yy[good_fits],2)
                     x = findgen(n_elements(sub_array[*,0]))
                     y = fit_result[0] + fit_result[1]*x + fit_result[2]*x^2
                     ycoord = findgen(n_elements(sub_array[0,*]))
                     
                     for k = 0, n_elements(extracted_spectrum)-1 DO BEGIN
                        filter = lorentz(ycoord, y[k], 3.0)
                        extracted_spectrum[k] += total(sub_array[k,*]* $
                                                       filter/max(filter))
                     ENDFOR
                  ENDFOR
              END
      'FULLAP' : begin
                 ; Full Aperture Extraction
                 extracted_spectrum = fltarr(n_elements(sub_array[*,0]))
                 for k = 0, n_elements(extracted_spectrum)-1 DO BEGIN
                     extracted_spectrum[k] = total(sub_array[k,*])
                 ENDFOR
              end
    endcase


    if (i eq 0) then avg1=mean(extracted_spectrum)   ; Roughly averages spectra to be on the same scale...
    avg=mean(extracted_spectrum)
    davg=avg-avg1
    extracted_spectrum=extracted_spectrum-davg
    *self.allwave[i]=wave
    *self.allflux[i]=extracted_spectrum
endfor
end
;******************************************************************************
;     Get Data - Send new sets of data
;******************************************************************************
function drip_extman::getdata,data=data,extract=ext,dapsel_name=dapn,$
                    wave_num=wave_num, flux_num=flux_num,$
                    orders=orders
if keyword_set(data) then  return, self.data
if keyword_set(ext) then return, self.extract
if keyword_set(dapn) then return, self.dapsel_name
if keyword_set(wave_num) then return, *self.allwave[abs((*self.orders)[0]-wave_num)]
if keyword_set(flux_num) then return, *self.allflux[abs((*self.orders)[0]-flux_num)]
if keyword_set(orders) then return, (*self.orders)

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
;   This routine is used solely for extraction of user-defined ROI
;******************************************************************************
pro drip_extman::user_defined_extraction

common drip_config_info, dripconf

;extract
data=*self.data

dy=self.boxy1-self.boxy2 ; height

slope= float(self.boxy2-self.boxy0)/float(self.boxx2-self.boxx0) ;slope

xvalue=round(findgen(self.boxx2-self.boxx0+1) + self.boxx0)

yvalue=round(slope*(xvalue-self.boxx0))+self.boxy0

;print,'xend:',xvalue(n_elements(xvalue)-1),xvalue(0)
;print,'yend:',yvalue(n_elements(yvalue)-1),yvalue(0)
;print,'dy:',dy,self.boxy1,self.boxy2

sub_array = fltarr(n_elements(xvalue),dy+1)

for i= 0,n_elements(xvalue)-1 do begin
    sub_array[i,*]=data[xvalue[i],yvalue[i]:(yvalue[i]+dy)]
endfor

header = self.dataman->getelement(self.dapsel_name,'HEADER')
extraction_mode = drip_getpar(header, 'EXTMODE')
instrument_mode = drip_getpar(header, 'INSTMODE')

;print, size(header)
;print, self.dapsel_name
;print, 'Extraction mode : ', extraction_mode
case extraction_mode of
   'OPTIMAL': begin
              ; Optimal Extraction Begins here
                  case instrument_mode of
                      'STARE': begin
                          c = [1]
                      END
                      'NAS': begin
                          c = [1, -1]
                      END
                  endcase
                  extracted_spectrum = fltarr(n_elements(sub_array[*,0]))
                  ;original = sub_array
                  for j = 0, n_elements(c)-1 DO BEGIN
                     n_segments = 16
                     sub_array *= c[j]
                     segment_size=floor(n_elements(sub_array[*,0])/n_segments)
                     
                     xx = intarr(n_segments)
                     yy = intarr(n_segments)
                     fit_status = intarr(n_segments)
                     
                     for i = 0,n_segments-1 do begin
                        print, i*segment_size
                        print, (i+1)*segment_size-1
                        piece = sub_array[i*segment_size:(i+1)*segment_size-1,*]
                        collapsed = total(piece,1)
                        
                        positive = where(collapsed ge 0)
                        xcoord = findgen(n_elements(collapsed))
                        ;Used MPFITPEAK instead of gaussfit.Need to give credit
                        collapse_fit = mpfitpeak(xcoord[positive],$
                            collapsed[positive], A, NTERMS=3, STATUS=status)
                        xx[i] = (i+0.5)*segment_size
                        yy[i] = A[1]
                        fit_status[i] = status
                     endfor

                     print, fit_status
                     good_fits = where(fit_status ne 5)
                     fit_result = POLY_FIT(xx[good_fits],yy[good_fits],2)
                     x = findgen(n_elements(sub_array[*,0]))
                     y = fit_result[0] + fit_result[1]*x + fit_result[2]*x^2
                     ycoord = findgen(n_elements(sub_array[0,*]))
                     
                     for i = 0, n_elements(extracted_spectrum)-1 DO BEGIN
                        filter = lorentz(ycoord, y[i], 3.0)
                        extracted_spectrum[i] += total(sub_array[i,*]* $
                                                       filter/max(filter))
                     ENDFOR
                  ENDFOR
              END
   'FULLAP' : begin
                 ; Full Aperture Extraction
                 extracted_spectrum = fltarr(n_elements(sub_array[*,0]))
                 for i = 0, n_elements(extracted_spectrum)-1 DO BEGIN
                     extracted_spectrum[i] = total(sub_array[i,*])
                 ENDFOR
              end
endcase
              
*self.extract=extracted_spectrum
end


;******************************************************************************
;     NEWDATA - Sets new sets of data
;******************************************************************************

pro drip_extman::newdata,data=data,$
                         boxx0=boxx0, boxy0=boxy0,$
                         boxx1=boxx1, boxy1=boxy1,$
                         boxx2=boxx2, boxy2=boxy2,map=map,$
                         dapsel_name=dapsel_name


print,'SETTING DATA IN EXTMAN'
if keyword_set(data) then self.data=data
if keyword_set(boxx0) then self.boxx0=boxx0 else self.boxx0=0
if keyword_set(boxy0) then self.boxy0=boxy0 else self.boxy0=0
if keyword_set(boxx1) then self.boxx1= boxx1
if keyword_set(boxy1) then self.boxy1= boxy1
if keyword_set(boxx2) then self.boxx2=boxx2 else self.boxx2=0
if keyword_set(boxy2) then self.boxy2=boxy2 else self.boxy2=0
if keyword_set(map) then *self.map=map
if keyword_set(dapsel_name) then self.dapsel_name=dapsel_name

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
ptr_free,self.orders
ptr_free,self.ord_height
ptr_free,self.map
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
self.orders=ptr_new(/allocate_heap)
self.ord_height=ptr_new(/allocate_heap)
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
        orders:ptr_new(),$      ;[array with order numbers]
        ord_height:ptr_new(),$  ;[array of order heights (in pixels)]
        n:0}
end
