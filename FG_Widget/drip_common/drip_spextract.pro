; NAME:
; DRIP_SPEXTRACT - Version 1.0
;
; PURPOSE:
; Pipeline spectral extraction for all FORCAST grism spectral modes
;
; CALLING SEQUENCE:
;       SPEXTRACTED=DRIP_SPEXTRACT(DATA, HEADER)
;
; INPUTS:
;       DATA - the reduced spectral image to be extracted
;       HEADER - The fits header of the new input data file
;             
;
; SIDE EFFECTS: None identified
; 
;
; RESTRICTIONS: None
; 
;
; PROCEDURE:
; Read reduced data intro extraction routines, extract, plot 1-D
; spectrum. Uses existing extraction code in drip_extman.
;
; MODIFICATION HISTORY:
;   Written by:  Luke Keller, Ithaca College, September 29, 2010
;   Modified     Luke Keller, Rob Lewis, Ithaca College, July 7, 2011
;                Moved extraction code from drip_extman__define.pro
;                now it will be a pipline step rather than gui object.
;   Modified     Luke Keller, Rob Lewis, Ithaca College, August 2, 2011
;                Changed names of grisms to apply to most recent
;                forcast setup
;   Modified     Rob Lewis, Ithaca College, August 5,2011 spectra map
;                changed due to new Cooldown cycle. (Cooldown 043)

;******************************************************************************
; DRIP_SPEXTRACT - Pipeline spectral extraction
;******************************************************************************

function drip_spextract, data, header

common drip_config_info, dripconf

;data=*self.data
;self->setmap,mode
map=map


;readcol,'drip_gui/order_calb.txt',orders,lam_low,lam_high,format='i,f,f'  ; need to modify to include polynomial fits
;readcol, 'drip_gui/order_calb.txt', grism_mode, orders, lam_low, lam_high, FORMAT='A,I,F,F', comment = '#', delimiter=','
readcol, 'drip_gui/grism/order_calb.txt', grism_mode, orders, Coeff_0, Coeff_1, Coeff_2, Coeff_3, FORMAT='A,I,F,F,F,F', skipline = 1
;readcol, 'drip_gui/order_calb.txt', grism_mode, orders, lam_low, lam_high, FORMAT='A,I,F,F', skipline = 1

orderslist=orders

;n_orders=orders                ; number of extractions/orders
;print,' n_orders', n_orders
; Gets information from the header
; print, dapname
;header = self.dataman->getelement(dapname,'HEADER')

extraction_mode = drip_getpar(header, 'EXTMODE')
instrument_mode = drip_getpar(header, 'INSTMODE')

; print, self.dapsel_name
; print, extraction_mode, instrument_mode

if(drip_getpar(header,'FILT1_S') eq 'G1+blk')then mode =2
if(drip_getpar(header,'FILT1_S') eq 'G3+blk')then mode =3
if((drip_getpar(header,'FILT4_S') eq 'grism5+blk')) then mode = 4
if((drip_getpar(header,'FILT4_S') eq 'grism6+blk')) then mode = 5
if((drip_getpar(header,'FILT1_S') eq 'G1+blk') and $
   (drip_getpar(header,'FILT2_S') eq 'grism 2')) then mode = 0
if((drip_getpar(header,'FILT1_S') eq 'G3+blk') and $
   (drip_getpar(header,'FILT2_S') eq 'grism 4')) then mode =1


if (mode gt 1) then n_orders = 1
if (mode eq 1) then n_orders = 5
if (mode eq 0) then n_orders = 8

case mode of
   0: grmode_txt = 'G1xG2'
   1: grmode_txt = 'G3xG4'
   2: grmode_txt = 'G1'
   3: grmode_txt = 'G3'
   4: grmode_txt = 'G5'
   5: grmode_txt = 'G6'
endcase

;print, 'MODE', mode

;  This case statement should actually come from the header file or master flat.
; 
case mode of
    0:begin            ; G1xG2
        ;   [ [ [y0_bottom_left, y0_bottom_right], [y1_bl, y1_br], ...], [ [x0_left, x0_right], [x1_l, x1_r], ... ] ]
        ; map=[[[202, 233],[162,210],[127,173],[98,144],[69,110],[46,84],[20,58],[0,38]], $
        ; [[0,159],[0,255],[0,255],[0,255],[0,255],[0,255],[0,255], [0,255]]]
        ; ord_height = [21, 21, 21, 21, 21, 21, 21, 18]

         map=[[[202,236],[163,210],[128,173],[97,140],[70,110],[45,84],[23,60],[0,37]],$
                    [[1,168]  ,[1,254]  ,[1,254]  ,[1,254] ,[1,254] ,[1,254],[1,254],[1,254]]]
         ord_height=[19,19,19,19,18,17,16,16]
         orders=[15, 16, 17, 18, 19, 20, 21, 22]
      end
    1:begin            ; G3xG4
         map=[[[137,231],[80,164],[33,112],[0, 69],[1, 33]], $
         [[0,255],[0,255],[0,255],[24,255],[141,255]]] 
         ord_height = [19, 19, 19, 19, 17]
         orders=[7, 8, 9, 10, 11]
      end
    2:begin           ; G1
         map=[[[0,0]],[[0,255]]]
         ord_height = [255]
         orders=[1]
      end
    3:begin           ; G3
         map=[[[0,0]],[[0,255]]]
         ord_height = [255]
         orders=[1]
      end
    4:begin           ; G5
         map=[[[0,0]],[[0,255]]]
         ord_height = [255]
         orders=[1]
      end
    5:begin           ; G6
         map=[[[0,0]],[[0,255]]]
         ord_height = [255]
         orders=[2]
      end
endcase

case instrument_mode of
    'STARE': begin
         c = [1]
    END
    'NAS': begin
         c = [-1, 1]
    END
endcase

allwave=fltarr(1)
allflux=fltarr(1)
avg=0
ext_orders=fltarr(1)
for i=0,n_orders-1 do begin
    ; calculates the slope

    pos = where( (orderslist eq orders[i]) and (grmode_txt eq grism_mode) )
  
    print, 'Pos = '+string(pos)+' Order = '+string(orders[pos])+', '+string((orders)[i])
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
    dy = (ord_height)[i]

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
                collapsed = total(piece,2, /NAN)
                
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
                                               filter/max(filter), /NAN)
             ENDFOR
          ENDFOR
          ;print, asdf
       END
       'FULLAP' : begin
                                ; Full Aperture Extraction
          extracted_spectrum = fltarr(n_elements(sub_array[*,0]))
          for k = 0, n_elements(extracted_spectrum)-1 DO BEGIN
             extracted_spectrum[k] = total(sub_array[k,*], /NAN)
          ENDFOR
       end
    endcase
    
    if (i eq 0) then avg1=mean(extracted_spectrum) ; Roughly averages spectra to be on the same scale...
    avg=mean(extracted_spectrum)
    davg=avg-avg1
    extracted_spectrum=extracted_spectrum-davg
   
    allwave=[allwave,wave]
    allflux=[allflux,extracted_spectrum]


    ;print, 'ORDERS   ',orders[i]
    ;print, 'I', i
    sz_wave=size(wave)
    ;print,'sz',  sz_wave
    list_orders=replicate(orders[i],sz_wave[1],1)
 
    ;print,'list_orders', list_orders
    ext_orders=[ext_orders, list_orders]
 endfor

allwave=allwave[1:*,*]
allflux=allflux[1:*,*]
ext_orders=ext_orders[1:*,*]

;print, 'ORDERS', ext_orders[0:20,*]

; G5 and G6 have lambda increaseing right to left (all others are left
; to right. So flitp G5 and G6 'allflux' arrays.

if (mode eq 4) OR (mode eq 5) then begin
   print,'reversing g5 or g6 wavelength order'
   allflux=reverse(allflux) ; reverse order so lambda left --> right
   extracted =[[allwave],[allflux],[ext_orders]]
endif else begin
   extracted = [[allwave],[allflux],[ext_orders]]
endelse
print, 'Extracted Spectrum : ', extracted
return, extracted

end
