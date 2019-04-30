%% process data into smaller, more managable files
clear, clc, close all

%% experiment info including adapt and fixed blocks
expts = [];

expts(end+1).yyyymmdd = '20190401';
expts(end).hhmmss = {'110449','111316','111942','112738','114253','133838','135810','141638'};

expts(end+1).yyyymmdd = '20190403';
expts(end).hhmmss = {'105510','111944','132634','135357'};

% % ignoring since rolling z-score
% expts(end+1).yyyymmdd = '20190409';
% expts(end).hhmmss = {'110409','112241','114901','135644'};

expts(end+1).yyyymmdd = '20190412';
expts(end).hhmmss = {'111554','113531','113822'};

expts(end+1).yyyymmdd = '20190415';
expts(end).hhmmss = {'111333','112549','132231','134412','140311'};

expts(end+1).yyyymmdd = '20190417';
expts(end).hhmmss = {'110418','112437','113706','135345'};

%% go through experiments and downsize
% 1. go through each folder, 
% 2. check for BCI_CLDA & BCI_Fixed folders
% 3. load each trial
% 4. create new structure that only includes necessary vars
% 5. save new structure with compression

basedir = '/Volumes/data/Bravo1';
savedir = '/Volumes/data/Bravo1/DownsizedTrials';
ct = 0;

% go through expts
for i=1:length(expts),
    expt = expts(i);
    yyyymmdd = expt.yyyymmdd;
    fprintf('%s\n',yyyymmdd)
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        fprintf('  %s\n',hhmmss)
    
        % 1. go through each folder
        expt_dir = fullfile(basedir,yyyymmdd,...
            'GangulyServer','Center-Out',yyyymmdd,hhmmss);
        clda_dir = fullfile(expt_dir,'BCI_CLDA');
        fixed_dir = fullfile(expt_dir,'BCI_Fixed');
        dirs = {clda_dir,fixed_dir};
        
        % 2. check if BCI_CLDA & BCI_Fixed exist
        clda_flag = exist(clda_dir,'dir')>0;
        fixed_flag = exist(fixed_dir,'dir')>0;
        dir_flags = [clda_flag,fixed_flag];
        
        for iii=1:length(dirs),
            flag = dir_flags(iii);
            if flag,
                datadir = dirs{iii};
                files = dir(fullfile(datadir,'Data*.mat'));
                for iiii=1:length(files),
                    % 3. load each trial
                    f = load(fullfile(datadir,files(iiii).name));
                    
                    % 4. track necessary vars
                    tidx = f.TrialData.Time > f.TrialData.Events(end).Time & ...
                        f.TrialData.Time <= f.TrialData.Events(end).Time+2;
                    
                    TrialData.TargetAngle = f.TrialData.TargetAngle;
                    TrialData.NeuralTime = f.TrialData.NeuralTime(tidx);
                    TrialData.NeuralSamps = f.TrialData.NeuralSamps(tidx);
                    TrialData.BroadbandData = cat(1,f.TrialData.BroadbandData{tidx})';
                    TrialData.Time = f.TrialData.Time(tidx);
                    TrialData.CursorState = f.TrialData.CursorState(:,tidx);
                    TrialData.IntendedCursorState = f.TrialData.IntendedCursorState(:,tidx);
                    
                    % 5. save new struct
                    ct = ct + 1;
                    save(fullfile(savedir,sprintf('Trial%05i.mat',ct)),'TrialData');
                    
                end
            end % if dir exists
        end % clda trials
    end % yyyymmdd
end % expts




