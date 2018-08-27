clc;
clear;
text=fileread('mem232.txt');

s=size(text);
j=1;
i=1;
while(i<=s(2)) 
  if(text(i)=='W')
    data(j)=(hex2dec(text((i+1):(i+8))));
    i=i+9;
    j=j+1;
  end
  if(text(i)=='A') 
    new_address=text((i+1):(i+3));
    i=i+5;
    address(j)=hex2dec(new_address);
  else
    address(j)=address(j-1)+1;
  end
  i=i+1;
end


ser=serial('COM3','Baudrate',115200);
fopen(ser);
fwrite(ser,85); %send hex55 start condition.
fclose(ser);

    ser=serial('COM3','Baudrate',115200);
    fopen(ser);

s2=size(data);
for i=1:s2(2)
   
    fwrite(ser, bitshift(bitand(address(i),hex2dec('FF00')),-8));
    fwrite(ser, bitand(address(i),hex2dec('00FF')));
  
    fwrite(ser, bitshift(bitand(data(i),hex2dec('FF000000')), -24));
    fwrite(ser, bitshift(bitand(data(i),hex2dec('00FF0000')), -16));
    fwrite(ser, bitshift(bitand(data(i),hex2dec('0000FF00')), -8));
    fwrite(ser, bitand(data(i),hex2dec('000000FF')));


end
   fclose(ser);
    
ser=serial('COM3','Baudrate',115200);
fopen(ser);
fwrite(ser,255); %send escape command hexFFFF
fwrite(ser,255);
fclose(ser);




