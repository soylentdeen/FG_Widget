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
; 
;

;******************************************************************************
; DRIP_SPEXTRACT - Pipeline spectral extraction
;******************************************************************************

pro drip_spextract
; error check
;sd=size(data)

; G1    event={         308        222         295           1}
; event.id = 308, event.top = 222, event.handler=295, event.select=1
; G1xG2 event={         309        222         295           1}
; G3    event={         310        222         295           1}
; G3xG4 event={         311        222         295           1}
; G5    event={         312        222         295           1}
; G6    event={         313        222         295           1}

;event={WIDGET_BUTTON, id:308,top:222,handler:295,select:1}
;multi_order, event
;value='G1'
;widget_control,event.id,get_value=value


drip_message, 'Done with spectral extraction'

end

;******************************************************************************
;     SPEXTRACT__DEFINE - Define the SPEXTRACT class structure.
;******************************************************************************

pro spextract__define  ;structure definition

struct={spextract, $
        extman:obj_new(), $
        inherits drip_analman_extract} ; child object of drip_analman_extract object
end
