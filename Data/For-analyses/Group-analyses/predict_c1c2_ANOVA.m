% this script intends to concatenate the CNV slopes of the participants who did not predict in
% the implicit expectation condition (first 4 blocks), but who did predict
% in the last 4 blocks, 
% and contrast them with randomly selected equal number of participants who
% did not predict in either expectation condition 

% this script supports ANOVA in JASP: 
% first column: whether they predicted; 
% second column: whether the data comes from the first 4 blocks or the last
% 4 blocks; 
% third column: latenesses 
% fourth column: the CNV slopes 

% all participants: 
allpart=1:21;
% predicting participants
prdctpt=[14 15 19 21];
% this participant is not included in the pool of non-predicting
% participants 
funky=17;
parttoexclude=[prdctpt funky];
nprdctpt=setdiff(allpart,parttoexclude);
% randomly select participants 
nprdctpt1=nprdctpt(randperm(length(nprdctpt),length(prdctpt)));
a=setdiff(nprdctpt,nprdctpt1);
nprdctpt2=a(randperm(length(a),length(prdctpt)));

% specify comparison (predict/nonpredict vs. nonpredict/nonpredict)
test=input('Run the real or control test? (r/c): ','s');
if ~ismember(test,['r' 'c'])
    test=input('Run the real or control test? (r/c): ','s');
end
if test=='r'
    parttoinclude=[prdctpt nprdctpt1];
elseif test=='c'
    parttoinclude=[nprdctpt1 nprdctpt2];
else
    error('Error in participant numbers. ')
end

allpre_c1c2=[];
allnpre_c1c2=[];

for part=parttoinclude
    load(['partinallc1_' num2str(part) '.mat']);
    load(['partinallc2_' num2str(part) '.mat']);
    partinallc1=table2cell(partinallc1);
    partinallc2=table2cell(partinallc2);
    partpre_c1c2=cell(size(partinallc1,1)+size(partinallc2,1),4);
    partpre_c1c2(1:size(partinallc1,1),2)={'Before'};
    partpre_c1c2((size(partinallc1,1)+1):end,2)={'After'};
    if ismember(part,prdctpt)
        partpre_c1c2(:,1)={'Predicting'};
    else
        if test=='r'
            partpre_c1c2(:,1)={'NotPredicting'};
        elseif test=='c'
            if ismember(part,nprdctpt1)
                partpre_c1c2(:,1)={'NotPredicting1'};
            else
                partpre_c1c2(:,1)={'NotPredicting2'};
            end
        end
    end
    concat=[partinallc1;partinallc2];
    partpre_c1c2(:,3:4)=concat;
    if test=='r'
        allpre_c1c2=[allpre_c1c2;partpre_c1c2];
    else
        allnpre_c1c2=[allnpre_c1c2;partpre_c1c2];
    end
end

if test=='r'
    allpre_c1c2=cell2table(allpre_c1c2,'VariableNames',{'Predicting','BeforeorAfter','Lateness','CNVSlope'});
    save('allpre_c1c2','allpre_c1c2');
    writetable(allpre_c1c2,'allpre_c1c2.csv','WriteRowNames',true);
else
    allnpre_c1c2=cell2table(allnpre_c1c2,'VariableNames',{'Predicting','BeforeorAfter','Lateness','CNVSlope'});
    save('allnpre_c1c2','allnpre_c1c2');
    writetable(allnpre_c1c2,'allnpre_c1c2.csv','WriteRowNames',true);
end


