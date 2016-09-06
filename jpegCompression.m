function [ Ioutput ] = jpegCompression( Iinput, quality )
%-----------------------------------------------------------
% RGB- YCBCR CONVERSION
%-----------------------------------------------------------
I=rgb2ycbcr(Iinput);
Y=I(:,:,1);
cb=I(:,:,2);
cr=I(:,:,3);

[a,b]=size(cb);
%-----------------------------------------------------------
% Quantization Tables
%-----------------------------------------------------------
Qluminance=[16 11 10 16 24 40 51 61;
   12 12 14 19 26 58 60 55;
   14 13 16 24 40 57 69 56;
   14 17 22 29 51 87 80 62;
   18 22 37 56 68 109 103 77;
   24 35 55 64 81 104 113 92;
   49 64 78 87 103 121 120 101;
   72 92 95 98 112 100 103 99];

Qchrominance=[17 18 24 47 99 99 99 99;
   18 21 26 66 99 99 99 99;
   24 26 56 99 99 99 99 99;
   47 99 99 99 99 99 99 99;
   99 99 99 99 99 99 99 99;
   99 99 99 99 99 99 99 99;
   99 99 99 99 99 99 99 99;
   99 99 99 99 99 99 99 99];
%-----------------------------------------------------------
% Scale
%-----------------------------------------------------------
qf=quality;
if qf>95
    qscale=1;

elseif qf < 50
qscale = floor(5000 / qf ) ;
else
qscale = 200 - 2 * qf ;
end
Qluminance = (Qluminance*(qscale/100));
Qchrominance=(Qchrominance*(qscale/100));
%-----------------------------------------------------------
% Applying Discrete Cosine Transform
%-----------------------------------------------------------
fun = @(block_struct) dct2(block_struct.data);
Y_dct=blockproc(Y,[8 8],fun);
CB_dct=blockproc(cb,[8 8],fun);
CR_dct=blockproc(cr,[8 8],fun);
%-----------------------------------------------------------
% Quantization of the DCT coefficients
%-----------------------------------------------------------
quantY = @(block_struct) round( block_struct.data./Qluminance);
quantCB = @(block_struct) round( block_struct.data./Qchrominance);

quantizedY=blockproc(Y_dct,[8 8],quantY);
quantizedCB=blockproc(CB_dct,[8 8],quantCB);
quantizedCR=blockproc(CR_dct,[8 8],quantCB);
%-----------------------------------------------------------
% ZigZag Scanning
%----------------------------------------------------------- 
zigzagedY=zigzag(quantizedY);
zigzagedCB=zigzag(quantizedCB);
zigzagedCR=zigzag(quantizedCR);
%-----------------------------------------------------------
% Zero-Run-Length Encoding
%-----------------------------------------------------------
[dY,cY]=runenc(zigzagedY');
[dB,cB]=runenc(zigzagedCB');
[dR,cR]=runenc(zigzagedCR');
%-----------------------------------------------------------
% Zero-Run-Length Decoding
%-----------------------------------------------------------
resultY=rl_dec(dY,cY);
resultCB=rl_dec(dB,cB);
resultCR=rl_dec(dR,cR);
%-----------------------------------------------------------
% InvZigZag Scanning
%-----------------------------------------------------------
invzigzagedY=invzigzag(resultY,a,b);
invzigzagedCB=invzigzag(resultCB,a,b);
invzigzagedCR=invzigzag(resultCR,a,b);
%-----------------------------------------------------------
% dequantization
%-----------------------------------------------------------
dequantY = @(block_struct) block_struct.data.*Qluminance;
dequantCB = @(block_struct) block_struct.data.*Qchrominance;

iquantizedY=blockproc(invzigzagedY,[8 8],dequantY);
iquantizedCB=blockproc(invzigzagedCB,[8 8],dequantCB);
iquantizedCR=blockproc(invzigzagedCR,[8 8],dequantCB);
%-----------------------------------------------------------
% IDCT
%-----------------------------------------------------------
fun = @(block_struct) idct2(block_struct.data);

Y1 = blockproc(iquantizedY, [8 8], fun);
cb1 = blockproc(iquantizedCB, [8 8], fun);
cr1 = blockproc(iquantizedCR, [8 8], fun);
%-----------------------------------------------------------

Ioutput(:,:,1)=Y1;
Ioutput(:,:,2)=cb1;
Ioutput(:,:,3)=cr1;

end

