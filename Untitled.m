%根据亮度值产生高斯噪声

I=imread('24063.jpg');

I=im2double(I);

h=0:0.1:1;

v=0.01:-0.001:0;

J=imnoise(I, 'localvar', h, v);%h为在[0,1]之间的向量 表示图像的亮度值 v为一个长度和h相同，表示与h中亮度对应的高斯噪声的方差

figure;

subplot(121);  imshow(I),title('原图像');

subplot(122);  imshow(J),title('添加高斯噪声后的图像');
