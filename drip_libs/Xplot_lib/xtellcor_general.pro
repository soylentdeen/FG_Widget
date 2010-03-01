;+
; NAME:
;     xtellcor_general
;    
; PURPOSE:
;     General telluric correction widget.
;    
; CATEGORY:
;     Widget
;
; CALLING SEQUENCE:
;     xtellcor_general
;    
; INPUTS:
;     None
;    
; OPTIONAL INPUTS:
;     None
;
; KEYWORD PARAMETERS:
;     None
;     
; OUTPUTS:
;     Writes a text file to disk of the telluric corrected spectrum
;
; OPTIONAL OUTPUTS:
;     None
;
; COMMON BLOCKS:
;     None
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     None
;
; PROCEDURE:
;     Follow the directions
;
; EXAMPLE:
;     
; MODIFICATION HISTORY:
;     2001 - Written by M. Cushing, Institute for Astonomy, UH
;-


;
;******************************************************************************
;
; ------------------------------Event Handlers-------------------------------- 
;
;******************************************************************************
;
pro xtellcor_general_helpevent,event

widget_control, event.top, /DESTROY

end
;
;******************************************************************************
;
pro xtellcor_general_event, event

widget_control, event.top, GET_UVALUE = state, /NO_COPY
widget_control, event.id,  GET_UVALUE = uvalue
widget_control, /HOURGLASS

case uvalue of

    'Additional Output': begin

        if event.value eq 'Telluric' then state.r.telluricoutput=event.select
        if event.value eq 'A0 V' then state.r.vegaoutput=event.select

    end

    'B Magnitude Field': setfocus, state.w.vmag_fld

    'Construct Kernel': xtellcor_general_conkernel,state
    
    'Construct Telluric Spectra': xtellcor_general_contellspec,state

    'Get Shift': xtellcor_general_getshift,state

    'Help': xtellcor_general_help,state

    'Load Spectra': xtellcor_general_loadspec,state

    'Method': begin

        state.r.method = event.value
        
        if event.value eq 'Deconvolution' then widget_control, $
          state.w.box2a_base,MAP=1 else $
          widget_control, state.w.box2a_base, MAP=0
        
    end

    'Object Spectra Button': begin

        path = cfld(state.w.path_fld,7,CANCEL=cancel)
        if cancel then return
        obj = dialog_pickfile(DIALOG_PARENT=state.w.xtellcor_general_base,$
                              PATH=path,/MUST_EXIST,FILTER='*.dat')
        if obj eq '' then goto, cont
        widget_control,state.w.objspectra_fld[1], $
          SET_VALUE = strmid(obj[0],strpos(obj,'/',/REVERSE_S)+1)
        setfocus,state.w.objspectra_fld

    end

    'Output Format': begin

        if event.value eq 'Text' then state.r.textoutput=event.select
        if event.value eq 'FITS' then state.r.fitsoutput=event.select
        
    end

    'Path Button': begin

        path= dialog_pickfile(/DIRECTORY,$
                              DIALOG_PARENT=state.w.xtellcor_general_base,$
                              TITLE='Select Path',/MUST_EXIST)
        
        if path ne '' then begin

            path = cpath(path,WIDGET_ID=state.w.xtellcor_general_base,$
                         CANCEL=cancel)
            if cancel then return
            widget_control,state.w.path_fld[1],SET_VALUE = path
            setfocus,state.w.path_fld
            setfocus,state.w.stdspectra_fld

        endif

    end

    'Plot Object Order': state.r.plotobjorder = $
      (*state.d.objorders)[event.index]

    'Standard Order': state.r.stdorder = (*state.d.stdorders)[event.index]

    'Quit': begin

        widget_control, event.top, /DESTROY
        goto, getout
        
    end

    'Scale Lines': xtellcor_general_getscales,state

    'Spectrum Units': begin

        case event.index of 

            0: state.r.units = 'ergs s-1 cm-2 A-1'
            1: state.r.units = 'ergs s-1 cm-2 Hz-1'
            2: state.r.units = 'W m-2 um-1'
            3: state.r.units = 'W m-2 Hz-1'
            4: state.r.units = 'Jy'
        
        endcase 

    end

    'Standard Spectra Button': begin

        path = cfld(state.w.path_fld,7,CANCEL=cancel)
        if cancel then return
        std = dialog_pickfile(DIALOG_PARENT=state.w.xtellcor_general_base,$
                             PATH=path,/MUST_EXIST,FILTER='*.dat')
        
        if std eq '' then goto, cont
        widget_control,state.w.stdspectra_fld[1],$
          SET_VALUE = strmid(std[0],strpos(std,'/',/REVERSE_S)+1)
        setfocus,state.w.stdspectra_fld

    end

    'Standard Spectra Field': setfocus,state.w.bmag_fld

    'V Magnitude Field': setfocus, state.w.objspectra_fld

    'Write File': xtellcor_general_writefile,state

    else:

endcase

;  Put state variable into the user value of the top level base.
 
cont: 
widget_control, state.w.xtellcor_general_base, SET_UVALUE=state, /NO_COPY
getout:

end
;
;******************************************************************************
;
; ----------------------------Support procedures------------------------------ 
;
;******************************************************************************
;
pro xtellcor_general_cleanup,base

widget_control, base, GET_UVALUE = state, /NO_COPY
if n_elements(state) ne 0 then begin

    ptr_free, state.r.normmask
    ptr_free, state.d.atrans
    ptr_free, state.d.awave
    ptr_free, state.d.corspec
    ptr_free, state.d.objhdr
    ptr_free, state.d.objorders
    ptr_free, state.d.objspec
    ptr_free, state.d.nstd
    ptr_free, state.d.stdhdr
    ptr_free, state.d.stdorders
    ptr_free, state.d.stdspec
    ptr_free, state.d.tellspec
    ptr_free, state.d.wvega
    ptr_free, state.d.swvega
    ptr_free, state.d.fvega
    ptr_free, state.d.cfvega
    ptr_free, state.d.cf2vega

    ptr_free, state.p.flux
    ptr_free, state.p.wave

endif
state = 0B

end
;
;******************************************************************************
;
pro xtellcor_general_changeunits,wave,tellspec,tellspec_error,state

c = 2.99792458e+8

case state.r.units of 

    'ergs s-1 cm-2 A-1': 

    'ergs s-1 cm-2 Hz-1': begin

        tellspec       = temporary(tellspec)* wave^2 * (1.0e-2 / c)
        tellspec_error = temporary(tellspec_error)* wave^2 * (1.0e-2 / c)

    end
    'W m-2 um-1': begin 

        tellspec       = temporary(tellspec)*10.
        tellspec_error = temporary(tellspec_error)*10.
            
    end
    'W m-2 Hz-1': begin

        tellspec       = temporary(tellspec)* wave^2 * (1.0e-5 / c)
        tellspec_error = temporary(tellspec_error)* wave^2 * (1.0e-5 / c)

    end
    
    'Jy': begin

        tellspec       = temporary(tellspec)* wave^2 * (1.0e21 / c) 
        tellspec_error = temporary(tellspec_error)* wave^2 * (1.0e21 / c) 

    end

endcase

end
;
;******************************************************************************
;
pro xtellcor_general_conkernel,state

if state.r.continue lt 1 then begin

    ok = dialog_message('Previous steps not complete.',/ERROR,$
                        DIALOG_PARENT=state.w.xtellcor_general_base)
    return
    
endif


vkernw_pix = state.d.fwhm/state.r.vdisp

nkernel = round(10.*vkernw_pix)
if not nkernel mod 2 then nkernel = nkernel + 1

kernel = psf_gaussian(NDIMEN=1,NPIX=nkernel,FWHM=vkernw_pix,/NORMALIZE)

state.r.vshift   = 0.0
state.r.scale    = 1.0
*state.d.kernels  = create_struct('Order01',kernel)

state.r.continue = 2

end
;
;******************************************************************************
;
pro xtellcor_general_contellspec,state

if state.r.continue lt 3 then begin
    
    ok = dialog_message('Previous steps not complete.',/ERROR,$
                        DIALOG_PARENT=state.w.xtellcor_general_base)
    return
    
endif

*state.d.tellspec = *state.d.stdspec
*state.d.vegaspec = *state.d.stdspec
(*state.d.vegaspec)[*,2,*] = 1.0

print, 'Constructing Telluric Correction Spectrum...'

telluric, (*state.d.stdspec)[*,0],(*state.d.stdspec)[*,1],$
  (*state.d.stdspec)[*,2],state.r.vmag,(state.r.bmag-state.r.vmag),$
  (*state.d.kernels).(0),(*state.r.scales)[*,0],*state.d.wvega,$
  *state.d.fvega,*state.d.cfvega,*state.d.cf2vega,state.r.vshift,tellcor,$
  tellcor_error,scvega

xtellcor_general_changeunits,(*state.d.stdspec)[*,0],tellcor,tellcor_error,$
  state
(*state.d.tellspec)[*,1] = tellcor
(*state.d.tellspec)[*,2] = tellcor_error
(*state.d.vegaspec)[*,1] = scvega

;writefits,'vega.fits',*state.d.vegaspec
;writefits,'tellcor.fits',*state.d.tellspec

cont:

state.r.continue = 4

end
;
;******************************************************************************
;
pro xtellcor_general_getscales,state

if state.r.continue lt 2 then begin
    
    ok = dialog_message('Previous steps not complete.',/ERROR,$
                        DIALOG_PARENT=state.w.xtellcor_general_base)
    return
    
endif

vshift = state.r.vshift

wvega  = *state.d.wvega
fvega  = *state.d.fvega
fcvega = *state.d.cfvega

xscalelines,*state.d.stdspec,[1],state.r.vmag,$
  (state.r.bmag-state.r.vmag),wvega,fvega,fcvega,*state.d.cf2vega,$
  *state.d.kernels,vshift,*state.d.objspec,[1],1,state.d.awave,$
  state.d.atrans,state.r.hlines,state.r.hnames,state.r.scale,$
  scales,XUNITS=state.r.xunits,PARENT=state.w.xtellcor_general_base,$
  CANCEL=cancel

if not cancel then begin
    
    *state.r.scales = scales
    state.r.continue = 3
    state.r.vshift = vshift

endif

end
;
;******************************************************************************
;
pro xtellcor_general_help,state

getfonts,buttonfont,textfont

if not xregistered('xtellcor_general_help') then begin

    help_base = widget_base(GROUP_LEADER=state.w.xtellcor_general_base, $
                            /COLUMN, $
                            TITLE='Xtellcor_General Help')
    
    openr, lun, filepath('xtellcor_general_helpfile.txt',$
                         ROOT_DIR=state.r.packagepath,SUBDIR='helpfiles'),$
      /get_lun
    nlines = numlines(filepath('xtellcor_general_helpfile.txt',$
                               ROOT_DIR=state.r.packagepath,$
                               SUBDIR='helpfiles'))
    array = strarr(nlines)
    readf, lun, array
    free_lun, lun
    
    help_text = widget_text(help_base, $
                            /SCROLL, $
                            VALUE=array, $
                            XSIZE=80, $
                            YSIZE=24)
    
    quit = widget_button(help_base,$
                         VALUE='Done',$
                         FONT=buttonfont,$
                         UVALUE='Done Help')
      
    centertlb,help_base

    widget_control, help_base, /REALIZE
 
; Start the Event Loop. This will be a non-blocking program.
       
    XManager, 'xtellcor_general_help', $
      help_base, $
      /NO_BLOCK,$
      EVENT_HANDLER='xtellcor_general_helpevent'
    
endif

end
;
;******************************************************************************
;
pro xtellcor_general_loadspec,state

;  Get files.

path = cfld(state.w.path_fld,7,CANCEL=cancel)
if cancel then return

std = cfld(state.w.stdspectra_fld,7,/EMPTY,CANCEL=cancel)
if cancel then return
std = cfile(path+std,WIDGET_ID=state.w.xtellcor_general_base,CANCEL=cancel)
if cancel then return

bmag = cfld(state.w.bmag_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return
vmag = cfld(state.w.vmag_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return

obj = cfld(state.w.objspectra_fld,7,/EMPTY,CANCEL=cancel)
if cancel then return
obj = cfile(path+obj,WIDGET_ID=state.w.xtellcor_general_base,CANCEL=cancel)
if cancel then return

fwhm = cfld(state.w.fwhm_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return

vrot = cfld(state.w.vrot_fld,4,/EMPTY,CANCEL=cancel)
if cancel then return


;  Read spectra and load data.

rdfloat,obj,wo,fo,eo
if (size(eo))[0] ne 0 then begin

    ospec = [[wo],[fo],[eo]]

endif else begin

    ndat = n_elements(wo)
    ospec = [[wo],[fo],[replicate(1.0,ndat)]]

endelse

rdfloat,std,ws,fs,es
if (size(es))[0] ne 0 then begin

    sspec = [[ws],[fs],[es]]

endif else begin

    ndat = n_elements(ws)
    sspec = [[ws],[fs],[replicate(1.0,ndat)]]

endelse

*state.d.stdspec   = sspec
state.d.fwhm       = fwhm
*state.d.objspec   = ospec

state.r.bmag = bmag
state.r.vmag = vmag
state.r.vshift = 0.0

;  Load Vega model

restore, state.r.packagepath+'/data/lvega5.sav'
state.r.vdisp = 1.49774e-5



*state.d.wvega = wvin/10000.

;  Bill stick it here.  You will have to do it to the fcvin and fvin
;  as well.

fvin   = add_rotation(wvin,fvin,vrot)
fcvin  = add_rotation(wvin,fcvin,vrot)
fc2vin = add_rotation(wvin,fc2vin,vrot)

*state.d.cf2vega = fc2vin
*state.d.cfvega = fcvin
*state.d.fvega = fvin

state.r.continue=1

end
;
;******************************************************************************
;
pro xtellcor_general_getshift,state

if state.r.continue lt 4 then begin
    
    ok = dialog_message('Previous steps not complete.',/ERROR,$
                        DIALOG_PARENT=state.w.xtellcor_general_base)
    return
    
endif

obj_wave = (*state.d.objspec)[*,0]
obj_flux = (*state.d.objspec)[*,1]

tel_wave = (*state.d.tellspec)[*,0]
tel_flux = (*state.d.tellspec)[*,1]

interpspec,tel_wave,tel_flux,obj_wave,new_flux
shift = xfindshift(obj_wave,obj_flux,new_flux,INITSHIFT=state.r.shift,$
                   XUNITS=state.r.xunits,PARENT=state.w.xtellcor_general_base,$
                   CANCEL=cancel)

if not cancel then state.r.shift = shift

state.r.continue=5

end
;
;******************************************************************************
;
pro xtellcor_general_writefile,state

if state.r.continue lt 5 then begin
    
    ok = dialog_message('Previous steps not complete.',/ERROR,$
                        DIALOG_PARENT=state.w.xtellcor_general_base)
    return
    
endif

obj = cfld(state.w.objoname_fld,7,/EMPTY,CANCEL=cancel)
if cancel then return

path = cfld(state.w.path_fld,7,CANCEL=cancel)
if cancel then return
    
stdfile = cfld(state.w.stdspectra_fld,7,/EMPTY,CANCEL=cancel)
if cancel then return

;  Write the telluric correction spectrum to disk

if state.r.telluricoutput then begin

    npix = n_elements((*state.d.tellspec)[*,0])
    openw,lun,path+obj+'_tellspec.dat', /GET_LUN
    
    for i = 0, npix-1 do begin
        
        printf, lun,  strjoin( reform((*state.d.tellspec)[i,*],3),'  ' )
        
    endfor
    close, lun
    free_lun, lun
    
    print,'Wrote the telluric correction spectrum to '+strtrim(path+obj,2)+$
      '_tellcor.dat'
        
endif

;  Write the convolved resampled Vega spectrum to disk

if state.r.vegaoutput then begin

    npix = n_elements((*state.d.vegaspec)[*,0])        
    openw,lun,path+obj+'_A0V.dat', /GET_LUN
    
    for i = 0, npix-1 do begin
        
        printf, lun,  strjoin( reform((*state.d.vegaspec)[i,*],3),'  ' )
        
    endfor
    close, lun
    free_lun, lun
        
    print,'Wrote the Vega spectrum to '+strtrim(path+obj,2)+'_vega.dat'

endif

;  Write the telluric corrected object spectrum to disk.

corspec  = *state.d.objspec

;  Interpolate telluric spectrum onto object wavelength sampling.

interpspec,(*state.d.tellspec)[*,0],(*state.d.tellspec)[*,1],$
  (*state.d.objspec)[*,0],nflux,nerror,YAERROR=(*state.d.tellspec)[*,2]

;  Now shift spectrum.

x = findgen(n_elements((*state.d.tellspec)[*,0]))
interpspec,x+state.r.shift,nflux,x,nnflux,nnerror,YAERROR=nerror

corspec[*,1] = nnflux*(*state.d.objspec)[*,1]
corspec[*,2] = sqrt( nnflux^2 * (*state.d.objspec)[*,2]^2 + $
                     (*state.d.objspec)[*,1]^2 * nnerror^2 )

;  Now write it to disk

openw,lun,path+obj+'.dat', /GET_LUN

npix = n_elements(corspec[*,0])        
for i = 0, npix-1 do begin
    
    printf, lun,  strjoin( reform(corspec[i,*],3),'  ' )
    
endfor
close, lun
free_lun, lun

print,'Wrote the corrected spectrum to '+strtrim(path+obj,2)+'.dat'

xzoomplot,corspec[*,0],corspec[*,1]


end
;
;******************************************************************************
;
; ------------------------------Main Program---------------------------------- 
;
;******************************************************************************
;
pro xtellcor_general

mkct

;  Startup

getosinfo,dirsep,strsep

last  = strpos(!path,'Telluric')
first = strpos(!path,strsep,last,/REVERSE_SEARCH)
packagepath = strmid(!path,first+1,last-first+8)

;  Get atmosphere file

restore, filepath('atrans.sav',ROOT_DIR=packagepath,SUBDIR='data')

;  Get hydrogen lines

readfmt,filepath('HI.dat',ROOT_DIR=packagepath,SUBDIR='data'),$
  'F8.6,1x,A12',hlines,hnames


;  Set the fonts

getfonts,buttonfont,textfont

;  Build three structures which will hold important info.

w = {bmag_fld:[0,0],$
     fwhm_fld:[0L,0L],$
     message:0L,$
     objoname_fld:[0L,0L],$
     objspectra_fld:[0,0],$
     path_fld:[0L,0L],$
     stdspectra_fld:[0L,0L],$
     stdorder_dl:0L,$
     vmag_fld:[0,0],$
     vrot_fld:[0L,0L],$
     xtellcor_general_base:0L}

r = {bmag:0.,$
     hlines:hlines,$
     hnames:hnames,$
     continue:0L,$
     packagepath:packagepath,$
     scale:0.,$
     scales:ptr_new(fltarr(2)),$
     shift:0.,$
     spec:'',$
     vegaoutput:0,$
     telluricoutput:1,$
     units:'ergs s-1 cm-2 A-1',$
     vdisp:0.,$
     vmag:0.,$
     vrot:0.,$
     vshift:0.,$
     wline:0.,$
     xunits:'',$
     yunits:''}

d = {airmass:'',$
     awave:awave,$
     atrans:atrans,$
     fwhm:0.,$
     kernels:ptr_new(fltarr(2)),$
     objhdr:ptr_new(fltarr(2)),$
     objspec:ptr_new(fltarr(2)),$
     stdspec:ptr_new(fltarr(2)),$
     tellspec:ptr_new(fltarr(2)),$
     fvega:ptr_new(fltarr(2)),$
     wvega:ptr_new(fltarr(2)),$
     vegaspec:ptr_new(fltarr(2)),$
     cfvega:ptr_new(fltarr(2)),$
     cf2vega:ptr_new(fltarr(2))}

;  Load the three structures in the state structure.

state = {w:w,r:r,d:d}

state.w.xtellcor_general_base = widget_base(TITLE='Xtellcor_General', $
                                    EVENT_PRO='xtellcor_general_event',$
                                    /COLUMN)
    
   quit_button = widget_button(state.w.xtellcor_general_base,$
                               FONT=buttonfont,$
                               VALUE='Done',$
                               UVALUE='Quit')
       
   state.w.message = widget_text(state.w.xtellcor_general_base, $
                                 VALUE='',$
                                 YSIZE=1)

   row_base = widget_base(state.w.xtellcor_general_base,$
                          /ROW)

      col1_base = widget_base(row_base,$
                              /COLUMN)
      
         box1_base = widget_base(col1_base,$
                                 /COLUMN,$
                                 /FRAME)
            
            label = widget_label(box1_base,$
                                 VALUE='1.  Load Spectra',$
                                 FONT=buttonfont,$
                                 /ALIGN_LEFT)
            
            row = widget_base(box1_base,$
                              /ROW,$
                              /BASE_ALIGN_CENTER)
                  
               button = widget_button(row,$
                                      FONT=buttonfont,$
                                      VALUE='Path',$
                                      UVALUE='Path Button')
               
               field = coyote_field2(row,$
                                     LABELFONT=buttonfont,$
                                     FIELDFONT=textfont,$
                                     TITLE=':',$
                                     UVALUE='Path Field',$
                                     XSIZE=25,$
                                     /CR_ONLY,$
                                     TEXTID=textid)
               state.w.path_fld = [field,textid]    
               
            row = widget_base(box1_base,$
                              /ROW,$
                              /BASE_ALIGN_CENTER)
            
               std_but = widget_button(row,$
                                       FONT=buttonfont,$
                                       VALUE='Std Spectra',$
                                       UVALUE='Standard Spectra Button')
               
               std_fld = coyote_field2(row,$
                                       LABELFONT=buttonfont,$
                                       FIELDFONT=textfont,$
                                       TITLE=':',$
                                       UVALUE='Standard Spectra Field',$
                                       XSIZE=18,$
;                                       VALUE='O4_std.txt',$
                                       /CR_ONLY,$
                                       TEXTID=textid)
               state.w.stdspectra_fld = [std_fld,textid]
               
            row = widget_base(box1_base,$
                              /ROW,$
                              /BASE_ALIGN_CENTER)
            
               mag = coyote_field2(row,$
                                   LABELFONT=buttonfont,$
                                   fieldfont=textfont,$
                                   TITLE='Std Mag (B,V):',$
                                   UVALUE='B Magnitude Field',$
                                   XSIZE=6,$
;                                   VALUE='7',$
                                   /CR_ONLY,$
                                   TEXTID=textid)
               state.w.bmag_fld = [mag,textid]
               
               mag = coyote_field2(row,$
                                   LABELFONT=buttonfont,$
                                   fieldfont=textfont,$
                                   UVALUE='V Magnitude Field',$
                                   XSIZE=6,$
;                                   VALUE='7',$
                                   TITLE='',$
                                   /CR_ONLY,$
                                   TEXTID=textid)
               state.w.vmag_fld = [mag,textid]
               
            row = widget_base(box1_base,$
                              /row,$
                              /base_align_center)
            
               obj_but = widget_button(row,$
                                       font=buttonfont,$
                                       VALUE='Obj Spectra',$
                                       UVALUE='Object Spectra Button',$
                                       EVENT_PRO='xtellcor_general_event')
               
               obj_fld = coyote_field2(row,$
                                       LABELFONT=buttonfont,$
                                       fieldfont=textfont,$
                                       TITLE=':',$
                                       UVALUE='Object Spectra Field',$
;                                       VALUE='O4_obj.txt',$
                                       XSIZE=18,$
                                       /CR_ONLY,$
                                       TEXTID=textid)
               state.w.objspectra_fld = [obj_fld,textid]

            fwhm = coyote_field2(box1_base,$
                                 LABELFONT=buttonfont,$
                                 fieldfont=textfont,$
                                 UVALUE='FWHM Field',$
                                 XSIZE=15,$
;                                 VALUE='0.00086774',$
                                 TITLE='FWHM = ',$
                                 TEXTID=textid)
            state.w.fwhm_fld = [fwhm,textid]

            fwhm = coyote_field2(box1_base,$
                                 LABELFONT=buttonfont,$
                                 fieldfont=textfont,$
                                 UVALUE='V_rot',$
                                 XSIZE=15,$
;                                 VALUE='0.00086774',$
                                 TITLE='V_rot = ',$
                                 TEXTID=textid)
            state.w.vrot_fld = [fwhm,textid]
                     
            load = widget_button(box1_base,$
                                 VALUE='Load Spectra',$
                                 FONT=buttonfont,$
                                 UVALUE='Load Spectra')

         box2_base = widget_base(col1_base,$
                                 /COLUMN,$
                                 /FRAME)
            
            label = widget_label(box2_base,$
                                 VALUE='2.  Construct Convolution Kernel',$
                                 FONT=buttonfont,$
                                 /ALIGN_LEFT)

            method_bg = cw_bgroup(box2_base,$
                                  FONT=buttonfont,$
                                  ['Gaussian'],$
                                  /ROW,$
                                  /RETURN_NAME,$
                                  /NO_RELEASE,$
                                  /EXCLUSIVE,$
                                  LABEL_LEFT='Kernel Type:',$
                                  UVALUE='Kernel Type',$
                                  SET_VALUE=0)

            button = widget_button(box2_base,$
                                   VALUE='Construct Kernel',$
                                   UVALUE='Construct Kernel',$
                                   FONT=buttonfont)
            
      col2_base = widget_base(row_base,$
                              EVENT_PRO='xtellcor_general_event',$
                              /COLUMN)


         box3_base = widget_base(col2_base,$
                                 /COLUMN,$
                                 /FRAME)
            
            label = widget_label(box3_base,$
                                 VALUE='3.  Construct Telluric Spectra',$
                                 FONT=buttonfont,$
                                 /ALIGN_LEFT)

            getshifts = widget_button(box3_base,$
                                      VALUE='Scale Lines',$
                                      UVALUE='Scale Lines',$
                                      FONT=buttonfont)

            value =['ergs s-1 cm-2 A-1','ergs s-1 cm-2 Hz-1',$
                    'W m-2 um-1','W m-2 Hz-1','Jy']
            units_dl = widget_droplist(box3_base,$
                                       FONT=buttonfont,$
                                       TITLE='Units:',$
                                       VALUE=value,$
                                       UVALUE='Spectrum Units')

            constructspec = widget_button(box3_base,$
                                          VALUE='Construct Telluric Spectra',$
                                          UVALUE='Construct Telluric Spectra',$
                                          FONT=buttonfont)

         box4_base = widget_base(col2_base,$
                                 /COLUMN,$
                                 /FRAME)

            label = widget_label(box4_base,$
                                 VALUE='4.  Determine Shift',$
                                 FONT=buttonfont,$
                                 /ALIGN_LEFT)

            row = widget_base(box4_base,$
                              /ROW,$
                              /BASE_ALIGN_CENTER)
            
               shift = widget_button(row,$
                                     VALUE='Get Shift',$
                                     UVALUE='Get Shift',$
                                     FONT=buttonfont)

          box5_base = widget_base(col2_base,$
                                  /COLUMN,$
                                  /FRAME)

             label = widget_label(box5_base,$
                                  VALUE='5.  Write File',$
                                  FONT=buttonfont,$
                                  /ALIGN_LEFT)

            oname = coyote_field2(box5_base,$
                                  LABELFONT=buttonfont,$
                                  FIELDFONT=textfont,$
                                  TITLE='Object File:',$
                                  UVALUE='Object File Oname',$
                                  xsize=18,$
                                  textID=textid)
            state.w.objoname_fld = [oname,textid]
            

            addoutput_bg = cw_bgroup(box5_base,$
                                     FONT=buttonfont,$
                                     ['Telluric','A0 V'],$
                                     /ROW,$
                                     /RETURN_NAME,$
                                     /NONEXCLUSIVE,$
                                     LABEL_LEFT='Additional:',$
                                     UVALUE='Additional Output',$
                                     SET_VALUE=[1,0])

            write = widget_button(box5_base,$
                                  VALUE='Write File',$
                                  UVALUE='Write File',$
                                  FONT=buttonfont)

   help = widget_button(state.w.xtellcor_general_base,$
                        VALUE='Help',$
                        UVALUE='Help',$
                        FONT=buttonfont)
      
; Get things running.  Center the widget using the Fanning routine.
            
centertlb,state.w.xtellcor_general_base
widget_control, state.w.xtellcor_general_base, /REALIZE

; Start the Event Loop. This will be a non-blocking program.

XManager, 'xtellcor_general', $
  state.w.xtellcor_general_base, $
  CLEANUP='xtellcor_general_cleanup',$
  /NO_BLOCK

widget_control, state.w.xtellcor_general_base, SET_UVALUE=state, /NO_COPY

end
