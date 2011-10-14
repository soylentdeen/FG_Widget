; NAME:
; DRIP_IMGNONLIN - Version .1.0
;
; PURPOSE:
; Corrects for non-linearity in detector response due to general background
;
; CALLING SEQUENCE:
;       LINEARIZED=DRIP_IMGNONLIN(DATA, BASEHEAD, SECTION=SECTION)
;
; INPUTS:
;       DATA - the data to be undistorted.
;       BASEHEAD - output header of the pipelining
;       SIGLEV - use this instead of info in basehead
;                 format is [X0,Y0,XDIM,YDIM]      
;                   X0,Y0: Center of the section
;                   XDIM,YDIM: Dimension of the section
;
; SIDE EFFECTS:
; 
;
; RESTRICTIONS:
;       The header must contain the information to determine the camera
;       and also the background level and size of the section used 
;       to calculate the level
;
; PROCEDURE:
; Read the background level from the image, calculate the non-linerarity
; correction and apply the correction.
;
; MODIFICATION HISTORY:
;   Written by:  W D Vacca,  USRA, April 2011
;	Modified:       Miguel Charcos Llorens, USRA, May 2011
;                       Fit into DRIP code
; 
;

;******************************************************************************
; DRIP_IMGNONLIN - Corrects for non-linearity due to general background
;******************************************************************************

function drip_imgnonlin, data, basehead, siglev=siglev
    
  ; Read background level in header
  if keyword_set(siglev) eq 0 then begin
    siglev_read=drip_getpar(basehead,'NLINSLEV')
    if siglev_read eq 'x' then begin
      drip_message, 'WARNING: The signal level has not been saved properly in the header'
      return,data
    endif
    siglev=float(strsplit(siglev_read,'[],',/extract))
  endif
  
  s = size(data)
  if (s[0] eq 2) AND (s[0] eq 3) then begin
    drip_message, 'WARNING: The size of data is incorrect (drip_imgnonlin)'
    drip_message, '         Linear correction is not applied'
    return,data
  endif
  if (s[0] eq 2) then begin
    if n_elements(siglev) gt 1 then begin
      drip_message, 'WARNING: The size of the signal does not match the size of the data (drip_imgnonlin)'
      drip_message, '         Linear correction is not applied'
      return,data
    endif
  endif
  if (s[0] eq 3) then begin
    if n_elements(siglev) ne s[3] then begin
      drip_message, 'WARNING: The size of the signal does not match the size of the data (drip_imgnonlin)'
      drip_message, '         Linear correction is not applied'
      return,data
    endif
  endif
  
  ; Read header and determine camera
  ; We use Wavelength because filt2_s is a string
  ; filt_read=drip_getpar(basehead,'FILT2_S')
  filt_read=drip_getpar(basehead,'WAVELNTH')
  if filt_read eq 'x' then begin
    drip_message, 'WARNING: Wavelength is not defined in header (drip_imgnonlin)'
    drip_message, '         Linear correction is not applied'
    return, data
  endif
  filt = float(filt_read)
  if filt eq 0.0 then begin
    drip_message, 'WARNING: Wavelength is not correctly defined (drip_imgnonlin)'
    drip_message, '         Linear correction is not applied'
    return, data
  endif
  if (filt le 24.2) then camera = 'SWC' else camera='LWC'
  
  epadu_read=drip_getpar(basehead,'EPERADU')
  if epadu_read eq 'x' then begin
    drip_message, 'WARNING: E/ADU is not defined in header (drip_imgnonlin)'    
    icap_read=drip_getpar(basehead,'ILOWCAP')
    if icap_read eq 'x' then begin
      drip_message, 'WARNING: ILOWCAP is not defined in header (drip_imgnonlin)'
      drip_message, '         Linear correction is not applied'
      return, data
    endif
    icap   = fxpar(basehead,'ILOWCAP')
    if (icap eq 1)    then cap = 'Lo' else cap = 'Hi'
    return, data
  endif else begin
    epadu = fix(epadu_read)
    CASE epadu of
       136  : cap='Lo'
       1294 : cap='Hi'
       else: begin
	     drip_message, 'WARNING: E/ADU is not correctly defined [epadu='+epadu_read+'] (drip_imgnonlin)'
	     drip_message, '         Linear correction is not applied'
	     return, data         
	   end
    ENDCASE
  endelse
  drip_message,'Using camera '+camera+' with '+cap+' capacity'
  
  ; Read correction parameters in dripconfig
  ; Read refsig, scale
  refsig_read=drip_getpar(basehead,'NLINREFS')
  if refsig_read eq 'x' then begin
    refsig = 9000.
    drip_message, 'WARNING: NLINREFSIG is not defined in configuration file (drip_imgnonlin)'
    drip_message, '         Default value is '+strtrim(refsig,1)
  endif else begin
    refsig = float(refsig_read)
  endelse
  
  scale_read=drip_getpar(basehead,'NLINSCAL')
  if scale_read eq 'x' then begin
    scale = 1000.
    drip_message, 'WARNING: NLINSCALE is not defined in configuration file (drip_imgnonlin)'
    drip_message, '         Default value is '+strtrim(scale,1)
  endif else begin
    scale = float(scale_read)
  endelse
  
  ; Read coeff and lims which depend on camera and cap
  coeff_read=drip_getpar(basehead,'NLC'+camera+cap)
  if coeff_read eq 'x' then begin
    drip_message, 'WARNING: NLINC'+camera+cap+' is not defined in configuration file (drip_imgnonlin)'
    drip_message, '         Linear correction is not applied'
    return, data
  endif
  pars=float(strsplit(coeff_read,'[],',/extract))
  
  lims_read=drip_getpar(basehead,'LIM'+camera+cap)
  if lims_read eq 'x' then begin
    drip_message, 'WARNING: LIM'+camera+cap+' is not defined in configuration file (drip_imgnonlin)'
    drip_message, '         Linear correction is not applied'
    return, data
  endif
  lims=float(strsplit(lims_read,'[],',/extract))
  if n_elements(lims) ne 2 then begin
    drip_message, 'WARNING: NLINLIM'+camera+cap+' has wrong format (drip_imgnonlin)'
    drip_message, '         Linear correction is not applied'
    return, data  
  endif
  
  ; Calculate correction
  xval = (siglev - refsig)/scale
  corr = poly(xval,pars)
  
  ; If required, write flaf to basehead
  ksig = where((siglev lt lims[0]) or (siglev gt lims[1]))
  ;if (siglev lt lims[0]) or (siglev gt lims[1]) then begin
  if ksig(0) ne -1 then begin
    sxaddpar, basehead, 'NLINFLAG', 1
    for j=0,n_elements(ksig)-1 do begin
      drip_message, 'WARNING: Level '+strtrim(siglev(ksig(j)),1)+' outside fit range: ['+strtrim(string(lims[0]),1)+' '+strtrim(string(lims[1]),1)+']'
      fxaddpar, basehead, 'HISTORY', 'Signal level for plane '+string(strtrim(j,2))+' outside correction range'
    endfor
  endif
  
  ; Apply correction
  linearized = data
  if (s[0] eq 2) then linearized=data/corr
  if (s[0] eq 3) then begin
    linearized=fltarr(s[1],s[2],s[3],/nozero)
    for i=0,s[3]-1 do begin
      linearized[*,*,i] = data[*,*,i]/corr(i)
    endfor
  endif  
  
  return, linearized
end
