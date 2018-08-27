ser=serial('COM3','Baudrate',115200);
N=120;
fopen(ser);
fwrite(ser,85);

fwrite(ser,0);
fwrite(ser,0);

fwrite(ser,0);
fwrite(ser,N);

temp=fread(ser,N*4);
fclose(ser);


temp2=dec2hex(bitshift(temp(1:4:(N*4-3)), 24)+bitshift(temp(2:4:(N*4-2)), 16)+bitshift(temp(3:4:(N*4-1)), 8)+temp(4:4:N*4),8)
