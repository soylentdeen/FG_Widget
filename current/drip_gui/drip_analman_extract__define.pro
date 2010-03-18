; NAME:
;     DRIP_ANALMAN_EXTRACT__DEFINE - Version .7.0
;
; PURPOSE:
;     Analysis Object Manager for the GUI
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_ANALMAN_EXTRACT', BASEID)
;
; INPUTS:
;     BASEID - Widget ID of base to put widgets
;
; STRUCTURE:
;     TITLE - object title
;     FOCUS - focus status (1 if in focus else 0)
;     DISOBJ - display object
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
;     Written by:  Nirbhik Chitrakar, Ithaca College, December 2007
;                  (based on old drip_analman_stats)
;************************************************************************
;     Read/Write event
;************************************************************************
pro drip_analman_extract::rwevent,event

widget_control,event.id,get_uvalue=uvalue

case uvalue.uval of
    'open ascii':begin
       self->openfile,/ascii      
    end
    'open fits':self.xplot->readfile,/fits
    'save ascii': self.xplot->writefile,/txt
    'save fits':self.xplot->writefile,/fits
    'save ps':self.xplot->writefile,/ps
    else:
endcase


end

;****************************************************************************
;     Extract_multi: extract multiple orders
;****************************************************************************

pro drip_analman_extract::multi_order,event

widget_control,event.id,get_value=value
dispinfocus=self.dispman->getdata(/dispinfocus)
data=dispinfocus->getdata(/dataraw)
if keyword_set(*data) then begin
    self.extman->newdata,data=data
    case value of
        'G1xG2':mode=0
        'G3xG4':mode=1
;        'G5xG6':mode=2
    endcase
    self.extman->multi_order,mode
    orders=self.extman->getdata(/orders)
    
    xplot_multi=cw_xplot_multi(self.xplot->getdata(/xzoomplot_base),$
                               mw=(self.dispman).mw,orders=orders,$
                               extman=self.extman,$
                               xsize=640,ysize=480)
    id=widget_info(xplot_multi,/child)
    widget_control,id,get_uvalue=obj
    self.xplot_multi=obj
    
    self.xplot_multi->start,self
    
    self.xplot_multi->draw,/all
endif

end

;****************************************************************************
;     Extract - extraction of all selected anal obj
;****************************************************************************
pro drip_analman_extract::extract,event
                                ;if there are any analobjs
  plot=0
  plotanals=objarr(20)
  j=0                           ;counter for anals to be plotted
  for i=0,self.analn-1 do begin
     if ((*self.anals)[i]->getdata(/focus) eq 1) or $
        ((*self.anals)[i]->getdata(/show) eq 1) then begin
        if (obj_class((*self.anals)[i]) eq 'DRIP_ANAL_EXTRACT') then begin
           plotanals[j]= (*self.anals)[i]
           j++
        endif
     endif
  endfor
                                ;check for extract objects set for
                                ;primary plot
  n=0                           ;counter for while loop
  if (j gt 0) then begin
     while((n ne j) and (plot ne 1)) do begin
        plot=plotanals[n]->getdata(/plot)
        n++
     endwhile
     n--                        ;ends up being one bigger than the one we need
                                ;check to see if none are set to primary
     if (n lt j) then begin
        plotanals[n]->extraction,event
        for i=0,j-1 do begin
           if(plotanals[i]->getdata(/plot) eq 2) then begin
              plotanals[i]->extraction,event
           endif
        endfor
     endif else begin
        self.mw->print,'At least one must be primary'
     endelse
  endif
  
  
end


;****************************************************************************
;     CLOSEOPENANAL - closes open file analysis object
;****************************************************************************

pro drip_analman_extract::closeopenanal, event

; get object and display
widget_control, event.id, get_uvalue=cmd
anal=cmd.obj
;disp=anal->getdata(/disp)
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
;disp->closeanal, anal
; setallwid, draw display
self->setallwid
;disp->draw

end
;****************************************************************************
;     CLOSEANAL - closes analysis object
;****************************************************************************

pro drip_analman_extract::closeanal, event

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

pro drip_analman_extract::openanal, event

; get dispinfocus and wid
dispinfocus=self.dispman->getdata(/dispinfocus)
wid=dispinfocus->getdata(/wid)
focid=dispinfocus->getdata(/disp_id)
; create object
analnew=obj_new('drip_anal_extract',dispinfocus,self,wid)
; find spot in list
; ( set analnext to index of first analobj with display id > focid )
; ( OR to analobjn if necessary place is last one
analnext=0
print,'analn=',self.analn
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
self.analn=self.analn+1
; add to display
dispinfocus->openanal,analnew
print,'here'
; setallwid, update all, draw display
self->setallwid
for anali=0, self.analn-1 do (*self.anals)[anali]->update
dispinfocus->draw

end

;****************************************************************************
;     OPENFile - creates analysis object and orders by display
;****************************************************************************
pro drip_analman_extract::openfile,fits=fits,ascii=ascii

; get dispinfocus and wid
dispinfocus=self.dispman->getdata(/dispinfocus)
wid=dispinfocus->getdata(/wid)
focid=dispinfocus->getdata(/disp_id)
if keyword_set(ascii) then begin
   file=dialog_pickfile(/READ,$
                        DIALOG_PARENT=(self.xplot).xzoomplot_base,$
                        Path=self.prevPath,$
                        Get_Path=prevPath,$
                        Filter='*.*')
   if keyword_set(file) then begin
      readcol,file,wave,flux
      self.prevPath=prevPath
   endif
   ; create object
   analnew=obj_new('drip_anal_openfile',dispinfocus,self,wid)
   analnew->setdata,owave=wave,oflux=flux,file=file
endif
; find spot in list
; ( set analnext to index of first analobj with display id > focid )
; ( OR to analobjn if necessary place is last one
analnext=0
print,'analn=',self.analn
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
self.analn=self.analn+1
; add to display
;dispinfocus->openanal,analnew
; setallwid, update all, draw display
self->setwidopenfile
for anali=0, self.analn-1 do (*self.anals)[anali]->update

end


;****************************************************************************
;     SETALLWID - set widgets for all analysis objects (only where needed)
;****************************************************************************

pro  drip_analman_extract::setallwid

; deactivate update for upwid
widget_control, self.topwid, update=0
;** go through list of widgets: check, assign wigets (ev. create new ones)
; set variables
dispid=65 ; identifer of display of last analysis object
objcnt=0 ; count how many objects for this display
widn=size(*self.wids,/n_elements) ; number of widget entries
widi=1 ; index of next valid widget entry (get new widgets if > widn-1)
colwids=(*self.wids)[0]
;print,'SETALLWID: widn=',widn
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
            newwids={drip_anal_extract_wids}
            ; make new widgets
            newwids.label=widget_label(colwids.label,value='A-1', $
                                       font=largefont, ysize=25)
            newwids.show=widget_button(colwids.show, value=' ', ysize=25)
            newwids.top=widget_button(colwids.top, value=' ', ysize=25)
            newwids.plot=widget_button(colwids.plot, value='P', ysize=25)
            newwids.close=widget_button(colwids.close, value='Cls', ysize=25)
            newwids.color=cw_color_sel(colwids.color, [0b,0b,0b], $
                                       xsize=32, ysize=19)
            newwids.display=widget_button(colwids.display, value='Display')
            newwids.coordinates=widget_button(colwids.coordinates, value='Coordinates')
            ; append them to wids
            *self.wids=[*self.wids,newwids]
            ;print,'  Creating new widget label=',newwids.label
        endif
        ; check if still same display
        disp=(*self.anals)[anali]->getdata(/disp)
        newid=disp->getdata(/disp_id)
        ;print,'  newid=',newid
        if dispid ne newid then begin
            dispid=newid
            objcnt=1
        endif else objcnt=objcnt+1
        ; make title
        title=string(string(byte(dispid)),objcnt,format='(A,"-",I1)')
        ; pass widgets to object
        (*self.anals)[anali]->setwid, (*self.wids)[widi], title
        ; increase widi
        widi=widi+1
    endif
endfor
;** kill leftover widgets
;print,'  widget sets needed=',widi
if widi lt widn then begin
    ; kill widgets
    while widi lt widn do begin
        ;print,'  killing widget ',widn-1
        oldwids=(*self.wids)[widn-1]
        widget_control, oldwids.label, /destroy
        widget_control, oldwids.show, /destroy
        widget_control, oldwids.top, /destroy
        widget_control, oldwids.plot, /destroy
        widget_control, oldwids.close, /destroy
        widget_control, oldwids.color, /destroy
        widget_control, oldwids.display,/destroy
        widget_control, oldwids.coordinates, /destroy
        widn=widn-1
    end
    ; shorten wids
    *self.wids=(*self.wids)[0:widn-1]
endif
; activate update for upwid
widget_control, self.topwid, update=1

end



;****************************************************************************
;     SETALLWID - set widgets for all analysis objects (only where needed)
;****************************************************************************

pro  drip_analman_extract::setwidopenfile

; deactivate update for upwid
widget_control, self.topwid, update=0
;** go through list of widgets: check, assign wigets (ev. create new ones)
; set variables
dispid=65 ; identifer of display of last analysis object
objcnt=0 ; count how many objects for this display
widn=size(*self.wids,/n_elements) ; number of widget entries
widi=1 ; index of next valid widget entry (get new widgets if > widn-1)
colwids=(*self.wids)[0]
;print,'SETALLWID: widn=',widn
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
            newwids={drip_anal_extract_wids}
            ; make new widgets
            newwids.label=widget_label(colwids.label,value='File', $
                                       font=largefont, ysize=25)
            newwids.show=widget_button(colwids.show, value='X', ysize=25)
            newwids.top=widget_button(colwids.top, value=' ', ysize=25)
            widget_control,newwids.top, sensitive=0
            newwids.plot=widget_button(colwids.plot, value='P', ysize=25)
            newwids.close=widget_button(colwids.close, value='Cls', ysize=25)
            newwids.color=cw_color_sel(colwids.color, [0b,0b,0b], $
                                       xsize=32, ysize=19)
            ;widget_control,newwids.color,sensitive=0
            newwids.display=widget_button(colwids.display, value='Display')
            newwids.coordinates=widget_label(colwids.coordinates, $
                                              value='file',/Dynamic_resize)
            ; append them to wids
            *self.wids=[*self.wids,newwids]
            ;print,'  Creating new widget label=',newwids.label
        endif
        ; check if still same display
        ;disp=(*self.anals)[anali]->getdata(/disp)
        ;newid=disp->getdata(/disp_id)
        ;print,'  newid=',newid
        ;if dispid ne newid then begin
        ;    dispid=newid
        ;    objcnt=1
        ;endif else objcnt=objcnt+1
        ; make title
        ;title=string(string(byte(dispid)),objcnt,format='(A,"-",I1)')
        ; pass widgets to object
        title="File"
        (*self.anals)[anali]->setwid, (*self.wids)[widi], title
        ; increase widi
        widi=widi+1
    endif
endfor
;** kill leftover widgets
;print,'  widget sets needed=',widi
if widi lt widn then begin
    ; kill widgets
    while widi lt widn do begin
        ;print,'  killing widget ',widn-1
        oldwids=(*self.wids)[widn-1]
        widget_control, oldwids.label, /destroy
        widget_control, oldwids.show, /destroy
        widget_control, oldwids.top, /destroy
        widget_control, oldwids.plot, /destroy
        widget_control, oldwids.close, /destroy
        widget_control, oldwids.color, /destroy
        widget_control, oldwids.display,/destroy
        widget_control, oldwids.coordinates, /destroy
        widn=widn-1
    end
    ; shorten wids
    *self.wids=(*self.wids)[0:widn-1]
endif
; activate update for upwid
widget_control, self.topwid, update=1

end
;******************************************************************************
;     START - starts analysis object manager
;******************************************************************************

pro drip_analman_extract::start, dispman, xplot, extman

self.dispman=dispman
self.xplot=xplot
self.extman=extman

end

;****************************************************************************
;     INIT - Initializes the object
;****************************************************************************
function drip_analman_extract::init,baseid

;** set initial variables
self.type='extract'
self.analn=0
self.anals=ptr_new(/allocate_heap)
self.wids=ptr_new(/allocate_heap)

;** make widgets
common gui_os_dependent_values, largefont, smallfont
; header
self.topwid=widget_base(baseid, /column, /frame, $
                        event_pro='drip_anal_eventhand' )
headwid=widget_base(self.topwid,/row,/align_left)
title=widget_label(headwid, value='Extract:', font=largefont)

;new button
newbox=widget_button(headwid, value='New Box' ,$
                       uvalue={object:self, method:'openanal'} )
;open buttons
open=widget_button(headwid, value='Open',/menu)
openasc=widget_button(open, value='ASCII...',$
                      uvalue={object:self,$
                              method:'rwevent', uval:'open ascii'})
openfits=widget_button(open, value='FITS...',$
                      uvalue={object:self,$
                              method:'rwevent', uval:'open fits'})
;save buttons
save=widget_button(headwid, value='Save',/menu)
saveasc=widget_button(save, value='ASCII...',$
                      uvalue={object:self,$
                              method:'rwevent', uval:'save ascii'})
savefits=widget_button(save, value='FITS...',$
                      uvalue={object:self, $
                              method:'rwevent', uval:'save fits'})
saveps=widget_button(save, value='PostScript...',$
                      uvalue={object:self, $
                              method:'rwevent', uval:'save ps'})
;extract buttons
ext=widget_button(headwid,value='Extract',/menu)
ext2=widget_button(ext, value='Extract Selection', $
                          uvalue={object:self, method:'extract'})
g1xg2=widget_button(ext, value='G1xG2',$
                         uvalue={object:self, method:'multi_order'})
g3xg4=widget_button(ext, value='G3xG4',$
                         uvalue={object:self, method:'multi_order'})
;g5xg6=widget_button(ext, value='G5xG6',$
;                         uvalue={object:self, method:'multi_order'})
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
; plot
plot=widget_base(table, /column)
plotlabel=widget_label(plot, value='Plot')
; close
close=widget_base(table, /column)
closelabel=widget_label(close, value='Close')
; color
color=widget_base(table, /column)
colorlabel=widget_label(color, value='Color')
; display
display=widget_base(table, /column)
displaylabel=widget_label(display, value='Display')
; Coordinates
coordinates=widget_base(table, /column)
coordlabel=widget_label(coordinates, value='Coordinates')

;** create structure and fill in
widlist={drip_anal_extract_wids, label:label, show:show, top:top, $
         plot:plot, close:close, color:color, display:display, $
         coordinates:coordinates}
*self.wids=[widlist]

common gui_config_info, config
self.prevPath=getpar(config,'loadfitspath')


return,1
end


;****************************************************************************
;     DRIP_ANAL_EXTRACT__DEFINE
;****************************************************************************

pro drip_analman_extract__define

struct={drip_analman_extract, $
        ; overall widget ids
        new:0L, $                ; new widget button
        ext:0L, $                ; Extract button
        multi:0L,$               ; Multi-order Extract button
        open:0L,$                ; Open file button
        save:0L,$                ; save file button
        wids:ptr_new(), $        ; analysis object widgets
                        ; ( array of records, first entry is column widetID )
        dispman:obj_new(), $     ; reference to dispman
        xplot:obj_new(), $       ; reference to xplot
        xplot_multi:obj_new(),$  ; cross-dispersed multiple order mode
        extman:obj_new(), $      ; extraction dataman
        prevPath:'',$            ;previous location where saved
        inherits drip_analman}   ; child object of drip_analman
end
