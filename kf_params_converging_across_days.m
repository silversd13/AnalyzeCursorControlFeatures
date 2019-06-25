%% check if kalman weights are converging within and across days
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
expts(end).hhmmss = {'104622','133540'};

expts(end+1).yymmdd = '20190610';
% expts(end).hhmmss = {'104104','131054'};
expts(end).hhmmss = {'104104'};

expts(end+1).yymmdd = '20190618';
expts(end).hhmmss = {'135020','141917'};

expts(end+1).yymmdd = '20190621';
expts(end).hhmmss = {'110109','112545','133227','135917'};


%% load performance metrics
fid = fopen('performance.csv');
tbl = textscan(fid,'%s%f%f%f%f%f%f','Delimiter',',','Headerlines',1);
fclose(fid);
perf_idx = [2,2,2,2,3,3,4,6,6,7,7,8,9,11,12,12,13,14,...
    15,15,16,16,17,18,19,19,20,20,21,21];

% ignore 6/10 afternoon
idx = 1:28;
perf_idx = [2,2,2,2,3,3,4,6,6,7,7,8,9,11,12,12,13,14,...
    15,15,16,16,17,18,19,19,20,20];

%% load data

% go through expts
Ccell = {};
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
            
            Ccell{trial} = TrialData.KalmanFilter{1}.C;
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

%% plot behavioral performance
figure;
subplot(4,1,1)
yyaxis left
plot(session_break(perf_idx)-1,tbl{6}(idx),'.'); hold on
plot(session_break(perf_idx)-1,smooth(session_break(perf_idx)-1,tbl{6}(idx),10),'--')
ylim([50,100])
xlim([0,trials(end)+1])
ylabel('Success Rate (%)')

yyaxis right
plot(session_break(perf_idx)-1,tbl{7}(idx),'.'); hold on
plot(session_break(perf_idx)-1,smooth(session_break(perf_idx)-1,tbl{7}(idx),10),'--')
ylim([0,25])
xlim([0,trials(end)+1])
ylabel('Median Time to Target (s)')

%% combine all plots into single figure
% look at angle btw weights (relative to final weights within session)
C = cat(3,Ccell{:});
Cx = squeeze(C(:,3,:));
Cy = squeeze(C(:,4,:));
Cc = squeeze(C(:,5,:));

x_ang = [];
y_ang = [];
c_ang = [];
tot_ang = [];
for i=1:length(session_break)-1,
    ref_idx = session_break(i+1)-1;
    idx = session_break(i):ref_idx-1;
    
    for t=idx,
        x_ang(end+1) = rad2deg(subspace(Cx(:,t),Cx(:,ref_idx)));
        y_ang(end+1) = rad2deg(subspace(Cy(:,t),Cy(:,ref_idx)));
        c_ang(end+1) = rad2deg(subspace(Cc(:,t),Cc(:,ref_idx)));
        tot_ang(end+1) = mean([x_ang(t),y_ang(t),c_ang(t)]);
    end
    x_ang(end+1) = nan;
    y_ang(end+1) = nan;
    c_ang(end+1) = nan;
    tot_ang(end+1) = nan;
end

subplot(4,1,2)
hold on
h(1)=plot(x_ang);
h(2)=plot(y_ang);
h(3)=plot(c_ang);
h(4)=plot(tot_ang);
ylabel({'\angle btw Kalman Weights','(current to last session)'})
title('Within Session Kalman Convergence')
xlim([0,trials(end)+1])

for i=1:length(session_break)-2,
    vline(gca,session_break(i+1)-1,'color',[.6,.6,.6]);
end
for i=1:length(day_break)-2,
    vline(gca,day_break(i+1)-1,'color','k','linewidth',2);
end

% look at angle btw weights (relative to final weights within day)
C = cat(3,Ccell{:});
Cx = squeeze(C(:,3,:));
Cy = squeeze(C(:,4,:));
Cc = squeeze(C(:,5,:));

x_ang = [];
y_ang = [];
c_ang = [];
tot_ang = [];
for i=1:length(day_break)-1,
    ref_idx = day_break(i+1)-1;
    idx = day_break(i):ref_idx-1;
    
    for t=idx,
        x_ang(end+1) = rad2deg(subspace(Cx(:,t),Cx(:,ref_idx)));
        y_ang(end+1) = rad2deg(subspace(Cy(:,t),Cy(:,ref_idx)));
        c_ang(end+1) = rad2deg(subspace(Cc(:,t),Cc(:,ref_idx)));
        tot_ang(end+1) = mean([x_ang(t),y_ang(t),c_ang(t)]);
    end
    x_ang(end+1) = nan;
    y_ang(end+1) = nan;
    c_ang(end+1) = nan;
    tot_ang(end+1) = nan;
end

subplot(4,1,3);
hold on
h(1)=plot(x_ang);
h(2)=plot(y_ang);
h(3)=plot(c_ang);
h(4)=plot(tot_ang);
ylabel({'\angle btw Kalman Weights','(current to last in day)'})
title('Within Day Kalman Convergence')
xlim([0,trials(end)+1])

for i=1:length(session_break)-2,
    vline(gca,session_break(i+1)-1,'color',[.6,.6,.6]);
end
for i=1:length(day_break)-2,
    vline(gca,day_break(i+1)-1,'color','k','linewidth',2);
end

% look at angle btw weights (relative to final weights across days)
C = cat(3,Ccell{:});
Cx = squeeze(C(:,3,:));
Cy = squeeze(C(:,4,:));
Cc = squeeze(C(:,5,:));

x_ang = [];
y_ang = [];
c_ang = [];
tot_ang = [];

ref_idx = trials(end);
idx = 1:ref_idx-1;
    
for t=idx,
    x_ang(end+1) = rad2deg(subspace(Cx(:,t),Cx(:,ref_idx)));
    y_ang(end+1) = rad2deg(subspace(Cy(:,t),Cy(:,ref_idx)));
    c_ang(end+1) = rad2deg(subspace(Cc(:,t),Cc(:,ref_idx)));
    tot_ang(end+1) = mean([x_ang(t),y_ang(t),c_ang(t)]);
end
x_ang(end+1) = nan;
y_ang(end+1) = nan;
c_ang(end+1) = nan;
tot_ang(end+1) = nan;

subplot(4,1,4)
hold on
h(1)=plot(x_ang);
h(2)=plot(y_ang);
h(3)=plot(c_ang);
h(4)=plot(tot_ang);
xlabel('trials')
ylabel({'\angle btw Kalman Weights','(current to last overall)'})
title('Across Day Kalman Convergence')
xlim([0,trials(end)+1])

for i=1:length(session_break)-2,
    vline(gca,session_break(i+1)-1,'color',[.6,.6,.6]);
end
for i=1:length(day_break)-2,
    vline(gca,day_break(i+1)-1,'color','k','linewidth',2);
end
legend(h,{'Vx Weights','Vy Weights','Constant Weights','Avg Angle'})
