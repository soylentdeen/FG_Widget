; NAME:
;     DRIP_AUTOMAN - Version 1.7.0
;
; PURPOSE:
;     Auto reduction manager for DRiP GUI
;
; CALLING SEQUENCE / INPUTS / OUTPUTS: NA
;
; CALLED ROUTINES AND OBJECTS:
;     CW_DRIP_MW: Used to send messages to the user
;     DRIP_PIPEMAN: AUTOMAN sends PIPEMAN files to open and commands
;                   it to run the reduction
;
; PROCEDURE:
;     AUTOMAN requires a text file that lists the file names of recently
;     stored data files (the listfile). If auto reduction is on, that
;     file is read every 5 seconds. New entries in the listfile are
;     compared to a list stored by AUTOMAN. New files are sent to
;     PIPEMAN and reduced (PIPEMAN::RUN). The filename entry in
;     listfile is altered according to pathskip and pathadd to
;     acomodate different paths on the FORAK and the data reduction
;     computer. If the new datafile has different keywords than the
;     previous one (as specified in resetvars) a new pipeline is set
;     up and all following files are reduced using the new pipeline.
;
; RESTRICTIONS:
;     Scanning doesn't work well in windows....
;
; MODIFICATION HISTORY:
;     Written by:  Alfred Lee, Cornell University, February, 2003
;     Modified:   Alfred Lee, Cornell University, April 14, 2003
;                 Finished a working reset method.
;     Modified:   Marc Berthoud, Cornell University, July 18. 2003
;                 drip_auto::scan: replaced searchmethod for end of file
;     Modified:   Marc Berthoud, Palomar, June 23. 2005
;                 Re-read listfile fully every time and compare to filelist
;                 Have ability to alter directory from listfile entry
;     Modified:   Marc Berthoud, Cornell University, October 2007
;                 Introduced Pipe Reset Keywords
;                 Changed handling of listfile (new function listopen)
;                 Added configuration window
;

;******************************************************************************
;     RESET - reset variables and state
;******************************************************************************

pro drip_automan::reset
if self.on then begin
    self->check
    widget_control, self.automenu, sensitive=0
    widget_control, self.checkid, sensitive=0
endif
*self.filelist=['']
end

;******************************************************************************
;     SCAN - upon timer event, scan file for new files to reduce
;******************************************************************************

pro drip_automan::scan, event
if self.on then begin
    ; set checkbox unsensitive
    widget_control, self.checkid, sensitive=0
    wait, 0.2
    datafile=''
    run=0b
    ; open file
    openr, lun, self.listfile, /get_lun
    while not eof(lun) do begin
        ; read file
        readf, lun, datafile
        ; check if valid file: alter path and search -> insert if not found
        if datafile ne '' then begin
            ; skip and add path
            pos=strpos(datafile,self.pathskip)+strlen(self.pathskip)
            dataf=strmid(datafile,pos)
            datafile=self.pathadd+dataf
            print,'checking file=',datafile
            ; check if datafile is already in filelist
            if not max(*self.filelist eq datafile) then begin
                ;** if not
                ; get file header
                fits_read, datafile, null, newhead, /header
                ; get resetarr, resetn
                resetarr=strsplit(self.resetvars,'/',/extract)
                resetn=size(resetarr,/N_elements)
                ; compare file header with basehead
                ; (to determine if new pipe has to be run)
                changehead=0
                for reseti=0,resetn-1 do begin
                    ; print,' comparing keyword ',resetarr[reseti], $
                    ;   ' newhead=',sxpar(newhead,resetarr[reseti]), $
                    ;   ' basehead=',sxpar(*self.basehead,resetarr[reseti])
                    if string(sxpar(newhead,resetarr[reseti])) ne $
                       string(sxpar(*self.basehead,resetarr[reseti])) then $
                      changehead=1
                endfor
                ; check if new pipe is required
                if changehead then begin
                    ; reduce old pipe
                    if run then self.pipeman->run
                    ; save old pipe
                    ; --- insert commands here ---
                    ; make new pipe
                    self.pipeman->new
                    ; set self.basehead
                    *self.basehead=newhead
                endif
                ; add to file list
                *self.filelist=[*self.filelist,datafile]
                ; run file
                run=1b
                self.pipeman->auto_open, datafile
            endif
        endif
    endwhile
    close, lun
    free_lun, lun
    ; if new files available, run pipeman
    if run then self.pipeman->run
    ; set timer widget and checkbox as sensitive
    widget_control, self.timerwid, timer=5
    widget_control, self.checkid, /sensitive
endif
end

;******************************************************************************
;     AUTOCONF - event function for auto configuration dialog window
;******************************************************************************

pro drip_automan::autoconf, event
common gui_os_dependent_values, largefont, smallfont
case event.id of
    ; Menu: make popup window
    (*self.autoconfstat).menu:begin
        if (*self.autoconfstat).stat eq 0 then begin
            ; make widgets
            top=widget_base(/column,/base_align_left)
            label=widget_label(top,font=largefont,value='Auto Options:')
            ; listfile
            base=widget_base(top,/row)
            (*self.autoconfstat).listfileid=cw_field(base,title='List File:', $
                value=self.listfile, xsize=40, /string )
            (*self.autoconfstat).listfilebutton=widget_button(base, $
                value='Select File . .', event_pro='drip_eventhand', $
                uvalue={object:self, method:'autoconf'} )
            info=widget_label(top,value= $
               '  ( Name of file with new data List )')
            ; pathskip and pathadd
            (*self.autoconfstat).pathskipid=cw_field(top,title='PathSkip :', $
                value=self.pathskip, xsize=40, /string )
            (*self.autoconfstat).pathaddid=cw_field(top,title='PathAdd  :', $
                value=self.pathadd, xsize=40)
            info=widget_label(top,value= $
               '  ( File entries in ListFile will be changed from')
            info=widget_label(top,value= $
               '    PathSkipFileName to PathAddFileName before loading )')
            ; reset vars
            (*self.autoconfstat).resetvarsid=cw_field(top,title='ResetVars:', $
                value=self.resetvars, xsize=40, /string )
            info=widget_label(top,value= $
               '  ( List of FITS keywords to be checked to reset pipeline')
            info=widget_label(top,value= $
               '    format: keyword1/keyword2/keyword3/keyword4 )')
            ; buttons
            row=widget_base(top,/row)
            (*self.autoconfstat).done=widget_button(row, value='Done', $
              event_pro='drip_eventhand', $
              uvalue={object:self, method:'autoconf'} )
            (*self.autoconfstat).chancel=widget_button(row, value='Cancel', $
              event_pro='drip_eventhand', $
              uvalue={object:self, method:'autoconf'} )
            ; set status
            (*self.autoconfstat).stat=1
            ; realize and start widgets
            widget_control, top, /realize
            xmanager, 'Configure Pipeline->Displays', top
            ;print,(*self.autoconfstat).dispsel
        endif
        break
    end
    ; ListFileButton: open file selection dialog
    (*self.autoconfstat).listfilebutton:begin
        if (*self.autoconfstat).stat ne 0 then begin
            ; get listfile
            listfile=''
            widget_control,(*self.autoconfstat).listfileid,get_value=listfile
            path=file_dirname(listfile)
            ; change get new file name
            listfile=dialog_pickfile(filter='*', /must_exist, $
               path=path, dialog_parent=event.top, file=listfile, $
               title='Select List File:' )
            ; set new file name
            if strlen(listfile) gt 0 then $
              widget_control,(*self.autoconfstat).listfileid,set_value=listfile
        endif
        break
    end
    ; Done: close window and save settings
    (*self.autoconfstat).done:begin
        if (*self.autoconfstat).stat ne 0 then begin
            ; change settings
            string=''
            widget_control,(*self.autoconfstat).listfileid, $
              get_value=string
            self.listfile=string
            self->listopen
            widget_control,(*self.autoconfstat).pathskipid, $
              get_value=string
            self.pathskip=string
            widget_control,(*self.autoconfstat).pathaddid, $
              get_value=string
            self.pathadd=string
            widget_control,(*self.autoconfstat).resetvarsid, $
              get_value=string
            self.resetvars=string
            ; close window, reset status
            widget_control, event.top, /destroy
            (*self.autoconfstat).stat=0
        endif
        break
    end
    ; Cancel: close window, reset status
    (*self.autoconfstat).chancel:begin
        if (*self.autoconfstat).stat ne 0 then begin
            widget_control, event.top, /destroy
            (*self.autoconfstat).stat=0
        endif
        break
    end
endcase
end

;******************************************************************************
;     TOOGLE - toogle (activate / deactivate) auto reduce
;******************************************************************************

pro drip_automan::toogle, event
; toggle on
self.on=1-self.on
; set checker
widget_control, self.checkid, set_button=self.on
if self.on then begin
    ; set widgets
    widget_control, self.automenu, set_value='Stop Auto Reduce'
    widget_control, self.timerwid, timer=1
    self.mw->print,'drip_automan: going ON'
endif else widget_control, self.automenu, set_value='Start Auto Reduce'

end

;******************************************************************************
;     LISTOPEN - check and open listfile (set controls)
;******************************************************************************
pro drip_automan::listopen
; open file and check
err=0
openr, lun, self.listfile, /get_lun, error=err
if err eq 0 then begin
    ; get file list from list file
    datafile=''
    *self.filelist=['']
    while not eof(lun) do begin
        readf, lun, datafile
        ; if valid file: alter path and add to list
        if datafile ne '' then begin
            pos=strpos(datafile,self.pathskip)+strlen(self.pathskip)
            dataf=strmid(datafile,pos)
            datafile=self.pathadd+dataf
            *self.filelist=[*self.filelist,datafile]
        endif
    endwhile
    close, lun
    free_lun, lun
    self.mw->print,'drip_automan: latest file '+self.listfile
    self.mw->print,' opened with '+ $
      string(size(*self.filelist,/n_elements)-1)+ $
      ' files'
    ; activate start widgets
    widget_control, self.automenu, /sensitive
    widget_control, self.checkid, /sensitive
endif else begin
    self.mw->print,'drip_automan: WARNING: Could not open'
    self.mw->print,'     listfile='+self.listfile
    ; deactivate start widgets
    widget_control, self.automenu, sensitive=0
    widget_control, self.checkid, sensitive=0
    ; empty file list
    *self.filelist=['']
endelse
end

;******************************************************************************
;     START - Make widgets and menu items
;******************************************************************************

pro drip_automan::start, mbar, ctrlbase1
; get fonts
COMMON gui_os_dependent_values, largefont, smallfont
; auto menu options
auto_menu=widget_button(mbar, value='Auto', /menu)
self.automenu=widget_button(auto_menu, value='Start Auto Reduce', $
     event_pro='drip_eventhand', uvalue={object:self, method:'toogle'}, $
     sensitive=0)
autoconf=widget_button(auto_menu, value='Auto Config', $
                       event_pro='drip_eventhand', $
                       uvalue={object:self, method:'autoconf'})
; on-screen auto control
autobase=widget_base(ctrlbase1, /row, /nonexclusive, $
      event_pro='drip_eventhand', uvalue={object:self, method:'scan'})
self.checkid=widget_button(autobase, value='Auto-Reduce', event_pro= $
        'drip_eventhand', uvalue={object:self, method:'toogle'}, $
        font=mediumfont, sensitive=0, ysize=20)
; use autobase as the timer widget
self.timerwid=autobase
; set auto configuration status
*self.autoconfstat={stat:0, listfileid:0L, listfilebutton:0L, $
                    pathskipid:0L, pathaddid:0L, resetvarsid:0L, $
                    menu:autoconf, done:0L, chancel:0L}
; check and open listfile
self->listopen
end

;******************************************************************************
;     CLEANUP - Save settings and free memory
;******************************************************************************

pro drip_automan::cleanup
; save configuration
common gui_config_info, guiconf
setpar,guiconf,'auto_listfile',self.listfile
setpar,guiconf,'auto_pathskip',self.pathskip
setpar,guiconf,'auto_pathadd',self.pathadd
setpar,guiconf,'auto_resetvars',self.resetvars
; free memory
ptr_free, self.filelist
ptr_free, self.basehead
ptr_free, self.autoconfstat
end

;******************************************************************************
;     INIT - Initialize structure
;******************************************************************************

function drip_automan::init, mw, pipeman
self.filelist=ptr_new(/allocate_heap)
*self.filelist=['']
self.basehead=ptr_new(/allocate_heap)
*self.basehead=['']
self.mw=mw
self.pipeman=pipeman
; get settings from stored configuration
common gui_config_info, guiconf
self.listfile=getpar(guiconf,'auto_listfile')
if size(self.listfile,/type) ne 7 then self.listfile=''
self.pathskip=getpar(guiconf,'auto_pathskip')
if size(self.pathskip,/type) ne 7 then self.pathskip=''
self.pathadd=getpar(guiconf,'auto_pathadd')
if size(self.pathadd,/type) ne 7 then self.pathadd=''
self.resetvars=getpar(guiconf,'auto_resetvars')
if size(self.resetvars,/type) ne 7 then self.resetvars=''
; get automan configuration status window memory
self.autoconfstat=ptr_new(/allocate_heap)
return, 1
end

;******************************************************************************
;     DRIP_AUTOMAN__DEFINE
;******************************************************************************

pro drip_automan__define

struct={drip_automan, $
        ; admin
        on:0b, $              ; flag for on/off
        ; files info
        listfile:'', $        ; name of list file (with path)
        pathskip:'', $        ; part of file name at start to skip
        pathadd:'', $         ; part of file name at start to add
        resetvars:'', $       ; header variables who's change will reset the
                              ; pipeline format: names with '/' as separator
        basehead:ptr_new(), $ ; header of first file of current pipeline
                              ; size(basehead,/n_elements) lt 2 indicates
                              ; that no files have been found/opened yet
        filelist:ptr_new(), $ ; list for files
        ; widget ids
        checkid:0L, $         ; checkbox widget id
        automenu:0L, $        ; auto menu item id
        timerwid:0L, $        ; widget id of timer event handler widget
        ; configuration window
        autoconfstat:ptr_new(), $; record variable with status of
                              ; dialog window with auto configuration
        ; other objects
        pipeman:obj_new(), $  ; pipeline manager
        mw:obj_new()}         ; message window object
end
