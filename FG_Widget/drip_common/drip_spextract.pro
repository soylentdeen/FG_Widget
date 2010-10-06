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

; newdap
; dataman->channeladd(object_with_newdap_function)

;****************************************************************************
;     pipe_extract: extract pre-selected spectral formats as a final step
;     in the pipeline (no user interaction required)
;****************************************************************************
; 
; The following are event parameters for the user-interactive version of
; drip_analman_extract::extract_multi
; 
; G1    event={         308        222         295           1}
; event.id = 308, event.top = 222, event.handler=295, event.select=1
; G1xG2 event={         309        222         295           1}
; G3    event={         310        222         295           1}
; G3xG4 event={         311        222         295           1}
; G5    event={         312        222         295           1}
; G6    event={         313        222         295           1}

;widget_control,event.id,get_value=value
;dispinfocus=self.dispman->getdata(/dispinfocus)
;data=dispinfocus->getdata(/dataraw)
;dapname=dispinfocus->getdata(/dapname)
;if keyword_set(*data) then begin
;    self.extman->newdata,data=data
;    case value of
;        'G1xG2':mode=0
;        'G3xG4':mode=1
;        'G1'   :mode=2
;        'G3'   :mode=3
;        'G5'   :mode=4
;        'G6'   :mode=5
;    endcase
;    self.extman->multi_order,mode,dapname
;    orders=self.extman->getdata(/orders)
;    
;    xplot_multi=cw_xplot_multi(self.xplot->getdata(/xzoomplot_base),$
;                               orders=orders,$; mw=(self.dispman).mw,$
;                               extman=self.extman,$
;                               xsize=640,ysize=480)
;    id=widget_info(xplot_multi,/child)
;    widget_control,id,get_uvalue=obj
;    self.xplot_multi=obj
;    
;    self.xplot_multi->start,self
;    
;    self.xplot_multi->draw,/all
;endif

drip_message, 'Done with spectral extraction'

end

;****************************************************************************
;     CLEANUP - Destroy pointer heap variables.
;****************************************************************************

pro drip::cleanup

; cleanup data
;ptr_free, self.dispman
;ptr_free, self.extman
;ptr_free, self.xplot
;ptr_free, self.xplot_multi

end

;****************************************************************************
;     INIT - Initializes the object
;****************************************************************************
function drip_analman_extract::init,baseid

;** set initial variables

;self.dispman=ptr_new(/allocate_heap)
;self.extman=ptr_new(/allocate_heap)
;self.xplot=ptr_new(/allocate_heap)
;xplot_multi=ptr_new(/allocate_heap)

end

;******************************************************************************
;     DRIP_SPEXTRACT__DEFINE - Define the SPEXTRACT class structure.
;******************************************************************************

pro drip_spextract__define  ;structure definition

struct={spextract, $
        ;dispman:ptr_new(), $
        ;extman:ptr_new(),$
        ;xplot_multi:ptr_new(),$
        ;xplot:ptr_new(),$
        ;dispman:obj_new(), $     ; reference to dispman
        ;xplot:obj_new(), $       ; reference to xplot
        ;xplot_multi:obj_new(),$  ; cross-dispersed multiple order mode
        ;extman:obj_new(), $      ; reference to extman
        inherits drip_extman,$    ; child object of drip_extman object
        inherits drip_analman}    ;,$   ; child object of drip_analman object
        ;inherits drip_analman_extract}   ; child object of drip_analman_extract object
end
