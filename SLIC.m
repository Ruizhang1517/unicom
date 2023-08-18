%�����ؼ��㺯����SLIC���£�
%SLC�㷨 
%�������  SLIC.mΪSLIC�㷨��ʵ�� ��һ��function����
%I  ΪRGBͼ��
%numseeds  ���ӵ�����
%compactness   ��ɫ��ռ���������
function [labels]=SLIC(num_seeds,compactness,R,G,B)
    [M,N]=size(R);
    %ͼ���ܵ���������
    n_tp=M*N;
    %�����ļ������0.5�����  ÿ�����ӵ�ľ������
    step=floor(sqrt(n_tp/num_seeds)+0.5);    
    %�������ӵ㼰����
    [seeds,num_seeds]=GetSeeds(step,M,N,R,G,B);
    %���㳬���ؼ���
    [seeds,labels]=SuperpixelSLIC(seeds,num_seeds,M,N,step,compactness,R,G,B);
    %ǿ�������ͨ
    k=floor(M*N/(step*step));
    labels=EnforceLabelConnectivity(labels,M,N,num_seeds,k);
    
end
%%����ͼ������ӵ�
%�������
%         step  .���߼�� zh
%         M     ͼ��ĸ߶�
%         N     ͼ��Ŀ��
%         R     ��ɫR����
%         G     ��ɫG����
%         B     ��ɫB����
function [seeds,num_seeds]=GetSeeds(step,M,N,R,G,B)  %�������ӵ㼰����
    %���ӵ㼯�ϣ��ֱ�ΪR,G.B.x.y
    seeds=zeros(1,5);
    %ע�⣬�����x.y��ʵ���෴
    %�����������
    xstrips=floor(M/step);
    ystrips=floor(N/step);
    %����x�������
    xerr=floor(M-step*xstrips);
    if xerr<0
        xstrips=xstrips-1;
        xerr=floor(M-step*xstrips);
    end   
    %����y ��������
    yerr=floor(N-step*ystrips);
    if yerr<0
        ystrips=ystrips-1;
        yerr=floor(N-step*ystrips);
    end    
    xerrperstrip=xerr/xstrips;
    yerrperstrip=yerr/ystrips;
    xoff=floor(step/2);
    yoff=floor(step/2);
    %���ӵ�����
    n=1;
    %ʵ�ʵ����ӵ�������
    num_seeds=xstrips*ystrips;
    for x=0:xstrips-1
        xe=floor(x*xerrperstrip);
        for y=0:ystrips-1
            ye=floor(y*yerrperstrip);
            %���ӵ��y����
            seedy=floor(y*step+yoff+ye);
            %���ӵ��x����
            seedx=floor(x*step+xoff+xe);
            seeds(n,1)=R(seedx,seedy);
            seeds(n,2)=G(seedx,seedy);
            seeds(n,3)=B(seedx,seedy);
            seeds(n,4)=seedx;
            seeds(n,5)=seedy;
            n=n+1;
        end
    end
end
%���㳬���ؼ���
function [seeds,labels]=SuperpixelSLIC(seeds,num_seeds,M,N,step,compactness,R,G,B)
    %ÿ�����ص�ľ����趨���������
    d=Inf(M,N);
    %ͼ�����ص��������
    labels=-1*ones(M,N);
    %ƫ����
    offset=step;
    if step<8
        offset=step*1.5;
    end
    invwt=1/(step/compactness)^2;
    %�������� �������ӵ�
    for itr=1:10
        for i=1:num_seeds
            %����x����С����   计算x的最小区�?
            x_min=seeds(i,4)-offset;
            if x_min<1;
                x_min=1;
            end
            %����x���������
            x_max=seeds(i,4)+offset;
            if x_max>M
                x_max=M;
            end
            %����y����С����
            y_min=seeds(i,5)-offset;
            if y_min<1;
                y_min=1;
            end
            %����y���������
            y_max=seeds(i,5)+offset;
            if y_max>N
                y_max=N;
            end   
            %����2step*2step��Χ�ڵĻ�Ͼ��릻
            for x=x_min:x_max
                for y=y_min:y_max
                    %�������ƽ������������ֻΪ�˱���С
                    d_color=(seeds(i,1)-R(x,y))^2+(seeds(i,2)-G(x,y))^2+(seeds(i,3)-B(x,y))^2;
                    d_space=(seeds(i,4)-x)^2+(seeds(i,5)-y)^2;
                    D=d_color+d_space*invwt;
                    %��Ϊ��ȷ�ļ���
                    % D=sqrt(d_color)+sqrt(d_space*invwt);
                    if D<d(x,y)
                        d(x,y)=D;
                        labels(x,y)=i;
                    end
                end
            end
            %���¼�������ӵ�����ĵ�
        end
    end
    %�����µ����ӵ㼯��,G,B,x,y��6��Ϊ��Ĵ�С大小
    new_seeds=zeros(num_seeds,6);
    for x=1:M
        for y=1:N
            %ͼ��x,y����λ�õ�����
            label=labels(x,y);
            %����ǰ����x,y���R,G,B,x,yֵ�����ۼ�
            new_seeds(label,1)=new_seeds(label,1)+R(x,y);
            new_seeds(label,2)=new_seeds(label,2)+G(x,y);
            new_seeds(label,3)=new_seeds(label,3)+B(x,y);
            new_seeds(label,4)=new_seeds(label,4)+x;    
            new_seeds(label,5)=new_seeds(label,5)+y;
            new_seeds(label,6)=new_seeds(label,6)+1;
        end
    end
    %�����µ����ӵ�
    for i=1:num_seeds
        seeds(i,:)=new_seeds(i,1:5)/new_seeds(i,6);
    end
end
%ǿ�������ͨ
function [labels,numlabels]=EnforceLabelConnectivity(labels,M,N,num_seeds,k)
    %
    nlabels=-1*ones(M,N);
    numlabels=num_seeds;
    sz=M*N;
    supsz=floor(sz/k);
    label=1;
%     oindex=1;
    %�ڽ����
    adjlabel=1;
    for x=1:M
        for y=1:N
            if nlabels(x,y)<0
                %����x��y���Ÿ�ֵ
                nlabels(x,y)=label;
                %����x��y��Χ�Ƿ����ڽ����
                if x-1>=1 && nlabels(x-1,y)>=1
                    adjlabel=nlabels(x-1,y);
                elseif x+1<=M && nlabels(x+1,y)>=1
                    adjlabel=nlabels(x+1,y);
                elseif y-1>=1 && nlabels(x,y-1)>=1
                    adjlabel=nlabels(x,y-1);
                elseif y+1<=N && nlabels(x,y+1)>=1
                    adjlabel=nlabels(x,y+1);
                end
                %�����������x��y4��ͨ�ĵ�
                %���ӵ㣨�أ�������
                count=1;
                %��ͨ���ջ
                points=[x,y];
                ps_back=[x,y];
                while ~isempty(points)
                    %ȡ����ջ�е�һ���㣬���Դ�Ϊ���Ŀ�ʼ���������ͬ�ĵ�
                    p=points(1,:);
                    %�ϵ�
                    if p(1)-1>=1
                        if nlabels(p(1)-1,p(2))<0 && labels(p(1)-1,p(2))==labels(x,y)
                            points=cat(1,points,[p(1)-1,p(2)]);
                            ps_back=cat(1,ps_back,[p(1)-1,p(2)]);
                            nlabels(p(1)-1,p(2))=label;
                            count=count+1;
                        end
                    end
                    %�µ�
                    if p(1)+1<=M
                        if nlabels(p(1)+1,p(2))<0 && labels(p(1)+1,p(2))==labels(x,y)
                            points=cat(1,points,[p(1)+1,p(2)]);
                            ps_back=cat(1,ps_back,[p(1)+1,p(2)]);
                            nlabels(p(1)+1,p(2))=label;
                            count=count+1;
                        end
                    end                    
                    %���
                    if p(2)-1>=1
                        if nlabels(p(1),p(2)-1)<0 && labels(p(1),p(2)-1)==labels(x,y)
                            points=cat(1,points,[p(1),p(2)-1]);
                            ps_back=cat(1,ps_back,[p(1),p(2)-1]);
                            nlabels(p(1),p(2)-1)=label;
                            count=count+1;
                        end
                    end
                    %�ҵ�
                    if p(2)+1<=N
                        if nlabels(p(1),p(2)+1)<0 && labels(p(1),p(2)+1)==labels(x,y)
                            points=cat(1,points,[p(1),p(2)+1]);
                            ps_back=cat(1,ps_back,[p(1),p(2)+1]);
                            nlabels(p(1),p(2)+1)=label;
                            count=count+1;
                        end
                    end  
                    points(1,:)=[];
                end
                %����صĹ�ģС����ֵ������ϲ����ڽ������
                if count<=supsz/4
                    while ~isempty(ps_back)
                        p=ps_back(1,:);
                        nlabels(p(1),p(2))=adjlabel;
                        ps_back(1,:)=[];
                    end
                    %�ϲ����ʱ�������Ҫ��һ
                    label=label-1;
                end
                %���  ��ǩ��1
                label=label+1;
            end
        end
    end
    numlabels=label;
    labels=nlabels;
end
 
 