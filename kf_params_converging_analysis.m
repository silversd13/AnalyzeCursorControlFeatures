%% check if kalman weights are converging
clear, clc, close all

% load data
datadir = uigetdir();
datafiles = dir(fullfile(datadir,'Data*.mat'));
Ccell = {};
Pcell = {};
alpha = [];
lambda = [];
TargetID = [];
TargetIDstr = {};
for i=1:length(datafiles),
    % load data, grab neural features
    disp(datafiles(i).name)
    load(fullfile(datadir,datafiles(i).name)) 
    for ii=1:length(TrialData.KalmanFilter),
        Ccell{end+1} = TrialData.KalmanFilter{ii}.C;
        Pcell{end+1} = TrialData.KalmanFilter{ii}.P;
    end
    alpha = cat(2,alpha,TrialData.CursorAssist(1));
    lambda = round(cat(2,lambda,TrialData.KalmanFilter{1}.Lambda),2);
    TargetID = cat(2,TargetID,TrialData.TargetID);
    TargetIDstr{end+1} = int2str(TrialData.TargetID);
end
C = cat(3,Ccell{:});
P = cat(3,Pcell{:});
cc = hsv(8);

%% look at all weights (raw)

figure('position',[296 177 1108 731]);

%%% ---- line plots ---- %%%

% cursor assist
subplot(4,3,1);
plot(1:length(alpha),alpha)
xlim([0,length(datafiles)+1])
ylabel('cursor assist')
title('convergence of KF params')

% X velocity weights
subplot(4,3,4)
plot(squeeze(C(:,3,:))')
xlim([0,length(datafiles)+1])
ylabel('KF.C (xvel)')

% Y velocity weights
subplot(4,3,7)
plot(squeeze(C(:,4,:))')
xlim([0,length(datafiles)+1])
ylabel('KF.C (yvel)')

% constant weights
subplot(4,3,10)
plot(squeeze(C(:,5,:))')
xlim([0,length(datafiles)+1])
ylabel('KF.C (const)')
xlabel('trials')

%%% ---- distribution plots ---- %%%

% colormap
subplot(4,3,2:3); hold on
for t=1:8,
    h = bar(t,1);
    h.FaceColor = cc(t,:);
    h.FaceAlpha = .4;
end
set(gca,'Xtick',1:8,'XLim',[0,9])
title('Target Colormap')

% X velocity weights
subplot(4,3,5:6)
violin(squeeze(C(:,3,:)),'facecolor',cc(TargetID,:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (xvel)')

% Y velocity weights
subplot(4,3,8:9)
violin(squeeze(C(:,4,:)),'facecolor',cc(TargetID,:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (yvel)')

% constant weights
subplot(4,3,11:12)
violin(squeeze(C(:,5,:)),'facecolor',cc(TargetID,:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (const)')
xlabel('trials')

tightfig;

%% look at change in all weights (raw)

figure('position',[296 177 1108 731]);

%%% ---- line plots ---- %%%

% cursor assist
subplot(4,3,1);
plot(1:length(alpha),alpha)
xlim([0,length(datafiles)+1])
ylabel('cursor assist')
title('convergence of KF params')

% X velocity weights
subplot(4,3,4)
plot(diff(squeeze(C(:,3,:)),1,2)')
xlim([0,length(datafiles)+1])
ylabel('KF.C (xvel)')

% Y velocity weights
subplot(4,3,7)
plot(diff(squeeze(C(:,4,:)),1,2)')
xlim([0,length(datafiles)+1])
ylabel('KF.C (yvel)')

% constant weights
subplot(4,3,10)
plot(diff(squeeze(C(:,5,:)),1,2)')
xlim([0,length(datafiles)+1])
ylabel('KF.C (const)')
xlabel('trials')

%%% ---- distribution plots ---- %%%

% colormap
subplot(4,3,2:3); hold on
for t=1:8,
    h = bar(t,1);
    h.FaceColor = cc(t,:);
    h.FaceAlpha = .4;
end
set(gca,'Xtick',1:8,'XLim',[0,9])
title('Target Colormap')

% X velocity weights
subplot(4,3,5:6)
violin(diff(squeeze(C(:,3,:)),1,2),'facecolor',cc(TargetID(1:63),:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (xvel)')

% Y velocity weights
subplot(4,3,8:9)
violin(diff(squeeze(C(:,4,:)),1,2),'facecolor',cc(TargetID(1:63),:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (yvel)')

% constant weights
subplot(4,3,11:12)
violin(diff(squeeze(C(:,5,:)),1,2),'facecolor',cc(TargetID(1:63),:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (const)')
xlabel('trials')

tightfig;

%% look at change in all weights (normalized by starting weights)

figure('position',[296 177 1108 731]);

%%% ---- line plots ---- %%%

% cursor assist
subplot(4,3,1);
plot(1:length(alpha),alpha)
xlim([0,length(datafiles)+1])
ylabel('cursor assist')
title('convergence of KF params')

% X velocity weights
subplot(4,3,4)
plot((diff(squeeze(C(:,3,:)),1,2)./squeeze(C(:,3,1:end-1)))')
xlim([0,length(datafiles)+1])
ylabel('KF.C (xvel)')
ylim([-100,100])

% Y velocity weights
subplot(4,3,7)
plot((diff(squeeze(C(:,4,:)),1,2)./squeeze(C(:,4,1:end-1)))')
xlim([0,length(datafiles)+1])
ylabel('KF.C (yvel)')
ylim([-100,100])

% constant weights
subplot(4,3,10)
plot((diff(squeeze(C(:,5,:)),1,2)./squeeze(C(:,5,1:end-1)))')
xlim([0,length(datafiles)+1])
ylabel('KF.C (const)')
xlabel('trials')
ylim([-100,100])

%%% ---- distribution plots ---- %%%

% colormap
subplot(4,3,2:3); hold on
for t=1:8,
    h = bar(t,1);
    h.FaceColor = cc(t,:);
    h.FaceAlpha = .4;
end
set(gca,'Xtick',1:8,'XLim',[0,9])
title('Target Colormap')

% X velocity weights
subplot(4,3,5:6)
violin((diff(squeeze(C(:,3,:)),1,2)./squeeze(C(:,3,1:end-1))),'facecolor',cc(TargetID(1:63),:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (xvel)')
ylim([-10,10])

% Y velocity weights
subplot(4,3,8:9)
violin((diff(squeeze(C(:,4,:)),1,2)./squeeze(C(:,4,1:end-1))),'facecolor',cc(TargetID(1:63),:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (yvel)')
ylim([-10,10])

% constant weights
subplot(4,3,11:12)
violin((diff(squeeze(C(:,5,:)),1,2)./squeeze(C(:,5,1:end-1))),'facecolor',cc(TargetID(1:63),:),'facealpha',.4,'mc',[],'medc',[]);
xlim([0,length(datafiles)+1])
ylabel('KF.C (const)')
xlabel('trials')
ylim([-10,10])

tightfig;

%% look at change in a few weights (normalized by starting weights)
FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};

figure('position',[292 55 1386 919]);

%%% ---- line plots ---- %%%

% X velocity weights
W = diff(squeeze(C(:,3,:)),1,2)./squeeze(C(:,3,1:end-1));
for i=1:7,
    [m,ch] = sort(mean(W(128*(i-1)+(1:128),:),2));
    idx = 128*(i-1)+ch(end-4:end);
    
    subplot(7,3,1+3*(i-1))
    plot(W(idx,:)')
    xlim([0,length(datafiles)+1])
    ylim([-100,100])
    title(sprintf('%s, chs [%i,%i,%i,%i,%i]',...
        FeatureList{i},ch(1),ch(2),ch(3),ch(4),ch(5)))
end

% Y velocity weights
W = diff(squeeze(C(:,4,:)),1,2)./squeeze(C(:,4,1:end-1));
for i=1:7,
    [m,ch] = sort(mean(W(128*(i-1)+(1:128),:),2));
    idx = 128*(i-1)+ch(end-4:end);
    
    subplot(7,3,2+3*(i-1))
    plot(W(idx,:)')
    xlim([0,length(datafiles)+1])
    ylim([-100,100])
    title(sprintf('%s, chs [%i,%i,%i,%i,%i]',...
        FeatureList{i},ch(1),ch(2),ch(3),ch(4),ch(5)))
end

% constant weights
W = diff(squeeze(C(:,5,:)),1,2)./squeeze(C(:,5,1:end-1));
for i=1:7,
    [m,ch] = sort(mean(W(128*(i-1)+(1:128),:),2));
    idx = 128*(i-1)+ch(end-4:end);
    
    subplot(7,3,3+3*(i-1))
    plot(W(idx,:)')
    xlim([0,length(datafiles)+1])
    ylim([-100,100])
    title(sprintf('%s, chs [%i,%i,%i,%i,%i]',...
        FeatureList{i},ch(1),ch(2),ch(3),ch(4),ch(5)))
end

%% look at change in a few weights (normalized by starting weights)
FeatureList = {'DeltaPhase','DeltaPower','ThetaPower','AlphaPower',...
    'BetaPower','LowGammaPower','HighGammaPower'};

figure('position',[292 55 1386 919]);

%%% ---- line plots ---- %%%

% X velocity weights
W = diff(squeeze(C(:,3,:)),1,2)./squeeze(C(:,3,1:end-1));
for i=1:7,
    [m,ch] = sort(mean(W(128*(i-1)+(1:128),:),2));
    idx = 128*(i-1)+ch(end-4:end);
    
    subplot(7,3,1+3*(i-1))
    plot(W(idx,:)')
    xlim([0,length(datafiles)+1])
    ylim([-2,2])
    title(sprintf('%s, chs [%i,%i,%i,%i,%i]',...
        FeatureList{i},ch(1),ch(2),ch(3),ch(4),ch(5)))
end

% Y velocity weights
W = diff(squeeze(C(:,4,:)),1,2)./squeeze(C(:,4,1:end-1));
for i=1:7,
    [m,ch] = sort(mean(W(128*(i-1)+(1:128),:),2));
    idx = 128*(i-1)+ch(end-4:end);
    
    subplot(7,3,2+3*(i-1))
    plot(W(idx,:)')
    xlim([0,length(datafiles)+1])
    ylim([-2,2])
    title(sprintf('%s, chs [%i,%i,%i,%i,%i]',...
        FeatureList{i},ch(1),ch(2),ch(3),ch(4),ch(5)))
end

% constant weights
W = diff(squeeze(C(:,5,:)),1,2)./squeeze(C(:,5,1:end-1));
for i=1:7,
    [m,ch] = sort(mean(W(128*(i-1)+(1:128),:),2));
    idx = 128*(i-1)+ch(end-4:end);
    
    subplot(7,3,3+3*(i-1))
    plot(W(idx,:)')
    xlim([0,length(datafiles)+1])
    ylim([-2,2])
    title(sprintf('%s, chs [%i,%i,%i,%i,%i]',...
        FeatureList{i},ch(1),ch(2),ch(3),ch(4),ch(5)))
end

%% normalized weight change vs weight

figure('position',[292 55 1386 919]);

%%% ---- scatter plots ---- %%%

% X velocity weights
dW = diff(squeeze(C(:,3,57:64)),1,2)./squeeze(C(:,3,57:end-1));
W = squeeze(C(:,3,57:end-1));

dW = dW(:);
W = W(:);

subplot(2,3,1)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('X velocity')

subplot(2,3,4)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('X velocity')
ylim([-2.5,2.5])

% Y velocity weights
dW = diff(squeeze(C(:,4,57:64)),1,2)./squeeze(C(:,4,57:end-1));
W = squeeze(C(:,4,57:end-1));

dW = dW(:);
W = W(:);

subplot(2,3,2)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('Y velocity')

subplot(2,3,5)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('Y velocity')
ylim([-2.5,2.5])

% constant weights
dW = diff(squeeze(C(:,5,57:64)),1,2)./squeeze(C(:,5,57:end-1));
W = squeeze(C(:,5,57:end-1));

dW = dW(:);
W = W(:);

subplot(2,3,3)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('constant')

subplot(2,3,6)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('constant')
ylim([-2.5,2.5])


%% weight change vs weight

figure('position',[469 229 867 500]);

%%% ---- scatter plots ---- %%%

% X velocity weights
dW = diff(squeeze(C(:,3,57:64)),1,2);
W = squeeze(C(:,3,57:end-1));

dW = dW(:);
W = W(:);

subplot(1,3,1)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('X velocity')

% Y velocity weights
dW = diff(squeeze(C(:,4,57:64)),1,2);
W = squeeze(C(:,4,57:end-1));

dW = dW(:);
W = W(:);

subplot(1,3,2)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('Y velocity')

% constant weights
dW = diff(squeeze(C(:,5,57:64)),1,2);
W = squeeze(C(:,5,57:end-1));

dW = dW(:);
W = W(:);

subplot(1,3,3)
scatter(W,dW)
xlabel('weights')
ylabel('change in weights')
title('constant')






