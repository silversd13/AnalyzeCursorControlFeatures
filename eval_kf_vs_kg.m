function [mse_kf,mse_kg] = eval_kf_vs_kg(datadir)

%% data dir
if ~exist('datadir','var'),
    % ask user for files
    [files,datadir] = uigetfile('*.mat','Select the INPUT DATA FILE(s)','MultiSelect','on');
    if ~iscell(files),
        tmp = files;
        clear files;
        files{1} = tmp;
        clear tmp;
    end
else,
    tmp = dir(fullfile(datadir,'Data*.mat'));
    for i=1:length(tmp),
        files{i} = tmp(i).name;
    end
end
disp(datadir)
disp(files{1})
disp(files{end})

%% load data
X = {}; % cursor state
Z = {}; % intended cursor state
Y = {}; % neural features
for i=1:length(files),
    load(fullfile(datadir,files{i}));
    
    % get reach target data
    T = TrialData.Time;
    idx = strcmp({TrialData.Events(:).Str},'Reach Target');
    Tidx = T > TrialData.Events(idx).Time;
    Ytrial = cat(2,TrialData.NeuralFeatures{:,:});
    
    X{i} = TrialData.CursorState(:,Tidx);
    Z{i} = TrialData.IntendedCursorState(:,Tidx);
    Y{i} = cat(2,Ytrial(:,Tidx));
end
dt = 1/TrialData.Params.UpdateRate;

%% eval kf and kg for different bins
for bins=1:50,
    [mse_kf,mse_kg{bins}] = eval_kg_decoder(bins,X,Z);
end
bins = 1:50;
mse = cat(2,mse_kg{:});

%% make plots
figure('position',[681 666 882 284]);

subplot(1,2,1); hold on
plot(bins,mse(1,:))
plot(bins,repmat(mse_kf(1),1,length(bins)),'--k')
xlabel('# kf vel bins used')
ylabel('mean squared error')
title('Vx')

subplot(1,2,2); hold on
plot(bins,mse(2,:))
plot(bins,repmat(mse_kf(2),1,length(bins)),'--k')
xlabel('# kf vel bins used')
ylabel('mean squared error')
title('Vy')

datadir_str = strsplit(datadir,'/');
yymmdd = datadir_str{9};
hhmmss = datadir_str{10};
saveas(gcf,sprintf('~/Desktop/%s_%s_kg_decoder.png',yymmdd,hhmmss))
close(gcf)

end

