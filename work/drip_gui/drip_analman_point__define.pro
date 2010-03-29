; NAME:
;     DRIP_ANALMAN_POINT__DEFINE - Version .7.0
;
; PURPOSE:
;     Analysis Object Manager for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANALMAN_POINT', BASEID)
;
; INPUTS:
;     BASEID - Widget ID of base to put widgets
;
; STRUCTURE:
;     TITLE - object title
;     FOCUS - focus status (1 if in focus else 0)
;     DISPOBJ - display object
;     BASEWID - base widget
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     In developement
;
; PROCEDURE:
;     Gets called by display manager
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, November 2007


;****************************************************************************
;     LOGALL - log all boxes to file
;****************************************************************************

pro drip_analman_point::logall, event

for anali=0, self.analn-1 do (*self.anals)[anali]->log

end

;****************************************************************************
;     CLOSEANAL - closes analysis object
;****************************************************************************

pro drip_analman_point::closeanal, event

; get object and display
widget_control, event.id, get_uvalue=cmd
anal=cmd.obj
disp=anal->getdata(/disp)
; find object -> index into i
i=0
while (i lt self.analn) and (anal ne (*self.anals)[i]) do i=i+1
; clear object from list (if found)
if i lt self.analn then begin
    if i gt 0 then begin
        if i lt self.analn-1 then $
            *self.anals=[(*self.anals)[0:i-1],(*self.anals)[i+1:self.analn-1]]$
          else *self.anals=[(*self.anals)[0:i-1]]
    endif else begin
        if self.analn gt 1 then *self.anals=[(*self.anals)[1:self.analn-1]] $
          else *self.anals=[obj_new()]
    endelse
    self.analn--
endif
; remove from display (will destroy object)
disp->closeanal, anal
; setallwid, draw display
self->setallwid
disp->draw

end

;****************************************************************************
;     OPENANAL - creates analysis object and orders by display
;****************************************************************************

pro drip_analman_point::openanal, event

; get dispinfocus and wid
dispinfocus=self.dispman->getdata(/dispinfocus)
wid=dispinfocus->getdata(/wid)
focid=dispinfocus->getdata(/disp_id)
; create object
analnew=obj_new('drip_anal_point',dispinfocus,self,'',wid)
; find spot in list
; ( set analnext to index of first analobj with display id > focid )
; ( OR to analobjn if necessary place is last one
analnext=0
if self.analn gt 0 then begin
    ; get first display id of first analobj
    dispi=((*self.anals)[analnext])->getdata(/disp)
    idi=dispi->getdata(/disp_id)
    ; find analobj with larger id than current
    while (focid ge idi) and (analnext lt self.analn-1) do begin
        analnext++
        dispi=((*self.anals)[analnext])->getdata(/disp)
        idi=dispi->getdata(/disp_id)
    endwhile
    ; if last anals has lower display id, increase analnext
    if focid ge idi then analnext++
endif
; add to list (in order)
;print,'openanal:',analobjn,analnext
if analnext gt 0 then anals=[(*self.anals)[0:analnext-1],analnew] $
  else anals=[analnew]
if analnext ge self.analn then *self.anals=anals $
  else *self.anals=[anals,(*self.anals)[analnext:self.analn-1]]
self.analn++
; add to display
dispinfocus->openanal,analnew
; setallwid, update all, draw display
self->setallwid
for anali=0, self.analn-1 do (*self.anals)[anali]->update
dispinfocus->draw

end

;****************************************************************************
;     SETALLWID - set widgets for all analysis objects (only where needed)
;****************************************************************************

pro drip_analman_point::setallwid

; deactivate update for upwid
widget_control, self.topwid, update=0
;** go through list of widgets: check, assign wigets (ev. create new ones)
; set variables
dispid=65 ; identifer of display of last analysis object
objcnt=0 ; counter for number of objects for current display
widn=size(*self.wids,/n_elements) ; number of widget entries
widi=1 ; index of next valid widget entry (get new widgets if > widn-1)
colwids=(*self.wids)[0]
; get largefont
common gui_os_dependent_values, largefont, smallfont
; go through list
for anali=0,self.analn-1 do begin
    ; if object in focus or shown
    if (*self.anals)[anali]->isfocus() or $
       (*self.anals)[anali]->isshow() then begin
        ; create widgets if necessary
        if widi ge widn then begin
            ; make new structure
            newwids={drip_anal_point_wids}
            ; make new widgets
            newwids.label=widget_label(colwids.label,value='A-1', $
                                       font=largefont, ysize=25)
            newwids.show=widget_button(colwids.show, value=' ', ysize=25)
            newwids.top=widget_button(colwids.top, value=' ', ysize=25)
            newwids.close=widget_button(colwids.close, value='Cls', ysize=25)
            newwids.log=widget_button(colwids.log, value=' ', ysize=25)
            newwids.color=cw_color_sel(colwids.color, [0b,0b,0b], $
                                       xsize=32, ysize=19)
            ; make 4 widgets in a row for data table
            data=lonarr(4)
            row=widget_base((colwids.data)[0], column=4,/frame)
            for i=0,3 do begin
               label=widget_label(row,xsize=65, font=smallfont,/align_center)
               data[i]=label
            endfor
            newwids.data=[row,data]
            ; append structure with new widgets to existing list
            *self.wids=[*self.wids,newwids]
        endif
        ; check if still same display
        disp=(*self.anals)[anali]->getdata(/disp)
        newid=disp->getdata(/disp_id)
        if dispid ne newid then begin
            dispid=newid
            objcnt=1
        endif else objcnt=objcnt+1
        ; make analysis object title
        title=string(string(byte(dispid)),objcnt,format='(A,"-",I1)')
        ; pass widgets to object
        (*self.anals)[anali]->setwid, (*self.wids)[widi], title
        ; increase widi
        widi=widi+1
    endif
endfor
;** destroy leftover widgets
if widi lt widn then begin
    ; destroy widgets
    while widi lt widn do begin
        oldwids=(*self.wids)[widn-1]
        widget_control, oldwids.label, /destroy
        widget_control, oldwids.show, /destroy
        widget_control, oldwids.top, /destroy
        widget_control, oldwids.close, /destroy
        widget_control, oldwids.color, /destroy
        widget_control, oldwids.log, /destroy
        widget_control, oldwids.data[0], /destroy ; destroys row of widgets
        widn=widn-1
    end
    ; shorten list of widget structure
    *self.wids=(*self.wids)[0:widn-1]
endif
; activate update for upwid
widget_control, self.topwid, update=1

end

;******************************************************************************
;     START - starts analysis object manager
;******************************************************************************

pro drip_analman_point::start, dispman

self.dispman=dispman

end

;****************************************************************************
;     INIT - to create analysis object manager
;****************************************************************************

function drip_analman_point::init, baseid

;** set initial variables
self.type='point'
self.analn=0
self.anals=ptr_new(/allocate_heap)
self.wids=ptr_new(/allocate_heap)

;** make widgets
common gui_os_dependent_values, largefont, smallfont
; header (with logall)
self.topwid=widget_base(baseid, /column, /frame, $
                        event_pro='drip_anal_eventhand' )
headwid=widget_base(self.topwid,/row,/align_left)
title=widget_label(headwid, value='Point:', font=largefont)
self.new=widget_button(headwid, value='New Aperture', $
                       uvalue={object:self, method:'openanal'} )
self.logall=widget_button(headwid, value='Log All', $
                          uvalue={object:self, method:'logall'} )
;-- table
table=widget_base(self.topwid, /row)
; label
label=widget_base(table, /column)
labellabel=widget_label(label, value='Box#')
; show
show=widget_base(table, /column)
showlabel=widget_label(show, value='Show')
; top
top=widget_base(table, /column)
toplabel=widget_label(top, value='Top')
; close
close=widget_base(table, /column)
closelabel=widget_label(close, value='Close')
; log
log=widget_base(table, /column)
loglabel=widget_label(log, value='Log')
; color
color=widget_base(table, /column)
colorlabel=widget_label(color, value='Color')
; data: make headers for data columns
dataheaders=['FWHM (x / y)','Source (e-)', 'Noise (e-)', 'S/N']
dtbl=widget_base(table, /column)
row=widget_base(dtbl, column=6)
for i=0,3 do begin
   datalabel=widget_label(row, font=smallfont, /frame, $
                          value=dataheaders[i], xsize=65)
endfor
data=lonarr(5)
data[*]=widget_base(dtbl, column=1)

;** create structure and fill in
widlist={drip_anal_point_wids, label:label, show:show, top:top, $
         close:close, log:log, color:color, data:data}
*self.wids=[widlist]

return, 1

end

;****************************************************************************
;     DRIP_ANAL_POINT__DEFINE
;****************************************************************************

pro drip_analman_point__define

struct={drip_analman_point, $
        ; overall widget ids
        new:0L, $                ; new widget button
        logall:0L, $             ; logall button
        wids:ptr_new(), $        ; analysis object widgets
                        ; ( array of records, first entry is column widetID )
        dispman:obj_new(), $     ; reference to dispman
        inherits drip_analman}   ; child object of drip_analman
end
