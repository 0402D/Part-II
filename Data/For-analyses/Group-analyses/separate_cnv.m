% this script intends to take cnv_comp12j, where there's the CNV slopes
% according to expectation condition and latenesses, and put them into
% different columns for repeated measure ANOVA (2 factors) 

load('allinallj.mat')
load('allinallc1.mat')
load('allinallc2.mat')

joystick=[allinallj(:,1) allinallj(:,3)];
joystic=cell(size(joystick,1),1);
joystic(:)={'Joystick'};
joystick=[joystic joystick];
befor=cell(size(allinallc1,1),1);
befor(:)={'Before'};
before=[befor allinallc1];
afte=cell(size(allinallc2,1),1);
afte(:)={'After'};
after=[afte allinallc2];
% equate the size
sz=min([size(allinallc1,1) size(allinallc2,1) size(allinallj,1)]);
cnv_comp12j=[before(1:sz,:);joystick(1:sz,:);after(1:sz,:)];
save('cnv_comp12j','cnv_comp12j')

cnv_comp12j=table2cell(cnv_comp12j);
cnv_comp12j_sep=cell(size(cnv_comp12j,1)./12,12);

count1=0;
count2=0;
count3=0;
count4=0;
count5=0;
count6=0;
count7=0;
count8=0;
count9=0;
count10=0;
count11=0;
count12=0;

for trial=1:size(cnv_comp12j,1)
    if strcmp(cnv_comp12j{trial,1},'Before')
        if cnv_comp12j{trial,2}==1
            count1=count1+1;
            cnv_comp12j_sep{count1,1}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==2
            count2=count2+1;
            cnv_comp12j_sep{count2,2}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==3
            count3=count3+1;
            cnv_comp12j_sep{count3,3}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==4
            count4=count4+1;
            cnv_comp12j_sep{count4,4}=cnv_comp12j{trial,3};
        end
    elseif strcmp(cnv_comp12j{trial,1},'Joystick')
        if cnv_comp12j{trial,2}==1
            count5=count5+1;
            cnv_comp12j_sep{count5,5}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==2
            count6=count6+1;
            cnv_comp12j_sep{count6,6}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==3
            count7=count7+1;
            cnv_comp12j_sep{count7,7}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==4
            count8=count8+1;
            cnv_comp12j_sep{count8,8}=cnv_comp12j{trial,3};
        end
    elseif strcmp(cnv_comp12j{trial,1},'After')
        if cnv_comp12j{trial,2}==1
            count9=count9+1;
            cnv_comp12j_sep{count9,9}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==2
            count10=count10+1;
            cnv_comp12j_sep{count10,10}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==3
            count11=count11+1;
            cnv_comp12j_sep{count11,11}=cnv_comp12j{trial,3};
        elseif cnv_comp12j{trial,2}==4
            count12=count12+1;
            cnv_comp12j_sep{count12,12}=cnv_comp12j{trial,3};
        end
    end
end

cnv_comp12j_sep=cell2table(cnv_comp12j_sep,'Variablenames',{'B1','B2','B3','B4','J1','J2','J3','J4','A1','A2','A3','A4'});
save('cnv_comp12j_sep','cnv_comp12j_sep');
writetable(cnv_comp12j_sep,'cnv_comp12j_sep.csv','WriteRowNames',true);
