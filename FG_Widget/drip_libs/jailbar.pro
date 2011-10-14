function jailbar,data

; subtract median of every 16th column from image

s=size(data)
median_col=fltarr(256,256)
temp_data=fltarr(16)
for i=0,255 do begin   ; change to i=0,240 for horizontal median
  for j=0,255 do begin
    ;for k=0,15 do begin
    ;  temp_data[k]=data[i+k,j]
    ;endfor
    median_col[i,j]=median(data[i,*]);  was median(temp_data)
  endfor
endfor
return,median_col
end
