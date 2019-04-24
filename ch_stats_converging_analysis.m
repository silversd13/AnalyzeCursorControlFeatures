%% check if ch_stats are converging
clear, clc, close all

% load data
datadir = uigetdir();
datafiles = dir(fullfile(datadir,'Data*.mat'));

%% get mean and std of chans and features over trials
mu = [];
sigma = [];
mu1 = [];
sigma1 = [];
mu2 = [];
sigma2 = [];

for i=1:length(datafiles),
    % load data, grab neural features
    load(fullfile(datadir,datafiles(i).name)) %#ok<LOAD>
    mu = cat(1,mu,TrialData.ChStats.mean);
    sigma = cat(1,sigma,sqrt(TrialData.ChStats.var));
    X = cat(1,TrialData.BroadbandData{:});
    mu1 = cat(1,mu1,mean(X));
    sigma1 = cat(1,sigma1,std(X));
    Y = [];
    for ii=1:length(TrialData.NeuralFeatures),
        Ytrial = reshape(TrialData.NeuralFeatures{ii},1,128,[]);
        Y = cat(1,Y,Ytrial);
    end
    mu2 = cat(1,mu2,mean(Y(:,:,2:end))); % ignoring phase feature
    sigma2 = cat(1,sigma2,std(Y(:,:,2:end)));
end

%%
figure;

subplot(221)
plot(mu1)
ylabel('mean')
title('ch stats across trials')

subplot(223)
plot(sigma1)
ylabel('standard dev')
xlabel('trials')

subplot(222)
plot(reshape(mu2,size(mu2,1),[]))
ylabel('mean')
title('feature stats across trials')

subplot(224)
plot(reshape(sigma2,size(sigma2,1),[]))
ylabel('standard dev')
xlabel('trials')



