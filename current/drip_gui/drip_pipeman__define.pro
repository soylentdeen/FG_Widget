; NAME:
;     DRIP_PIPEMAN - Version .7.0
;
; PURPOSE:
;     Pipeline manager for the GUI
;
; DEFINITIONS
;     PIPE = data reduction PIPEline
;            object for data reduction
;
; CALLING SEQUENCE:
;     Obj=Obj_new('DRIP_PIPEMAN',dataman)
;     Obj->START
;
; INPUTS:
;     DATAMAN - data manager to handle data to
;
; STRUCTURE:
;     {DRIP_DATAMAN, DISP_OBJS, FRAME_INDEX, STRUCTURE}
;     DISP_OBJS - DRIP_DISP object references (from cw_drip_disp widgets)
;     PIPE_STEPS - the dripipeline output structure (see DRIP__DEFINE::GETDATA)
;     PIPE_STEPS_SUM SUMSTRUCT - sum of previous drip outputs
;     DEC_OLD - old decomposition state (to restore it)
;     MW - message window object
;     N - counter used for averaging running sums
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;
; SIDE EFFECTS:
;     None
;
; RESTRICTIONS:
;     None
;
; PROCEDURE:
;     Contain data regarding current, open data reduction pipeline,
;     handle pipeline events.
;
; MODIFICATION HISTORY:
;     Written by: Marc Berthoud, Cornell University, July 2006
;     Modified: Marc Berthoud, Cornell University, September 2007
;               - Made responsible of its menu and drip buttons
;               - Added interaction with diplays (auto send reduced
;                 images)
;     Modified: Nirbhik Chitrakar, Cornell Univerisity, August 2006
;               - added saveflag for unsaved reduced data


;******************************************************************************
;     GETDATA - Returns the SELF structure elements
;******************************************************************************

function drip_pipeman::getdata, saveflag=sf

if keyword_set(sf) then return, self.saveflag

end
;******************************************************************************
;     RESET - Reset daps
;******************************************************************************

pro drip_pipeman::reset
; reset pipeline
obj_destroy, self.drip  ;new pipeline
*self.filelist=['']
self.n=0    ;clear var's
self.ind=0
self.mode=''
self.cnt=0
self.name=''
self.next=0

print,'PIPEMAN RESET'

end

;******************************************************************************
;     NEW - Initialize new pipe
;******************************************************************************
pro drip_pipeman::new, event
obj_destroy, self.drip  ;new pipeline
*self.filelist=['']
self.n=0    ;clear var's
self.ind=0
self.mode=''
self.cnt=0
end

;******************************************************************************
;     AUTO_OPEN - handle files picked automatically
;******************************************************************************

pro drip_pipeman::auto_open, filelist

if (filelist[0] ne '') then begin
    ; make new drip object with file list, initialize file list
    if self.n eq 0 then begin
        drip=drip_new(filelist) ;create drip object
        if drip ne obj_new() then begin
            self.drip=drip      ;store reference
            *self.filelist=filelist ;store filelist
            self.n=n_elements(filelist) ;store # files
            mode=drip->getdata(/mode) ;find pipeline mode and store
            self.mode=mode
        endif
    ; else (filelist exists) simply add to it
    endif else begin
        file=*self.filelist
        file=[file, filelist]
        *self.filelist=file
        self.n=n_elements(file)
    endelse
    ; print message
    if self.n gt 0 then begin
        sz=size(filelist, /n_elements)
        if sz gt 1 then self.mw->print, 'files ' + $
          file_basename(filelist[0]) + ' to ' + $
          file_basename(filelist[sz-1]) + ' added to filelist' else $
          self.mw->print, 'file ' + file_basename(filelist) + $
          ' added to filelist'
    endif else begin
        self.mw->print, 'ERROR: auto_open could not initialize pipe from ' + $
          file_basename(filelist[0])
    endelse
endif
end

;******************************************************************************
;     OPEN - pick files for reduction
;******************************************************************************

pro drip_pipeman::open, event

;let user choose file
filelist=dialog_pickfile(filter=*self.loadfilter, file=self.lastfile, $
      /fix_filter, /multiple_files, /must_exist, /read, get_path=path, $
      path=self.loaddatapath, dialog_parent=event.top)
if (filelist[0] ne '') then begin
    ; make new drip object with file list, initialize file list
    if self.n eq 0 then begin
        drip=drip_new(filelist) ;create drip object
        if drip ne obj_new() then begin
            self.drip=drip      ;store reference
            *self.filelist=filelist ;store filelist
            self.n=n_elements(filelist) ;store # files
            mode=drip->getdata(/mode) ;find pipeline mode and store
            self.mode=mode
        endif
    ; add files to existing file list
    endif else begin
        file=*self.filelist
        file=[file, filelist]
        *self.filelist=file
        self.n=n_elements(file)
    endelse
    ; print message
    if self.n gt 0 then begin
        sz=size(filelist, /n_elements)
        if sz gt 1 then self.mw->print, 'files ' + $
          file_basename(filelist[0]) + ' to ' + $
          file_basename(filelist[sz-1]) + ' added to filelist' $ 
        else self.mw->print, 'file ' + file_basename(filelist) + $
          ' added to filelist'
        print,self.n,self.ind,*self.filelist
    endif else begin
        msg='Error: open could not initialize pipe from ' + $
          file_basename(filelist[0])
        self.mw->print, msg
        s=dialog_message(msg)
    endelse
    ; store path and loadfilter
    self.loaddatapath=path ;store path
    self.lastfile=filelist[sz-1]
    if strmid(self.lastfile,strlen(self.lastfile)-5) eq '.fits' then $
      *self.loadfilter=['*.fits','*.fit','*.fts']
    if strmid(self.lastfile,strlen(self.lastfile)-4) eq '.fit' then $
      *self.loadfilter=['*.fit','*.fits','*.fts']
    if strmid(self.lastfile,strlen(self.lastfile)-4) eq '.fts' then $
      *self.loadfilter=['*.fts','*.fits','*.fit']
endif
end

;******************************************************************************
;     RUN - reduce data (takes care of all unreduced files in filelist)
;******************************************************************************

pro drip_pipeman::run, event
; print message if nothing to do
if (self.ind ge self.n) then begin
    self.mw->print, 'End of File List.  No more files to reduce.'
    return
endif
; reduce the unreduced files
repeat begin ;reduce, display, increment
    widget_control, /hourglass
    ; get filename from filelist (for messages)
    fileonly=file_basename((*self.filelist)[self.ind])
    ; reduce data -> get new pipe steps
    self.mw->print, 'reducing file ' + fileonly
    self.drip->run,(*self.filelist)[self.ind]
    self.mw->print, 'finished reducing file ' + fileonly
    self.ind=self.ind+1
    pipe_steps=self.drip->getdata()
    ; check if it's first reduced file ind==1
    if self.ind eq 1 then begin
        ; make new pipe name
        detector=strtrim(sxpar(pipe_steps.header,'DETECTOR'),2)
        self.name='FC_'+self.mode+'_'+detector+'_'+ $
          strtrim(string(self.next),2)
        ; copy data to dataman
        self.dataman->setdap,self.name,pipe_steps
        ; make sum copy in dataman
        sum_name=self.name+'_sum'
        self.dataman->setdap,sum_name,pipe_steps
        ; update counter for next pipeline and number of reduced files
        self.next=self.next+1
        self.cnt=1
    endif else begin
    ; add data to existing sum
        ; copy data to dataman
        self.dataman->setdap,self.name,pipe_steps
        ; get sum dap
        sum_name=self.name+'_sum'
        sum_dap=self.dataman->getdap(sum_name)
        ; check if it's valid, else make a new sum dap
        if ptr_valid(pipe_sum_dap) eq 0 then begin
            self.dataman->setdap,sum_name,pipe_steps
            self.cnt=1
        endif else begin
            ntags=n_tags(pipe_steps)
            for i=0,ntags-1 do begin
                if size(pipe_steps.(i),/n_dimensions) gt 1 then $
                  (*sum_dap).(i)=(*sum_dap).(i)+pipe_steps.(i)
            endfor
            self.cnt=self.cnt+1
        endelse
    endelse
    ; set displays if required
    dispn=size(*self.disp_sels,/n_elements)
    for dispi=0,dispn-1 do begin
        if (*self.dispnewpipe)[dispi] ne 'None' then $
          (*self.disp_sels)[dispi]->newdap, $
          dapnew=self.name, elemnew=(*self.dispnewpipe)[dispi]
    endfor
    ; update channels
    self.dataman->channelcall
    ; new reduced data so set flag to 0
    self.saveflag=0
endrep until (self.ind ge self.n)
end

;******************************************************************************
;     STEPBACK - undo last reduction (only works once)
;******************************************************************************

pro drip_pipeman::stepback, event
if self.cnt gt 0 then begin
    ; step back in drip
    self.drip->stepback
    ; subtract old data from current sum
    pipe_dap=self.dataman->getdap(self.name)
    sum_dap=self.dataman->getdap(self.name+'_sum')
    if (ptr_valid(pipe_dap) gt 0) and (ptr_valid(sum_dap) gt 0) then begin
        ntags=n_tags(*pipe_dap)
        for i=0,ntags-1 do begin
            if size((*pipe_dap).(i),/n_dimensions) gt 1 then $
              (*sum_dap).(i)=(*sum_dap).(i)-(*pipe_dap).(i)
        endfor
        self.cnt=self.cnt-1
    endif
    ; set stepped back data
    pipe_steps=self.drip->getdata()
    self.dataman->setdap,self.name,pipe_steps
    self.dataman->channelcall
endif
end

;******************************************************************************
;     SAVE - save result from current drip (uses drip::save)
;******************************************************************************

pro drip_pipeman::save, event
if (self.ind gt 0) then begin
    ; make default filename
    filename=(*self.filelist)[self.ind-1]
    namepos=strpos(filename,'.fit',/reverse_search)
    filename=strmid(filename,0,namepos)+'_reduced.fits'
    ; querry user for filename
    filename=dialog_pickfile(file=filename, /fix_filter, /write, $
                             filter=['*.fits','*.fit','*.fts'], $
                             get_path=path, path=self.savepath)
    ; save file
    if filename ne '' then begin
        self.savepath=path
        self.drip->save, filename=filename
        self.mw->print, 'saved reduced image.'
        self.saveflag=1
    endif
endif else self.mw->print,'No new reduced files to save'
end

;******************************************************************************
;     DRIPCONF_EDIT - edit pipeline configuration
;******************************************************************************

pro drip_pipeman::dripconf_edit, event
common drip_config_info, dripconf
edit_string_list, dripconf, $
  comment='Edit Drip Configuration:'
end

;******************************************************************************
;     DISPCONF - configure pipeline -> display behaviour
;******************************************************************************

pro drip_pipeman::dispconf, event
dispn=size(*self.disp_sels,/n_elements)
framelist=['None','Data','Cleaned','Badflags','Flatted','Stacked', $
           'Undistorted','Merged','Coadded','Coadded_rot','Badmap','Masterflat']
framen=size(framelist,/n_elements)
common gui_os_dependent_values, largefont, smallfont
case event.id of
    ; Menu: make popup window
    (*self.dispconfstat).menu:begin
        if ((*self.dispconfstat).stat eq 0) and (dispn gt 0) then begin
            ; setup list
            ; set selection indices
            for dispi=0, dispn-1 do begin
                ind=where(framelist eq (*self.dispnewpipe)[dispi])
                if ind gt -1 then (*self.dispconfstat).dispsel[dispi]=ind $
                else (*self.dispconfstat).dispsel[dispi]=0
            endfor
            ; make widgets
            top=widget_base(/column)
            label=widget_label(top,font=largefont,value='Display Options:')
            info0=widget_label(top,value='Pipeline steps set below will be')
            info1=widget_label(top,value='automatically displayed whenever')
            info2=widget_label(top,value='new data is reduced')
            ; selection widgets
            for dispi=0, dispn-1 do begin
                title='Display '+string(byte('A')+byte(dispi))
                (*self.dispconfstat).dispdrop[dispi]=widget_droplist(top, $
                     value=framelist, event_pro='drip_eventhand', $
                     uvalue={object:self, method:'dispconf'}, $
                     title=title )
            endfor
            ; buttons
            row=widget_base(top,/row)
            (*self.dispconfstat).done=widget_button(row, value='Done', $
              event_pro='drip_eventhand', $
              uvalue={object:self, method:'dispconf'} )
            (*self.dispconfstat).chancel=widget_button(row, value='Chancel', $
              event_pro='drip_eventhand', $
              uvalue={object:self, method:'dispconf'} )
            ; set status
            (*self.dispconfstat).stat=1
            ; realize and start widgets
            widget_control, top, /realize
            for dispi=0, dispn-1 do $
              widget_control, (*self.dispconfstat).dispdrop[dispi], $
              set_droplist_select=(*self.dispconfstat).dispsel[dispi]
            xmanager, 'Configure Pipeline->Displays', top
            ;print,(*self.dispconfstat).dispsel
        endif
        break
    end
    ; Done: close window and save settings
    (*self.dispconfstat).done:begin
        if (*self.dispconfstat).stat ne 0 then begin
            ; change settings
            for dispi=0, dispn-1 do begin
                ind=(*self.dispconfstat).dispsel[dispi]
                (*self.dispnewpipe)[dispi]=framelist[ind]
            endfor
            ; close window, reset status
            widget_control, event.top, /destroy
            (*self.dispconfstat).stat=0
        endif
        break
    end
    ; Chancel: close window
    (*self.dispconfstat).chancel:begin
        if (*self.dispconfstat).stat ne 0 then begin
            widget_control, event.top, /destroy
            (*self.dispconfstat).stat=0
        endif
        break
    end
    else:begin ; look through drop down list
        ind=where((*self.dispconfstat).dispdrop eq event.id)
        if ind gt -1 then $
          (*self.dispconfstat).dispsel[ind]=event.index
    endelse
endcase
end

;******************************************************************************
;     VIEWHEAD - Show Fits Header of Current Pipe
;******************************************************************************
pro drip_pipeman::viewhead, event
if self.cnt gt 0 then begin
    widget_control, event.id, get_value=value
    pipe_dap=self.dataman->getdap(self.name)
    if strpos(value,'Base') gt -1 then $
      head=(*pipe_dap).basehead else head=(*pipe_dap).header
    edit_param_list, head, $
      comment='WARNING: this window is not updated as new images are loaded', $
      /viewonly
endif else begin
    self.mw->print, $
      'PipeMan::ViewHead - no header available, current pipe has no data'
endelse
end

;******************************************************************************
;     START - Makes widgets
;             Parameters: requires menu bar and on-screen base widget id
;******************************************************************************

pro drip_pipeman::start, mbar, ctrlbase1, disp_sels=disp_sels
;** make interactive widgets
; get fonts
COMMON gui_os_dependent_values, largefont, smallfont
common gui_config_info, guiconf
; pipeline menu options
pipe_menu=widget_button(mbar, value='PipeLine', /menu)
new=widget_button(pipe_menu, value='New Pipe', event_pro='drip_eventhand', $
      uvalue={object:self, method:'new'}, /separator )
open=widget_button(pipe_menu, value='Open Forcast File(s) ...', $
      event_pro='drip_eventhand', uvalue={object:self, method:'open'})
reduce=widget_button(pipe_menu, value='Reduce', event_pro='drip_eventhand', $
      uvalue={object:self, method:'run'})
back=widget_button(pipe_menu, value='Step Back', event_pro='drip_eventhand', $
      uvalue={object:self, method:'stepback'})
save=widget_button(pipe_menu, value='Save...', event_pro='drip_eventhand', $
      uvalue={object:self, method:'save'} )
keywordrep=widget_button(pipe_menu, value='Edit Drip Config...', $
      event_pro='drip_eventhand', $
      uvalue={object:self, method:'dripconf_edit'}, $
      /separator )
viewhead=widget_button(pipe_menu, value='View FITS header...', /menu)
viewhead_sub=widget_button(viewhead, value='Base Header', $
      event_pro='drip_eventhand', uvalue={object:self, method:'viewhead'} )
viewhead_sub=widget_button(viewhead, value='Last Header', $
      event_pro='drip_eventhand', uvalue={object:self, method:'viewhead'} )
dispconfid=widget_button(pipe_menu, value='Pipe -> Display Config', $
      event_pro='drip_eventhand', uvalue={object:self, method:'dispconf'} )
; on-screen pipeline control
lab=widget_label(ctrlbase1, value=" Pipeline Control : ", /frame, $
      font=largefont)
new=widget_button(ctrlbase1, value='New Pipe', event_pro='drip_eventhand', $
      uvalue={object:self, method:'new'}, /sensitive, $
      font=largefont, ysize=30)
open=widget_button(ctrlbase1, value='Open File(s)', $
      event_pro='drip_eventhand', $
      uvalue={object:self, method:'open'}, /sensitive, $
      font=largefont, ysize=30)
reduce=widget_button(ctrlbase1, value='Reduce', event_pro='drip_eventhand', $
      uvalue={object:self, method:'run'}, /sensitive, $
      font=largefont, ysize=30)
;** get displays information - setup display configuration status
if keyword_set(disp_sels) then begin
    ; get displays
    *self.disp_sels=disp_sels
    dispn=size(disp_sels,/n_elements)
    ; set dispnewpipe / load from guiconfig
    *self.dispnewpipe=strarr(dispn)
    for dispi=0, dispn-1 do begin
        paramname='disp_pipe_pref_'+strtrim(string(dispi),2)
        pref=getpar(guiconf,paramname)
        if size(pref,/type) eq 7 then (*self.dispnewpipe)[dispi]=pref $
        else (*self.dispnewpipe)[dispi]='None'
    endfor
    ; make display configuration status
    *self.dispconfstat={stat:0, dispdrop:lonarr(dispn), dispsel:intarr(dispn),$
                        menu:dispconfid, done:0L, chancel:0L}
endif else begin
    ; no displays available - set status to 0
    *self.dispconfstat={stat:0, menu:dispconfid}
endelse
; make / set disp_setup_stat
end

;******************************************************************************
;     CLEANUP
;******************************************************************************

pro drip_pipeman::cleanup
;** save configuration info
common gui_config_info, guiconf
; Save Paths
setpar,guiconf,'loaddatapath',self.loaddatapath
setpar,guiconf,'savepath',self.savepath
; save dispnewpipe steps
dispn=size(*self.dispnewpipe,/n_elements)
for dispi=0,dispn-1 do begin
    paramname='disp_pipe_pref_'+strtrim(string(dispi),2)
    setpar,guiconf,paramname,(*self.dispnewpipe)[dispi]
endfor
;** free pointers
ptr_free, self.disp_sels
ptr_free, self.filelist
ptr_free, self.loadfilter
ptr_free, self.dispnewpipe
ptr_free, self.dispconfstat
if obj_valid(self.drip) then obj_destroy, self.drip
end

;******************************************************************************
;     INIT
;******************************************************************************

function drip_pipeman::init, dataman, mw
; assign objects
self.dataman=dataman
self.mw=mw
self.disp_sels=ptr_new(/allocate_heap)
; reset file list
self.filelist=ptr_new(/allocate_heap)
*self.filelist=['']
; set load filter
self.loadfilter=ptr_new(/allocate_heap)
*self.loadfilter=['*.fits','*.fit','*.fts']
; get loaddatapath and savepath (check if entry is valid and path exists)
common gui_config_info, guiconf
loaddatapath=getpar(guiconf,'loaddatapath')
if size(loaddatapath,/type) ne 7 then self.loaddatapath='.' else begin
    if file_test(loaddatapath) gt 0 then $
      self.loaddatapath=loaddatapath else self.loaddatapath='.'
endelse
savepath=getpar(guiconf,'savepath')
if size(savepath,/type) ne 7 then self.savepath='.' else begin
    if file_test(savepath) gt 0 then $
      self.savepath=savepath else self.savepath='.'
endelse
; get dispnewpipe memory
self.dispnewpipe=ptr_new(/allocate_heap)
; get display setup popup status memory
self.dispconfstat=ptr_new(/allocate_heap)
return, 1
end

;******************************************************************************
;     DRIP_PIPEMAN__DEFINE
;******************************************************************************

pro drip_pipeman__define

struct={drip_pipeman, $
        ; other objects
        mw:obj_new(), $       ; message window object
        dataman:obj_new(), $  ; data manager
        disp_sels:ptr_new(), $; array of display anal select objects
        ; loading and saving information
        loaddatapath:'', $    ; loading directory for forcast data
        loadfilter:ptr_new(),$; filters for loading images
        lastfile:'',$         ; last data file loaded
        savepath:'', $        ; saving directory
        saveflag:0,$          ; flag to check if a reduced data is saved
        ; pipe variables: data reduction
        drip:obj_new(), $     ; data reduction pipe object
        mode:'', $            ; instrument mode of the current pipeline
        ; files to process
        n:0, $                ; the number of entries in filelist
        ind:0, $              ; the index of next file to reduce in filelist
        filelist:ptr_new(), $ ; file list for current pipe
                              ; (all files: reduced and non-reduced)
        ; reduced pipeline data
        cnt:0, $              ; number of summed files for current pipe
                              ; (can be !=ind b/c of stepback)
        name:'', $            ; name of current pipe dap
        next:0, $             ; number of next pipe
        ; pipeline displays interaction
        dispnewpipe:ptr_new(),$; string array with name of new pipestep
                               ; to be displayed for each display
                               ; 'none' for not requested
        dispconfstat:ptr_new() } ; record variable with  status of
                               ; popup window with display configuration
end