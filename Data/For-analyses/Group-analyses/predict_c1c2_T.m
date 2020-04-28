% this function is to be run after predict_c1c2_ANOVA 
% it takes allpre_c1c2, and allnpre_c1c2 
% and separate the conditions into different columns, so that a T test can
% be performed 

% there will be 3 outputs: 
% pre_c1c2_T: comparison within predicting participants before and after
% joystick; 
% prenpre_c2_T: comparison between participants after joystick; 
% npre_c1c2_T: comparison within non-predicting participants before and after
% joystick; 

clear all 

load('allpre_c1c2.mat')
load('allnpre_c1c2.mat')
allpre_c1c2=table2cell(allpre_c1c2);
allnpre_c1c2=table2cell(allnpre_c1c2);

%% in allpre_c1c2
findpredict=allpre_c1c2(:,1);
findpredict=find(ismember(findpredict,'Predicting'));
findnpredict=setdiff(1:size((allpre_c1c2),1),findpredict);

findbefore=find(ismember(allpre_c1c2(:,2),'Before'));
% indices where the two intersect 
interprebefore=intersect(findpredict,findbefore);
interpreafter=setdiff(findpredict,interprebefore);
% in case the number of data poitns for before and after are not the same 
minn=min([length(interprebefore),length(interpreafter)]);
% take out before and after 
pre_c1c2_T(1:minn,1:2)=allpre_c1c2(interprebefore(randperm(length(interprebefore),minn)),3:4);
pre_c1c2_T(1:minn,3:4)=allpre_c1c2(interpreafter(randperm(length(interpreafter),minn)),3:4);
pre_c1c2_T=cell2table(pre_c1c2_T,'VariableNames',{'LateBefore','CNVBefore','LateAfter','CNVAfter'});
save('pre_c1c2_T','pre_c1c2_T')
writetable(pre_c1c2_T,'pre_c1c2_T.csv','WriteRowNames',true);

% finds row numbers of after in non-predicting 
internpreafter=setdiff(findnpredict,intersect(findnpredict,findbefore));
minn1=min([length(interpreafter) length(internpreafter)]);
prenpre_c2_T(1:minn1,1:2)=allpre_c1c2(interpreafter(randperm(length(interpreafter),minn1)),3:4);
prenpre_c2_T(1:minn1,3:4)=allpre_c1c2(internpreafter(randperm(length(internpreafter),minn1)),3:4);
prenpre_c2_T=cell2table(prenpre_c2_T,'VariableNames',{'LateAfterPre','CNVAfterPre','LateAfterNopre','CNVAfterNopre'});
save('prenpre_c2_T','prenpre_c2_T')
writetable(prenpre_c2_T,'prenpre_c2_T.csv','WriteRowNames',true);

%% compare afters in npre
findaftern=find(ismember(allnpre_c1c2(:,2),'After'));
firsthalf=1:(size(allnpre_c1c2,1)./2);
intergrp1=intersect(findaftern,firsthalf);
intergrp2=intersect(findaftern,length(firsthalf)+1:size(allnpre_c1c2));
minn2=min([length(intergrp1),length(intergrp2)]);
npre_c2_T(1:minn2,1:2)=allnpre_c1c2(intergrp1(randperm(length(intergrp1),minn2)),3:4);
npre_c2_T(1:minn2,3:4)=allnpre_c1c2(intergrp2(randperm(length(intergrp2),minn2)),3:4);
npre_c2_T=cell2table(npre_c2_T,'VariableNames',{'LateAfterNopre1','CNVAfterNopre1','LateAfterNopre2','CNVAfterNopre2'});
save('npre_c2_T','npre_c2_T')
writetable(npre_c2_T,'npre_c2_T.csv','WriteRowNames',true);
