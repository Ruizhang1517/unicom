%��������ֵ������˹����

I=imread('24063.jpg');

I=im2double(I);

h=0:0.1:1;

v=0.01:-0.001:0;

J=imnoise(I, 'localvar', h, v);%hΪ��[0,1]֮������� ��ʾͼ�������ֵ vΪһ�����Ⱥ�h��ͬ����ʾ��h�����ȶ�Ӧ�ĸ�˹�����ķ���

figure;

subplot(121);  imshow(I),title('ԭͼ��');

subplot(122);  imshow(J),title('��Ӹ�˹�������ͼ��');
