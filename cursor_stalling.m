%% cursor stalling
clear, clc

%% data info 
datadir = '/media/dsilver/data/Bravo1/DownsizedTrials';
files = dir(fullfile(datadir,'*BCI_Fixed*.mat')); % fixed blocks
N = length(files);

%% load data
V = [];
Vopt = [];
for n=1:N,
    TrialData = load(fullfile(datadir,files(n).name),...
        'CursorState','IntendedCursorState');
    V       = cat(2,V,   TrialData.CursorState(3:4,:));
    Vopt    = cat(2,Vopt,TrialData.IntendedCursorState(3:4,:));
end

%% get distribution of kalman vel error
Verr = sqrt( (V(1,:) - Vopt(1,:)).^2 + (V(2,:) - Vopt(2,:)).^2 );

% split into quintiles
quintiles = prctile(Verr,[20,80]);

th = quintiles(1);
best_idx = Verr < th;

th = quintiles(2);
worst_idx = Verr > th;

% plot
figure;
histogram(Verr); hold on
histogram(Verr(worst_idx));
histogram(Verr(best_idx));
vline(quintiles);
xlim([125,375])

title('Distribution of Vel Err Over Bins')
xlabel('Error in Velocity (px/bin)')

% look at distribution of intended velocity angles
figure('position',[200 584 714 340]);
suptitle('Distribution of Intended Velocity Angles')
cc = lines(3);

subplot(1,3,1),
polarhistogram(atan2d(Vopt(2,:),Vopt(1,:)),20,'facecolor',cc(1,:))
title('All Time Bins')

subplot(1,3,2),
polarhistogram(atan2d(Vopt(2,worst_idx),Vopt(1,worst_idx)),20,'facecolor',cc(2,:))
title('Worst Time Bins')

subplot(1,3,3),
polarhistogram(atan2d(Vopt(2,best_idx),Vopt(1,best_idx)),20,'facecolor',cc(3,:))
title('Best Time Bins')

% look at distribution of intended velocity angles
figure('position',[200 584 714 340]);
suptitle('Distribution of Decoded Velocity Angles')
cc = lines(3);

subplot(1,3,1),
polarhistogram(atan2d(V(2,:),V(1,:)),20,'facecolor',cc(1,:))
title('All Time Bins')

subplot(1,3,2),
polarhistogram(atan2d(V(2,worst_idx),V(1,worst_idx)),20,'facecolor',cc(2,:))
title('Worst Time Bins')

subplot(1,3,3),
polarhistogram(atan2d(V(2,best_idx),V(1,best_idx)),20,'facecolor',cc(3,:))
title('Best Time Bins')

%% look @ avg high gamma during worst, best, and difference
HG = [];
for n=1:N,
    TrialData = load(fullfile(datadir,files(n).name),...
        'HighGammaPower');
    HG = cat(2,HG,   TrialData.HighGammaPower);
end

% parse based on Verr
best_hg  = HG(:,best_idx);
worst_hg = HG(:,worst_idx);
diff_hg = mean(best_hg,2) - mean(worst_hg,2);

% plot distribution for channel w/ largest diff in mean
[mx,ch] = max(diff_hg);
h(1) = histogram(worst_hg(ch,:)); hold on
h(2) = histogram(best_hg(ch,:));
vline([mean(worst_hg(ch,:),2),mean(best_hg(ch,:),2)])
xlim([-5,10])

xlabel('high gamma pwr (z)')
title(sprintf('Ch%i HG',ch))
legend(h,{'worst','best'})

% plot difference in means (best-worst) on the brain
load('imaging/BRAVO1_rh_pial.mat');
rh = cortex;
load('imaging/BRAVO1_lh_pial.mat');
lh = cortex;
load('imaging/elecs_all.mat');

close all;
figure;
ctmr_gauss_plot(lh, elecmatrix,diff_hg,'lh'); hold on
title(sprintf('hg pwr (best - worst)'))
close(gcf)

% plot mean of best and mean of worst
figure('position',[681 693 976 257]);

ax(1) = subplot(1,2,1);
h(1) = ctmr_gauss_plot(lh, elecmatrix, mean(best_hg,2),'lh'); hold on
title(sprintf('mean hg pwr (best)'))
colorbar;

ax(2) = subplot(1,2,2);
h(2) = ctmr_gauss_plot(lh, elecmatrix, mean(worst_hg,2),'lh'); hold on
title(sprintf('mean hg pwr (worst)'))
colorbar;

close(gcf)


%% repeat analysis for all features during worst, best, and difference
FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};
for i=1:length(FeatureList),
    FeatureStr = FeatureList{i};
    
    % grab feature
    feature = [];
    for n=1:N,
        TrialData = load(fullfile(datadir,files(n).name),...
            FeatureStr);
        feature = cat(2,feature,   TrialData.(FeatureStr));
    end

    % parse based on Verr
    best_feature  = feature(:,best_idx);
    worst_feature = feature(:,worst_idx);
    diff_feature = mean(best_feature,2) - mean(worst_feature,2);

    % plot difference in means (best-worst) on the brain
    figure;
    ctmr_gauss_plot(lh, elecmatrix,diff_feature,'lh'); hold on
    colorbar;
    title(sprintf('%s (best - worst)',FeatureStr))
    
    savefile = sprintf(...
        '~/Desktop/Bravo1_Attention/%s_BestVerrMinusWorstVerr.png',...
        FeatureStr);
    saveas(gcf,savefile,'png');
    close(gcf)

end

%% full analysis for individual days
days = {'20190403','20190417','20190426','20190429','20190501'};
FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};
load('imaging/BRAVO1_lh_pial.mat');
lh = cortex;
load('imaging/elecs_all.mat');
for d=1:length(days),
    day = days{d};
    
    % data info
    datadir = '/media/dsilver/data/Bravo1/DownsizedTrials';
    files = dir(fullfile(datadir,sprintf('%s*BCI_Fixed*.mat',day))); % fixed blocks
    N = length(files);
    
    % get best and worst indices
    V = [];
    Vopt = [];
    for n=1:N,
        TrialData = load(fullfile(datadir,files(n).name),...
            'CursorState','IntendedCursorState');
        V       = cat(2,V,   TrialData.CursorState(3:4,:));
        Vopt    = cat(2,Vopt,TrialData.IntendedCursorState(3:4,:));
    end
    
    % get distribution of kalman vel error
    Verr = sqrt( (V(1,:) - Vopt(1,:)).^2 + (V(2,:) - Vopt(2,:)).^2 );
    
    % split into quintiles
    quintiles = prctile(Verr,[20,80]);
    
    th = quintiles(1);
    best_idx = Verr < th;
    
    th = quintiles(2);
    worst_idx = Verr > th;

    for i=1:length(FeatureList),
        FeatureStr = FeatureList{i};
        
        % grab feature
        feature = [];
        for n=1:N,
            TrialData = load(fullfile(datadir,files(n).name),...
                FeatureStr);
            feature = cat(2,feature,   TrialData.(FeatureStr));
        end
        
        % parse based on Verr
        best_feature  = feature(:,best_idx);
        worst_feature = feature(:,worst_idx);
        diff_feature = mean(best_feature,2) - mean(worst_feature,2);
        
        % plot difference in means (best-worst) on the brain
        figure;
        ctmr_gauss_plot(lh, elecmatrix,diff_feature,'lh'); hold on
        colorbar;
        title(sprintf('%s (best - worst)',FeatureStr))
        
        savefile = sprintf(...
            '~/Desktop/Bravo1_Attention/%s_%s_BestVerrMinusWorstVerr.png',...
            day,FeatureStr);
        saveas(gcf,savefile,'png');
        close(gcf)
        
    end

end % days


%% build a classifier
V = [];
Vopt = [];
for n=1:N,
    TrialData = load(fullfile(datadir,files(n).name),...
        'CursorState','IntendedCursorState');
    V       = cat(2,V,   TrialData.CursorState(3:4,:));
    Vopt    = cat(2,Vopt,TrialData.IntendedCursorState(3:4,:));
end

% get distribution of kalman vel error
Verr = sqrt( (V(1,:) - Vopt(1,:)).^2 + (V(2,:) - Vopt(2,:)).^2 );

% split into quintiles
quintiles = prctile(Verr,[20,80]);

th = quintiles(1);
best_idx = Verr < th;

th = quintiles(2);
worst_idx = Verr > th;

FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};
for i=1:length(FeatureList),
    FeatureStr = FeatureList{i};
    
    % grab feature
    feature = [];
    for n=1:N,
        TrialData = load(fullfile(datadir,files(n).name),...
            FeatureStr);
        feature = cat(2,feature,   TrialData.(FeatureStr));
    end

    % parse based on Verr
    best_feature  = feature(:,best_idx);
    worst_feature = feature(:,worst_idx);
    diff_feature = mean(best_feature,2) - mean(worst_feature,2);

    % build matrices for classifier
    

end