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

pro drip_spextract, data, header, basehead
; error check
sd=size(data)

multi_order, mode, dapname


drip_message, 'Done with spectral extraction'

end

;******************************************************************************
;     SPEXTRACT__DEFINE - Define the SPEXTRACT class structure.
;******************************************************************************

pro spectract__define  ;structure definition

struct={spextract, $
      inherits drip_extman} ; child object of drip_extman object
end
