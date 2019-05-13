function downsize_data()
% process data into smaller, more managable files
% go through experiments and downsize
% 1. go through each experiment,
% 3. check for Imagined, BCI_CLDA, & BCI_Fixed folders
% 4. load each trial
% 5. create new structure that only includes necessary vars
% 8. save new structure as individual vars with compression


% experiment info for loading
basedir = '/media/dsilver/data/Bravo1';
savedir = '/media/dsilver/data/Bravo1/DownsizedTrials';
features = {'delta','theta','alpha','beta','low_gamma','high_gamma'};

expts = [];

expts(end+1).yyyymmdd = '20190403';
expts(end).hhmmss = {'105510',      '111944'};
expts(end).brocks = {'105455-001',  '105455-002'};

expts(end+1).yyyymmdd = '20190417';
expts(end).hhmmss = {'105410',      '110418',       '112437',       '113706',       '134447',   '135345'};
expts(end).brocks = {'105357-001',  '105357-002',   '105357-003',   '105357-004', '134435-001', '134435-002'};

expts(end+1).yyyymmdd = '20190426';
expts(end).hhmmss = {'111618',      '115111'};
expts(end).brocks = {'111533-001',  '111533-002'};

expts(end+1).yyyymmdd = '20190429';
expts(end).hhmmss = {'130907',      '134613',       '135428',       '140100'};
expts(end).brocks = {'130848-001',  '130848-002',   '130848-003',   '130848-004'};

expts(end+1).yyyymmdd = '20190501';
expts(end).hhmmss = {'133420',      '133745',       '135512'};
expts(end).brocks = {'133403-001',  '133403-002',   '133403-003'};


% 1. go through expts
for i=1:length(expts), % date
    expt = expts(i);
    yyyymmdd = expt.yyyymmdd;
    fprintf('%s\n',yyyymmdd)
    
    for ii=1:length(expt.hhmmss), % session within date
        hhmmss  = expt.hhmmss{ii};
        brock   = expt.brocks{ii};
        fprintf('  %s / %s\n',hhmmss,brock)
        
        % % load blackrock, parse into trials
        % [anin,lfp,Fs] = load_blackrock(basedir,yyyymmdd,brock);
        % trials = parse_blackrock(anin,Fs);
        
        % 3. go through each folder
        expt_dir = fullfile(basedir,yyyymmdd,...
            'GangulyServer','Center-Out',yyyymmdd,hhmmss);
        imag_dir = fullfile(expt_dir,'Imagined');
        clda_dir = fullfile(expt_dir,'BCI_CLDA');
        fixed_dir = fullfile(expt_dir,'BCI_Fixed');
        
        % combine into one list of trials
        files = [];
        files = cat(1,files,dir(fullfile(imag_dir,'Data*.mat')));
        files = cat(1,files,dir(fullfile(clda_dir,'Data*.mat')));
        files = cat(1,files,dir(fullfile(fixed_dir,'Data*.mat')));
        
        % assert(length(files)==length(trials),...
        %     'matlab trials do not match blackrock trials')
        
        for iii=1:length(files),
            % parse filename to get trial info
            split_path = strsplit(files(iii).folder,'/');
            trial_type = split_path{end};
            split_name = strsplit(files(iii).name,'Data');
            split_name = strsplit(split_name{2},'.mat');
            trial = str2double(split_name{1});
            savefile = fullfile(savedir,sprintf('%s_%s_%s_Trial%04i.mat',yyyymmdd,hhmmss,trial_type,trial));
            
            % skip if savefile already exists
            if exist(savefile,'file'),
                continue;
            end
            
            % 3. load each trial - get idx for reaching to target
            f = load(fullfile(files(iii).folder,files(iii).name));
            
            % 4. track necessary vars (interp to 10hz if necessary)
            TrialData.TargetAngle = f.TrialData.TargetAngle;
            TrialData.TargetPosition = f.TrialData.TargetPosition;
            TrialData.Success = f.TrialData.ErrorID==0;
            if iscell(f.TrialData.KalmanFilter),
                if isempty(f.TrialData.KalmanFilter),
                    TrialData.KalmanFilter = [];
                else,
                    TrialData.KalmanFilter = f.TrialData.KalmanFilter{1};
                end
            else,
                TrialData.KalmanFilter = f.TrialData.KalmanFilter;
            end
            
            tidx = f.TrialData.NeuralTime > f.TrialData.Events(end).Time;
            TrialData.NeuralTime = f.TrialData.NeuralTime(tidx);
            TrialData.NeuralSamps = f.TrialData.NeuralSamps(tidx);
            TrialData.BroadbandData = cat(1,f.TrialData.BroadbandData{tidx})';
            Y = cat(2,f.TrialData.NeuralFeatures{tidx});
            if f.TrialData.Params.UpdateRate==5, % interpolate to 10hz
                x  = linspace(1,length(TrialData.NeuralTime),  length(TrialData.NeuralTime));
                xq = linspace(1,length(TrialData.NeuralTime),2*length(TrialData.NeuralTime));
                Yq = [];
                for iiii=1:size(Y,1),
                    Yq(iiii,:) = interp1(x,Y(iiii,:),xq);
                end
                NeuralFeatures = Yq;
            else,
                NeuralFeatures = Y;
            end
            % store each neural feature separately for fast loading of
            % individual features
            TrialData.DeltaPhase    = NeuralFeatures(0*128+(1:128),:);
            TrialData.DeltaPower    = NeuralFeatures(1*128+(1:128),:);
            TrialData.ThetaPower    = NeuralFeatures(2*128+(1:128),:);
            TrialData.AlphaPower    = NeuralFeatures(3*128+(1:128),:);
            TrialData.BetaPower     = NeuralFeatures(4*128+(1:128),:);
            TrialData.LowGammaPower = NeuralFeatures(5*128+(1:128),:);
            TrialData.HighGammaPower= NeuralFeatures(6*128+(1:128),:);
            
            tidx = f.TrialData.Time > f.TrialData.Events(end).Time;
            TrialData.Time = f.TrialData.Time(tidx);
            if f.TrialData.Params.ScreenRefreshRate==5, % interp to 10hz
                x  = linspace(1,length(TrialData.Time),  length(TrialData.Time));
                xq = linspace(1,length(TrialData.Time),2*length(TrialData.Time));
                S  = f.TrialData.CursorState(:,tidx);
                IS = f.TrialData.IntendedCursorState(:,tidx);
                Sq = [];
                ISq = [];
                for iiii=1:5,
                    Sq(iiii,:)  = interp1(x, S(iiii,:),xq);
                    ISq(iiii,:) = interp1(x,IS(iiii,:),xq);
                end
                
                TrialData.CursorState = Sq;
                TrialData.IntendedCursorState = ISq;
            else,
                S = f.TrialData.CursorState(:,tidx);
                IS = f.TrialData.IntendedCursorState(:,tidx);
                
                TrialData.CursorState = S;
                TrialData.IntendedCursorState = IS;
            end
            
            % 5. save new struct
            save(savefile,'-struct','TrialData');
            
        end % trials
    end % yyyymmdd
end % expts




