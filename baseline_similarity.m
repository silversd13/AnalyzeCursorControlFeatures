%% x vs y
clear, clc, close all

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190507';
expts(end).hhmmss = {'105331'};

expts(end+1).yymmdd = '20190510';
expts(end).hhmmss = {'104601','132311'};

expts(end+1).yymmdd = '20190514';
expts(end).hhmmss = {'111822','133050'};

expts(end+1).yymmdd = '20190515';
expts(end).hhmmss = {'105504'};

%% load data
ttl = {};
ch_mean = [];
ch_var = [];
feature_mean = [];
feature_var = [];
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
            'GangulyServer','Center-Out',yymmdd,hhmmss,'Imagined');
        disp(datadir)
        files = dir(fullfile(datadir,'Data*.mat'));

        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_CLDA');
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


%% look at weights for each channel
figure('Position',[681 55 623 919]);
for i=1:5,
    ax(i)=subplot(5,1,i);
    errorbar(1:128,ch_mean(i,:),ch_var(i,:),'.','capsize',0)
    title(ttl{i})
end
tightfig;
linkaxes(ax,'xy')

%% look at weights for each feature
FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};
for f=1:7,
    figure('Position',[681 55 623 919]);
    for i=1:5,
        ax(i)=subplot(5,1,i);
        errorbar(1:128,feature_mean(i,128*(f-1)+(1:128)),feature_var(i,128*(f-1)+(1:128)),'.','capsize',0)
        title(sprintf('%s: %s',ttl{i},FeatureList{f}))
    end
    tightfig;
    linkaxes(ax,'xy')
end
