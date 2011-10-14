; NAME:
; READ_SECTION - Version .1.0
;
; PURPOSE:
; Read the section in the configuration file and check if it is correct
;
; CALLING SEQUENCE:
;       SECTION = READ_SECTION(XDIM,YDIM,BASEHEAD)
;
; INPUTS:
;       XDIM,YDIM - Size of the image
;       BASEHEAD - output header of the pipelining
; 
; RESULT:
;       Return SECTION = [X0,Y0,XDIM,YDIM]      
;                   X0,Y0: Center of the section
;                   XDIM,YDIM: Dimension of the section
;
; SIDE EFFECTS:
; 
;
; RESTRICTIONS:
;       
;
; PROCEDURE:
; Read the the section to use in the configuratio file. If it is not correct
; it returns default value [128,128,200,200]
;
; MODIFICATION HISTORY:
;   Written by:  Miguel Charcos Llorens, USRA, May 2011
; 
;

FUNCTION read_section, xdim,ydim, basehead
    
  defaultsection = [128,128,200,200]
    
  ; Read background level in header
  section_read=drip_getpar(basehead,'NLINSECTION')
  print,section_read
  if section_read eq 'x' then begin
    section = defaultsection
    drip_message, 'WARNING: The section has not been specified in the configuration file (read_section)'
    drip_message, '         Default value is '+strtrim(section(2),1)+'x'+strtrim(section(3),1)+' centered at ['+strtrim(section(0),1)+'x'+strtrim(section(1),1)+']'
    return,defaultsection
  endif 
  
  section=fix(strsplit(section_read,'[],',/extract))
  
  if n_elements(section) ne 4 then begin
    section = defaultsection
    drip_message, 'ERROR: The section '+section_read+' has wrong format (read_section)'
    drip_message, '         Default value is '+strtrim(section(2),1)+'x'+strtrim(section(3),1)+' centered at ['+strtrim(section(0),1)+'x'+strtrim(section(1),1)+']'
    return,defaultsection
  endif
  
  ; Check if the section makes sense (xsize and ysize >10)
  if section(2) lt 10 or section(3) lt 10 then begin
    section = defaultsection
    drip_message, 'ERROR: The section '+section_read+' has wrong size values (read_section)'
    drip_message, '         Default value is '+strtrim(section(2),1)+'x'+strtrim(section(3),1)+' centered at ['+strtrim(section(0),1)+'x'+strtrim(section(1),1)+']'
    return,defaultsection
  endif
  
  ; Check if the section we choosed is not outside the detector
  if (section(0) lt section(2)/2) or (section(0)+section(2)/2) gt xdim then begin
    drip_message, 'ERROR: Wrong section size or center along X (read_section)'
    return, defaultsection
  endif
  if (section(1) lt section(3)/2) or (section(1)+section(3)/2) gt ydim then begin
    drip_message, 'ERROR: Wrong section size or center along Y (read_section)'
    return,defaultsection
  endif
    
  return, section
  
END
