function [mse_avg] = eval_channels_greedy_down_decoders(datadir)

%% params
savedir = sprintf('~/Desktop/Kf_Performance_AcrossChannels_100ms_100ms');
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

    X{i} = TrialData.CursorState(:,Tidx);
    Y{i} = cat(2,Ytrial(6*128+1:7*128,Tidx)); % only high gamma
end
dt = 1/TrialData.Params.UpdateRate;

%% use greedy alg to increase channels
a = .8;
w = 750;

num_channels = 128;
mse_avg = zeros(1,num_channels);
mse_channel_idx = cell(1,num_channels);

best_decode_channels = 1:128; %  list of channels to use in decoder (in greedy order)
curr_decode_channels = 1:128; % current list

for i=1:num_channels, % all feature combinations
    
    % go through remaining chs, one at a time
    best_ch = 0;
    best_mse = inf;
    for ch=best_decode_channels,
        curr_decode_channels = setdiff(best_decode_channels, ch);
        
        % 12-fold cross validation
        K = 12;
        N = round(length(X)/K);
        idx = 1:length(X);
        mse_blocks = zeros(K,2);
        for ii=1:K,
            shift_idx = circshift(idx,N*(ii-1));
            train_idx = shift_idx(1:(K-1)*N);
            test_idx = shift_idx((K-1)*N+1:end);
            
            kf = fit_cv_kf3(a,w,dt,cat(2,X{train_idx}),cat(2,Y{train_idx}),curr_decode_channels);
            [mse_blocks(ii,:),X1,X1hat] = eval_kf3(kf,X(test_idx),Y(test_idx),curr_decode_channels);
        end
        
        % keep track of best ch
        mse_channels = mean(mean(mse_blocks));
        if mse_channels < best_mse,
            best_mse = mse_channels;
            best_ch = ch;
        end
        
    end
    
    % store mse
    mse_avg(i) = best_mse;
    best_decode_channels = setdiff(best_decode_channels, best_ch);
    mse_channel_idx{i} = best_decode_channels;
    
    % output to screen
    disp(mse_channel_idx{i})
    fprintf('  mse: %.1f\n',best_mse)
    
end

%% plot mse across a and w vals
fig = figure('position',[677 191 944 756]);

subplot(2,1,1);
plot(1:128,mse_avg)
ylabel('MSE (Vx and Vy)')
xlabel('num channels')
title('Decoder Performance')

plt_channels = zeros(128,127);
for i=1:128,
    idx = mse_channel_idx{i};    
    plt_channels(idx,i) = 1;
end
subplot(2,1,2); hold on
imagesc(plt_channels)
xlabel('num channels')
ylabel('channels')
title('Channel Key')

saveas(fig,fullfile(savedir,'perf_across_channels_greedy_down'),'png')
close(fig)

%% save mat file w/ data
save(fullfile(savedir,'perf_across_channels_greedy_down.mat'),...
    'mse_avg','mse_channel_idx','plt_channels')

end

