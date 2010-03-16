; NAME:
;     DRIP_DROPMAN - Version .7.0
;
; PURPOSE:
;     Droplist manager for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_DROPMAN', DISPMAN, MW)
;     Obj->START
;
; INPUTS:
;     DISPMAN - Display manager object reference
;     MW - Message manager object reference
;
; STRUCTURE:
;     {DRIP_DROPMAN, DROP1, DROP1INDEX, DROP2, DROP2INDEX, DISPMAN}
;     DISPMAN - display manager object reference
;     MW - message window object reference
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     limited functionality
;
; PROCEDURE:
;     handle droplist events to keep track of values.  inform DISPMAN of any
;     changes
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, 2002
;     Modified:   Alfred Lee, Cornell University, January 2003
;                 Decided to give this version a number
;     Modified:   Alfred Lee, CU, January 30, 2003
;                 Enhanced RESET.
;     Modified:   Marc Berthoud, CU, July 2003
;                 Erased most Code as CW windows now handle pipeline step selection

;******************************************************************************
;     RESET - Reset droplists
;******************************************************************************

pro drip_dropman::reset
end

;******************************************************************************
;     START
;******************************************************************************

pro drip_dropman::start
end

;******************************************************************************
;     INIT
;******************************************************************************

function drip_dropman::init, dispman, mw
self.dispman=dispman
self.mw=mw
return, 1
end

;******************************************************************************
;     DRIP_DROPMAN__DEFINE
;******************************************************************************

pro drip_dropman__define

struct={drip_dropman, $
        dispman:obj_new(), $    ; display manager object reference
        mw:obj_new()}           ; message window object reference

end
