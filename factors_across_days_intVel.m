%% check if feature covariance changes across days
clear, clc, close all
cc = hsv(8);

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190514';
expts(end).hhmmss = {'135927','140808','141731','142704'};

expts(end+1).yymmdd = '20190515';
expts(end).hhmmss = {'112302','113447'};

expts(end+1).yymmdd = '20190521';
expts(end).hhmmss = {'135943'};

expts(end+1).yymmdd = '20190524';
expts(end).hhmmss = {'111731','112353','134653','135957'};

expts(end+1).yymmdd = '20190529';
expts(end).hhmmss = {'111528','114050'};

expts(end+1).yymmdd = '20190531';
expts(end).hhmmss = {'105048','110703','112444','133517','140204','141319'};

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'114636','143109'};

expts(end+1).yymmdd = '20190607';
expts(end).hhmmss = {'105615','135050','140828'};

expts(end+1).yymmdd = '20190610';
expts(end).hhmmss = {'105809','110746'};

expts(end+1).yymmdd = '20190618';
expts(end).hhmmss = {'135944','143103'};

expts(end+1).yymmdd = '20190621';
expts(end).hhmmss = {'110942','113715','134143','141129'};

days = cat(1,expts.yymmdd);

%% load data

% go through expts
Fcell = {};
TargetID = {};
CursorState = {};
IntendedCursorState = {};
KF = {};

trial = 1;
trials = [];
day_break = [];
session_break = [];
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    day_break(end+1) = trial; 
    
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        session_break(end+1) = trial; 
        
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_Fixed');
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        T = length(datafiles);

        for iii=1:T,
            % load data, grab neural features
            disp(datafiles(iii).name)
            load(fullfile(datadir,datafiles(iii).name))
            
            if strcmp(TrialData.Events(end).Str,'Reach Target'),
                idx = TrialData.Time > TrialData.Events(end).Time;
                Fcell{trial} = cat(2,TrialData.NeuralFeatures{idx})';
                TargetID{trial} = TrialData.TargetID;
                CursorState{trial} = TrialData.CursorState(:,idx);
                IntendedCursorState{trial} = TrialData.IntendedCursorState(:,idx);
                KF{trial} = TrialData.KalmanFilter{1};
            else,
                Fcell{trial} = [];
                TargetID{trial} = [];
                CursorState{trial} = [];
                IntendedCursorState{trial} = [];
            end
            
            trials(trial) = trial;
            trial = trial + 1;
        end
        
    end
end
day_break(end+1) = trial;
session_break(end+1) = trial; 

%% Factor Analysis for all up trials
int_dirs = (0:45:360)' - 45/2;
figure;
SOT = zeros(7,length(day_break)-1,8);
for feature=1:7,
    for i=1:length(day_break)-1,
        % only trials from single day
        day_idx = day_break(i):day_break(i+1)-1;
        F_day = cat(1,Fcell{day_idx});
        CS_day = cat(2,CursorState{day_idx})';
        ICS_day = cat(2,IntendedCursorState{day_idx})';
        
        % compute intended target dir
        int_vel = ICS_day(:,3:4);
        int_dir = atan2d(int_vel(:,2),int_vel(:,1));
        
        for t=1:8,
            % only trials for intending to dir "t"
            int_dir_edges = [int_dirs(t),int_dirs(t+1)];
            if t==1, % handle circular nature
                idx = int_dir>=int_dir_edges(1) ...
                    & int_dir<int_dir_edges(2);
            else,
                idx = mod(int_dir,360)>=int_dir_edges(1) ...
                    & mod(int_dir,360)<int_dir_edges(2);
            end
            F = F_day(idx,:);
            
            % select feature
            F_feature = F(:,128*(feature-1)+1:128*feature);
            
            % do factor analysis
            [estParams, LL] = myfastfa(F_feature', 2);
            FA = @(X) estParams.L\(X'-estParams.d);
            
            % shared over total variance
            sharedCov = diag(estParams.L*estParams.L');
            privateCov = estParams.Ph;
            totalCov = sharedCov + privateCov;
            sharedOverTot = sharedCov ./ totalCov;
            
            % track shared over total per day
            SOT(feature,i,t) = sum(sharedCov) / sum(totalCov);
            
        end
        
    end
    
    subplot(7,2,2*(feature-1)+1)
    plot(1:8,squeeze(SOT(feature,:,:))','.'); hold on
    errorbar(1:8,mean(squeeze(SOT(feature,:,:))),std(squeeze(SOT(feature,:,:)))/sqrt(size(squeeze(SOT(feature,:,:)),1)),'k')
    xlim([0.5,8.5])
    ylabel({sprintf('feature%i',feature),'SOT'})
    if feature==1,
        title('Per Binned Intended Velocity')
    elseif feature==7,
        xlabel('Per Binned Intended Velocity')
    end
    
    subplot(7,2,2*(feature-1)+2)
    errorbar(1:size(squeeze(SOT(feature,:,:)),1),mean(squeeze(SOT(feature,:,:)),2),std(squeeze(SOT(feature,:,:)),[],2)/sqrt(8))
    xlim([0.5,length(day_break)-.5])
    if feature==1,
        title('Per Day')
    elseif feature==7,
        xlabel('days')
    end
    
end
tightfig;

figure('name','all_features');

subplot(1,2,1)
plot(1:8,squeeze(mean(SOT))','.'); hold on
errorbar(1:8,mean(squeeze(mean(SOT))),std(squeeze(mean(SOT)))/sqrt(size(SOT,1)),'k')
xlim([0.5,8.5])
xlabel('Per Binned Intended Velocity')
ylabel('shared / total var')
title('SoT per Target')

subplot(1,2,2)
errorbar(1:size(squeeze(mean(SOT)),1),mean(squeeze(mean(SOT)),2),std(squeeze(mean(SOT)),[],2)/sqrt(8))
xlim([0.5,length(day_break)-0.5])
xlabel('days')
ylabel('shared / total var')
title('SoT per day')

