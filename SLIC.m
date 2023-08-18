%超像素计算函数，SLIC如下：
%SLC算法 
%验入参数  SLIC.m为SLIC算法的实现 是一个function函数
%I  为RGB图像
%numseeds  种子点数量
%compactness   颜色与空间距离相关性
function [labels]=SLIC(num_seeds,compactness,R,G,B)
    [M,N]=size(R);
    %图像总的像素数量
    n_tp=M*N;
    %步进的间隔，补0.5的误差  每个种子点的距离近似
    step=floor(sqrt(n_tp/num_seeds)+0.5);    
    %计算种子点及数量
    [seeds,num_seeds]=GetSeeds(step,M,N,R,G,B);
    %计算超像素集合
    [seeds,labels]=SuperpixelSLIC(seeds,num_seeds,M,N,step,compactness,R,G,B);
    %强制类别连通
    k=floor(M*N/(step*step));
    labels=EnforceLabelConnectivity(labels,M,N,num_seeds,k);
    
end
%%调整图像的种子点
%输入参数
%         step  .步边间隔 zh
%         M     图像的高度
%         N     图像的宽际
%         R     颜色R分量
%         G     颜色G分量
%         B     颜色B分量
function [seeds,num_seeds]=GetSeeds(step,M,N,R,G,B)  %计算种子点及数量
    %种子点集合，分别为R,G.B.x.y
    seeds=zeros(1,5);
    %注意，这里的x.y与实际相反
    %计算坐标误差
    xstrips=floor(M/step);
    ystrips=floor(N/step);
    %计算x坐标误差
    xerr=floor(M-step*xstrips);
    if xerr<0
        xstrips=xstrips-1;
        xerr=floor(M-step*xstrips);
    end   
    %计算y 坐标标误差
    yerr=floor(N-step*ystrips);
    if yerr<0
        ystrips=ystrips-1;
        yerr=floor(N-step*ystrips);
    end    
    xerrperstrip=xerr/xstrips;
    yerrperstrip=yerr/ystrips;
    xoff=floor(step/2);
    yoff=floor(step/2);
    %种子点数器
    n=1;
    %实际的种子点数数量
    num_seeds=xstrips*ystrips;
    for x=0:xstrips-1
        xe=floor(x*xerrperstrip);
        for y=0:ystrips-1
            ye=floor(y*yerrperstrip);
            %种子点的y坐标
            seedy=floor(y*step+yoff+ye);
            %种子点的x坐标
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
%计算超像素集合
function [seeds,labels]=SuperpixelSLIC(seeds,num_seeds,M,N,step,compactness,R,G,B)
    %每个像素点的距离设定，正无穷大
    d=Inf(M,N);
    %图像像素点的类别矩阵
    labels=-1*ones(M,N);
    %偏移量
    offset=step;
    if step<8
        offset=step*1.5;
    end
    invwt=1/(step/compactness)^2;
    %迭代计算 中心种子点
    for itr=1:10
        for i=1:num_seeds
            %计算x的最小区间   璁＄畻x鐨勬渶灏忓尯闂?
            x_min=seeds(i,4)-offset;
            if x_min<1;
                x_min=1;
            end
            %计算x的最大区间
            x_max=seeds(i,4)+offset;
            if x_max>M
                x_max=M;
            end
            %计算y的最小区间
            y_min=seeds(i,5)-offset;
            if y_min<1;
                y_min=1;
            end
            %计算y的最大区间
            y_max=seeds(i,5)+offset;
            if y_max>N
                y_max=N;
            end   
            %计算2step*2step范围内的混合距离
            for x=x_min:x_max
                for y=y_min:y_max
                    %这里计算平方，不开方，只为了表交大小
                    d_color=(seeds(i,1)-R(x,y))^2+(seeds(i,2)-G(x,y))^2+(seeds(i,3)-B(x,y))^2;
                    d_space=(seeds(i,4)-x)^2+(seeds(i,5)-y)^2;
                    D=d_color+d_space*invwt;
                    %更为精确的计算
                    % D=sqrt(d_color)+sqrt(d_space*invwt);
                    if D<d(x,y)
                        d(x,y)=D;
                        labels(x,y)=i;
                    end
                end
            end
            %重新计算该种子点的中心点
        end
    end
    %创建新的种子点集合,G,B,x,y第6列为族的大小澶у皬
    new_seeds=zeros(num_seeds,6);
    for x=1:M
        for y=1:N
            %图像x,y所在位置的类别号
            label=labels(x,y);
            %将当前类别号x,y点的R,G,B,x,y值进行累加
            new_seeds(label,1)=new_seeds(label,1)+R(x,y);
            new_seeds(label,2)=new_seeds(label,2)+G(x,y);
            new_seeds(label,3)=new_seeds(label,3)+B(x,y);
            new_seeds(label,4)=new_seeds(label,4)+x;    
            new_seeds(label,5)=new_seeds(label,5)+y;
            new_seeds(label,6)=new_seeds(label,6)+1;
        end
    end
    %计算新的种子点
    for i=1:num_seeds
        seeds(i,:)=new_seeds(i,1:5)/new_seeds(i,6);
    end
end
%强制类别连通
function [labels,numlabels]=EnforceLabelConnectivity(labels,M,N,num_seeds,k)
    %
    nlabels=-1*ones(M,N);
    numlabels=num_seeds;
    sz=M*N;
    supsz=floor(sz/k);
    label=1;
%     oindex=1;
    %邻接类别
    adjlabel=1;
    for x=1:M
        for y=1:N
            if nlabels(x,y)<0
                %将点x，y类别号赋值
                nlabels(x,y)=label;
                %查找x，y周围是否有邻接类别
                if x-1>=1 && nlabels(x-1,y)>=1
                    adjlabel=nlabels(x-1,y);
                elseif x+1<=M && nlabels(x+1,y)>=1
                    adjlabel=nlabels(x+1,y);
                elseif y-1>=1 && nlabels(x,y-1)>=1
                    adjlabel=nlabels(x,y-1);
                elseif y+1<=N && nlabels(x,y+1)>=1
                    adjlabel=nlabels(x,y+1);
                end
                %查找所以与点x，y4连通的点
                %连接点（簇）计数器
                count=1;
                %连通点堆栈
                points=[x,y];
                ps_back=[x,y];
                while ~isempty(points)
                    %取出堆栈中第一个点，并以此为中心开始搜索类别相同的点
                    p=points(1,:);
                    %上点
                    if p(1)-1>=1
                        if nlabels(p(1)-1,p(2))<0 && labels(p(1)-1,p(2))==labels(x,y)
                            points=cat(1,points,[p(1)-1,p(2)]);
                            ps_back=cat(1,ps_back,[p(1)-1,p(2)]);
                            nlabels(p(1)-1,p(2))=label;
                            count=count+1;
                        end
                    end
                    %下点
                    if p(1)+1<=M
                        if nlabels(p(1)+1,p(2))<0 && labels(p(1)+1,p(2))==labels(x,y)
                            points=cat(1,points,[p(1)+1,p(2)]);
                            ps_back=cat(1,ps_back,[p(1)+1,p(2)]);
                            nlabels(p(1)+1,p(2))=label;
                            count=count+1;
                        end
                    end                    
                    %左点
                    if p(2)-1>=1
                        if nlabels(p(1),p(2)-1)<0 && labels(p(1),p(2)-1)==labels(x,y)
                            points=cat(1,points,[p(1),p(2)-1]);
                            ps_back=cat(1,ps_back,[p(1),p(2)-1]);
                            nlabels(p(1),p(2)-1)=label;
                            count=count+1;
                        end
                    end
                    %右点
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
                %如果簇的规模小于阈值，则将其合并到邻接类别中
                if count<=supsz/4
                    while ~isempty(ps_back)
                        p=ps_back(1,:);
                        nlabels(p(1),p(2))=adjlabel;
                        ps_back(1,:)=[];
                    end
                    %合并类别时，标号需要减一
                    label=label-1;
                end
                %类别  标签加1
                label=label+1;
            end
        end
    end
    numlabels=label;
    labels=nlabels;
end
 
 