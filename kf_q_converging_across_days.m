%% check if kalman q matrix is changing within and across days
clear, clc, close all
cc = hsv(8);

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190514';
expts(end).hhmmss = {'112836','133050'};

expts(end+1).yymmdd = '20190515';
expts(end).hhmmss = {'110735'};

expts(end+1).yymmdd = '20190521';
expts(end).hhmmss = {'135008','141438'};

expts(end+1).yymmdd = '20190524';
expts(end).hhmmss = {'110219','133313'};

expts(end+1).yymmdd = '20190529';
expts(end).hhmmss = {'105609','113247','132457','135030'};

expts(end+1).yymmdd = '20190531';
expts(end).hhmmss = {'102944','111946','132244','135046'};

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'112454','140706'};

expts(end+1).yymmdd = '20190607';
expts(end).hhmmss = {'104622','133540','133540'};

% expts(end+1).yymmdd = '20190610';
% expts(end).hhmmss = {'104104','131054'};

%% load data

% go through expts
Qcell = {};
alpha = {};
lambda = {};
TargetID = {};
TargetIDstr = {};
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
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_CLDA');
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        T = length(datafiles);

        for iii=1:T,
            % load data, grab neural features
            disp(datafiles(iii).name)
            load(fullfile(datadir,datafiles(iii).name))
            
            Qcell{trial} = TrialData.KalmanFilter{1}.Q;
            alpha{trial} = TrialData.CursorAssist(1);
            lambda{trial} = round(TrialData.KalmanFilter{1}.Lambda,2);
            TargetID{trial} = TrialData.TargetID;
            TargetIDstr{trial} = int2str(TrialData.TargetID);
            
            trials(trial) = trial;
            trial = trial + 1;
        end
        
    end
end
day_break(end+1) = trial;
session_break(end+1) = trial; 

%% combine all plots into single figure
Q = cat(3,Qcell{:});

q_norm = [];    
for t=1:trials(end)-1,
    q_norm(end+1) = trace(Q(:,:,t)); %norm(triu(Q(:,:,t)),'fro');
end

hold on
h(1)=plot(q_norm);
xlabel('trials')
ylabel({'frobenius norm of upper Q'})
title('Across Day Kalman Convergence')
xlim([0,trials(end)+1])

for i=1:length(session_break)-2,
    vline(gca,session_break(i+1)-1,'color',[.6,.6,.6]);
end
for i=1:length(day_break)-2,
    vline(gca,day_break(i+1)-1,'color','k','linewidth',2);
end
