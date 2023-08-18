%�߽��߼�⺯����FindAroundline����

%���߽����Ϊ��ɫ  points
%FindAroundLine.m�������������ؿ黭�߽��ߵ�function����
function [points]=FindAroundLine(labels)
    [M,N]=size(labels);
    %��ʼ���߽�����
    points=zeros(1,2);
    %����ͨ��
    dx=[-1, -1,  0,  1, 1, 1, 0, -1];
    dy=[0, -1, -1, -1, 0, 1, 1,  1];
    %������
    n=1;
    %Ѱ�ҳ����صı߽��ߣ��ð���ͨ���ж�
    for x=1:M
        for y=1:N
            %��Χ�����ͬ������
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