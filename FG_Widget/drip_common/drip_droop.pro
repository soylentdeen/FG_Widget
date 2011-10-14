; NAME:
;	DRIP_DROOP - Version .7.0
;
; PURPOSE:
;	Corrects droop electronic signal.
;
; CALLING SEQUENCE:
;       UNDROOP=DRIP_DROOP(DARR, BASEHEAD ,FRAC=frac)
;
; INPUTS:
;	DARR - the data to be corrected from droop.
;       BASEHEAD - output header of the pipelining. 
;       FRAC - 
;
; SIDE EFFECTS: 
;
; RESTRICTIONS:
;
; PROCEDURE:
;	
;
; MODIFICATION HISTORY:
;   Written by:  W D Vacca,  USRA, April 2011
;                based on Pascal routine by Terry Herter
;	Modified:       Miguel Charcos Llorens, USRA, April 2011
;                       Fit into DRIP code
;

FUNCTION drip_droop, darr, basehead, FRAC=frac

  if not(keyword_set(FRAC)) then begin
    frac_read = drip_getpar(basehead,'FRACDROOP')
    if frac_read eq 'x' then frac = 0.0035 $
    else frac=float(frac_read)
  endif
  
  minval_read = drip_getpar(basehead,'MINDROOP')
  if minval_read eq 'x' then begin
    minval = 0.0
    drip_message, 'WARNING: MINDROOP not found. Default value is '+strtrim(minval,1)
  endif else begin
    minval = float(minval_read)
  endelse
  
  maxval_read = drip_getpar(basehead,'MAXDROOP')
  if maxval_read eq 'x' then begin
    maxval = 65535.0
    drip_message, 'WARNING: MAXDROOP not found. Default value is '+strtrim(maxval,1)
  endif else begin
    maxval = float(maxval_read)
  endelse
  
  nreadouts_read = drip_getpar(basehead,'NRODROOP')
  if nreadouts_read eq 'x' then begin
    nreadouts = 16
    drip_message, 'WARNING: NRODROOP not found. Default value is '+strtrim(nreadouts,1)
  endif else begin
    nreadouts = float(nreadouts_read)
  endelse

  sz = size(darr)
  dim = sz(0)
  nx  = sz(1)
  ny  = sz(2)
  nplanes = 1
  if (dim gt 2) then nplanes = sz(3)

  nsets = fix(float(nx)/float(nreadouts))

  for l = 0,nplanes-1 do begin

      if (dim gt 2) then data = darr[*,*,l] else data = darr

      for j = 0,ny-1 do begin
          for i=0,nsets-1 do begin
              indx = i*nreadouts
              corr = frac*total(data[indx:indx+nreadouts-1,j])
              for k = indx,indx+nreadouts-1 do begin
                  temp  = (data[k,j] + corr lt minval) ? minval : data[k,j] + corr
                  temp  = (data[k,j] + corr gt maxval) ? maxval : data[k,j] + corr 
                  data[k,j] = temp
              endfor
          endfor
      endfor

      if (dim gt 2) then darr[*,*,l] = data else darr = data

  endfor

  sxaddpar, basehead, 'HISTORY', 'Applied channel suppression correction'
  sxaddpar, basehead, 'HISTORY', 'Channel suppression correction factor '+strtrim(string(frac), 2) 

  return, darr

END 
