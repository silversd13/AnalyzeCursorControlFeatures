%% look at cursor state uncertainty over trials
clear, clc, close all

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190507';
expts(end).hhmmss = {'111526'};

% expts(end+1).yymmdd = '20190510';
% expts(end).hhmmss = {'104601','132311'};
% 
% expts(end+1).yymmdd = '20190514';
% expts(end).hhmmss = {'111822','133050'};
% 
% expts(end+1).yymmdd = '20190515';
% expts(end).hhmmss = {'105504'};

%% load data
ttl = {};
P = [];
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        
        % per block
        time_to_targ_pb = cell(1,8);
        success_pb = cell(1,8);
        
        % go through datafiles in fixed blocks
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_Fixed');
        disp(datadir)
        files = dir(fullfile(datadir,'Data*.mat'));
        
        % load data
        for iii=1:length(files),
            load(fullfile(files(iii).folder,files(iii).name));
            ttl{end+1} = sprintf('%s-%s',yymmdd,hhmmss);
            P(:,:,end+1) = TrialData.KalmanFilter{1}.P;
        end
    end
end
P = P(3:4,3:4,:);

%% plot trace of P
T = [];
for i=1:size(P,3),
    T(i) = trace(squeeze(P(:,:,i)));
end




