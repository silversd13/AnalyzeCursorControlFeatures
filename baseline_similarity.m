%% x vs y
clear, clc, close all

%% experiment info
expts = [];

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
expts(end).hhmmss = {'105609','132457'};

expts(end+1).yymmdd = '20190531';
expts(end).hhmmss = {'102944','132244'};

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'111420','134538'};

expts(end+1).yymmdd = '20190607';
expts(end).hhmmss = {'103919','133540'};

expts(end+1).yymmdd = '20190610';
expts(end).hhmmss = {'104104','131054'};

%% load data
ttl = {};
ch_mean = [];
ch_var = [];
feature_mean = [];
feature_var = [];
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    for ii=1,%:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        
        % per block
        time_to_targ_pb = cell(1,8);
        success_pb = cell(1,8);
        
        % go through datafiles in fixed blocks
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'Imagined');
        disp(datadir)
        files = dir(fullfile(datadir,'Data*.mat'));

        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_CLDA');
        files = cat(1,files,dir(fullfile(datadir,'Data*.mat')));
        
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_Fixed');
        files = cat(1,files,dir(fullfile(datadir,'Data*.mat')));
        
        for iii=1,
            % load data
            load(fullfile(files(iii).folder,files(iii).name));
            try
                ttl{end+1} = sprintf('%s-%s',yymmdd,hhmmss);
                ch_mean(end+1,:) = TrialData.ChStats.Mean;
                ch_var(end+1,:) = TrialData.ChStats.Var;
                feature_mean(end+1,:) = TrialData.FeatureStats.Mean;
                feature_var(end+1,:) = TrialData.FeatureStats.Var;
            catch
                disp(datadir)
            end
        end
    end
end

N = size(ch_mean,1);

%% look at weights for each channel
figure('units','normalized','Position',[0.2 0.1 0.3 1]);
for i=1:N,
    ax(i)=subplot(N,1,i);
    
    % remove bad channels
    bad_idx = ch_var(i,:) > 2.5e3;
    
    ch_mean_plt = ch_mean(i,:);
    ch_mean_plt(bad_idx) = nan;
    
    ch_var_plt = sqrt(ch_var(i,:));
    ch_var_plt(bad_idx) = 0;
    
    % plot
    errorbar(1:128,ch_mean_plt,ch_var_plt,'.','capsize',0)
    title(ttl{i})
end
linkaxes(ax,'xy')
set(ax,'Xlim',[0,129])
tightfig;

% figure showing variation across days
for i=1:N,
    % remove bad channels
    bad_idx = ch_var(i,:) > 2.5e3;
    ch_mean(i,bad_idx) = nan;
    ch_var(i,bad_idx) = nan;
end
per_change_mean = nanmean(nanmean(100 * diff(ch_mean,1,1) ./ ch_mean(1:end-1,:)))
per_change_std = nanmean(nanstd(100 * diff(ch_mean,1,1) ./ ch_mean(1:end-1,:)))
per_change_mean = nanmean(nanmean(100 * diff(ch_var,1,1) ./ ch_var(1:end-1,:)))
per_change_std = nanmean(nanstd(100 * diff(ch_var,1,1) ./ ch_var(1:end-1,:)))

% %% look at weights for each feature
% FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
%     'BetaPower','LowGammaPower','HighGammaPower'};
% for f=1:7,
%     figure('Position',[689 104 508 870]);
%     for i=1:N,
%         ax(i)=subplot(N,1,i);
%         errorbar(1:128,feature_mean(i,128*(f-1)+(1:128)),feature_var(i,128*(f-1)+(1:128)),'.','capsize',0)
%         title(sprintf('%s: %s',ttl{i},FeatureList{f}))
%     end
%     linkaxes(ax,'xy')
%     tightfig;
% end
