%边界线检测函数，FindAroundline如下

%将边界点设为白色  points
%FindAroundLine.m是用来将超像素块画边界线的function函数
function [points]=FindAroundLine(labels)
    [M,N]=size(labels);
    %初始化边界点矩阵
    points=zeros(1,2);
    %八连通点
    dx=[-1, -1,  0,  1, 1, 1, 0, -1];
    dy=[0, -1, -1, -1, 0, 1, 1,  1];
    %计数器
    n=1;
    %寻找超像素的边界线，用八连通性判断
    for x=1:M
        for y=1:N
            %周围点类别不同计数器
            np=0;
            for i=1:length(dx)
                xx=x+dx(i);
                yy=y+dy(i);
                if (xx>=1 && xx<=M) && (yy>=1 && yy<=N)
                    if labels(xx,yy)~=labels(x,y)
                        np=np+1;
                    end
                end
            end
            if np>1
                points(n,:)=[x,y];
                n=n+1;
            end
        end
    end    
end