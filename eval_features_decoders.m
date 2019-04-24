function [mse_avg] = eval_features_decoders(datadir,B)

%% params
if ~exist('B','var'),
    B = 1;
end
savedir = sprintf('~/Desktop/Kf_Performance_AcrossFeatures_%i00ms_100ms',B);
mkdir(savedir);

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
Y = {}; % neural features
for i=1:length(files),
    load(fullfile(datadir,files{i}));
    
    % get reach target data
    T = TrialData.Time;
    idx = strcmp({TrialData.Events(:).Str},'Reach Target');
    Tidx = T > TrialData.Events(idx).Time;
    Ytrial = cat(2,TrialData.NeuralFeatures{:,:});
    
    % moving avg
    win = 1/B * ones(1,B);
    Ynew = zeros(size(Ytrial));
    for ii=1:size(Ytrial,1),
        Ynew(ii,:) = conv(circshift(Ytrial(ii,:),B-1),win,'same');
    end
    
    Ytrial = Ytrial(:,Tidx);
    Ynew = Ynew(:,Tidx);

    X{i} = TrialData.CursorState(:,Tidx);
    Y{i} = cat(2,Ynew(:,:));
end
dt = 1/TrialData.Params.UpdateRate;

%% try different a and w values
a = .8;
w = 750;

feature_strs = {'delta_ph','delta_pwr','theta_pwr','alpha_pwr',...
    'beta_pwr','lg_pwr','hg_pwr'};
num_features = 7;
mse_avg = cell(1,2^num_features-1);
mse_feature_idx = cell(1,2^num_features-1);
mse_feature_str = cell(1,2^num_features-1);
for i=1:2^num_features-1, % all feature combinations
    
    % select features to use
    feature_idx = strfind(dec2bin(i,7),'1');
    feature_mask = [];
    feature_str = '';
    for ii=1:length(feature_idx),
        feature_mask = cat(2,feature_mask, ...
            128*(feature_idx(ii)-1)+1:128*feature_idx(ii));
        feature_str = cat(2,feature_str,'_',feature_strs{feature_idx(ii)});
    end
        
    % 12-fold cross validation
    K = 12;
    N = round(length(X)/K);
    idx = 1:length(X);
    mse_blocks = zeros(K,2);
    for ii=1:K,
        shift_idx = circshift(idx,N*(ii-1));
        train_idx = shift_idx(1:(K-1)*N);
        test_idx = shift_idx((K-1)*N+1:end);
        kf = fit_cv_kf2(a,w,dt,cat(2,X{train_idx}),cat(2,Y{train_idx}),feature_mask);
        [mse_blocks(ii,:),X1,X1hat] = eval_kf2(kf,X(test_idx),Y(test_idx),feature_mask);
    end
        
    % store mse
    mse_avg{i} = mean(mse_blocks);
    mse_feature_idx{i} = feature_idx;
    mse_feature_str{i} = feature_str;
    
    % output to screen
    fprintf('features: %s: ',mse_feature_str{i})
    disp(mse_feature_idx{i})
    fprintf('  mse: [%.1f,%.1f]\n',...
        mse_avg{i}(1),mse_avg{i}(2))
        
end

%% plot mse across a and w vals
MSE = cat(1,mse_avg{:});

fig = figure('position',[677 191 944 756]);

subplot(3,1,1);
stem(MSE(:,1))
ylabel('MSE')
title('Vx')

subplot(3,1,2);
stem(MSE(:,2))
ylabel('MSE')
title('Vy')

plt_features = zeros(7,127);
for i=1:127,
    idx = mse_feature_idx{i};    
    plt_features(idx,i) = 1;
end
subplot(3,1,3); hold on
imagesc(plt_features)
set(gca,'YTick',1:7,'YTickLabel',feature_strs)

saveas(fig,fullfile(savedir,'perf_across_features'),'png')
close(fig)

%% save mat file w/ data
save(fullfile(savedir,'perf_across_features.mat'),...
    'mse_avg','mse_feature_idx','mse_feature_str')

end

