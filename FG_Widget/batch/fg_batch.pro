pro fg_batch,file_list

; Reduces and saves a list of FORCAST raw data files

; Send data to DRIP for reduction and save reduced files 

for i=0,n_elements(file_list)-1 do begin

    redux=drip_new(file_list[i])

    ; Run the pipeline

    redux->run, file_list[i]

    ; Save reduced data

    redux-> save

    ; Destroy the object

    obj_destroy, redux

endfor

print,'DRIP FINISHED'


end
