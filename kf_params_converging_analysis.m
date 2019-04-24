%% check if kalman weights are converging
clear, clc, close all

% load data
datadir = uigetdir();
datafiles = dir(fullfile(datadir,'Data*.mat'));
Ccell = {};
Kcell = [];
alpha = [];
% lambda = [];
bins = 0;
for i=1:length(datafiles),
    % load data, grab neural features
    disp(datafiles(i).name)
    load(fullfile(datadir,datafiles(i).name)) 
    for ii=1:length(TrialData.KalmanFilter),
        Ccell{end+1} = TrialData.KalmanFilter{ii}.C;
        Kcell{end+1} = TrialData.KalmanGain{ii}.K;
    end
    alpha = cat(2,alpha,TrialData.CursorAssist(1));
%     lambda = cat(2,lambda,TrialData.KalmanFilter.Lambda);
    bins = cat(2,bins,bins(end)+length(Ccell));
end
bins = bins(2:end);
C = cat(3,Ccell{:});
K = cat(3,Kcell{:});

%%

figure;
subplot(411);
plot(1:length(alpha),alpha)
ylabel('cursor assist')
title('convergence of KF params')

% subplot(512)
% lambda = [80,80,5000*ones(1,length(alpha)-2)];
% plot(1:length(lambda),lambda)
% ylabel('RML Lambda')


subplot(412)
plot(squeeze(C(:,3,:))')
ylabel('KF.C (xvel)')

subplot(413)
plot(squeeze(C(:,4,:))')
ylabel('KF.C (yvel)')

subplot(414)
plot(squeeze(C(:,5,:))')
ylabel('KF.C (const)')
xlabel('bins')

%%

figure;
subplot(411);
plot(1:length(alpha),alpha)
ylabel('cursor assist')
title('convergence of KF params')

subplot(412)
plot(abs(squeeze(C(:,3,:))'))
ylabel('KF.C (xvel)')

subplot(413)
plot(abs(squeeze(C(:,4,:))'))
ylabel('KF.C (yvel)')

subplot(414)
plot(abs(squeeze(C(:,5,:))'))
ylabel('KF.C (const)')
xlabel('trials')


%%

figure;
subplot(411);
plot(1:length(alpha),alpha)
ylabel('cursor assist')
title('convergence of KF params')

subplot(412)
plot((diff(squeeze(C(:,3,:))')))
ylabel('KF.C (xvel)')

subplot(413)
plot((diff(squeeze(C(:,4,:))')))
ylabel('KF.C (yvel)')

subplot(414)
plot((diff(squeeze(C(:,5,:))')))
ylabel('KF.C (const)')
xlabel('bins')

%% 
s = '/Volumes/FLASH/Bravo1/20190403/GangulyServer/Center-Out/20190403';
s2 = {'105510','111944','135357'};
C = [];
Q = [];
feature = 1;
for ii=1:length(s2),
    datafiles = dir(fullfile(s,s2{ii},'BCI_Fixed','Data0001.mat'));
    % load data, grab neural features
    load(fullfile(s,s2{ii},'BCI_Fixed',datafiles(1).name))
    C = cat(3,C,TrialData.KalmanFilter.C(128*(feature-1)+1:128*feature,3:5));
    Q = cat(3,Q,TrialData.KalmanFilter.Q);
end

%%
figure
ax1 = [];
ax2 = [];
ax3 = [];
for i=1:size(C,3),
    ax1(end+1)=subplot(length(s2),3,3*(i-1)+1);
    stem(C(:,1,i));
    if i==1, title('V_x'); end
    ylabel(sprintf('session %i',i))

    ax2(end+1)=subplot(length(s2),3,3*(i-1)+2);
    stem(C(:,2,i));
    if i==1, title('V_y'); end

    ax3(end+1)=subplot(length(s2),3,3*(i-1)+3);
    stem(C(:,3,i));
    if i==1, title('Constant'); end
end
YY = cell2mat(get(ax1,'YLim'));
YY = [min(YY(:)),max(YY(:))];
set(ax1,'YLim',YY)

YY = cell2mat(get(ax2,'YLim'));
YY = [min(YY(:)),max(YY(:))];
set(ax2,'YLim',YY)

YY = cell2mat(get(ax3,'YLim'));
YY = [min(YY(:)),max(YY(:))];
set(ax3,'YLim',YY)

% compute angle btw first and other C mats
for i=1:size(C,3)-1,
    vx_ang(i) = abs(rad2deg(acos(dot(C(:,1,i),C(:,1,i+1)) ...
        / norm(C(:,1,i)) / norm(C(:,1,i+1)))));
    vy_ang(i) = abs(rad2deg(acos(dot(C(:,2,i),C(:,2,i+1)) ...
        / norm(C(:,2,i)) / norm(C(:,2,i+1)))));
end

vx_ang
vy_ang
