f=imread('BaboonRGB.tif');
%                            quality
[output]= jpegCompression(f,20);
figure;
subplot(1,2,1),imshow(f);
subplot(1,2,2),imshow(output);
