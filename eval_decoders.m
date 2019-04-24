function [mse_avg,mse_std] = eval_decoders(datadir,B)

%% params
if ~exist('B','var'),
    B = 1;
end
savedir = sprintf('~/Desktop/CV_Kf_Performance_hg_%i00ms_100ms',B);
mkdir(savedir);
feature_mask = 128*6+1:128*7;

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
    Ynew = Ynew(feature_mask,Tidx);
    
    % avg features together
    %Ynew2 = squeeze(mean(reshape(Ynew,128,[],sum(Tidx)),2));

    X{i} = TrialData.CursorState(:,Tidx);
    Y{i} = cat(2,Ynew);
end
dt = 1/TrialData.Params.UpdateRate;

%% try different a and w values
a_vals = [.8,.9,.95];
w_vals = [500,750,1000,1500];

mse_avg = zeros(length(a_vals),length(w_vals),2);
mse_std = zeros(length(a_vals),length(w_vals),2);
for i=1:length(a_vals),
    a = a_vals(i);
    for ii=1:length(w_vals),
        w = w_vals(ii);
        
        % 12-fold cross validation
        K = 12;
        N = round(length(X)/K);
        idx = 1:length(X);
        mse_blocks = zeros(K,2);
        for iii=1:K,
            shift_idx = circshift(idx,-N*(iii-1));
            train_idx = shift_idx(1:(K-1)*N);
            test_idx = shift_idx((K-1)*N+1:end);
            %kf = fit_kf(a,w,dt,cat(2,X{train_idx}),cat(2,Y{train_idx}));
            kf = fit_cv_kf(a,w,dt,cat(2,X{train_idx}),cat(2,Y{train_idx}));
            [mse_blocks(iii,:),X1,X1hat] = eval_kf(kf,X(test_idx),Y(test_idx));
        end
        
        % store mse
        mse_avg(i,ii,:) = mean(mse_blocks);
        mse_std(i,ii,:) = std(mse_blocks);
        
        % output to screen
        fprintf('a:%.2f, w:%i, mse: [%.1f,%.1f]\n',...
            a,w,mse_avg(i,ii,1),mse_avg(i,ii,2))
        
        % generate figure from final fold
        figname = sprintf('kf_performance_imagined_20190403_a-%.2f_w-%i',a,w);
        fig = figure('name',figname);
        
        subplot(2,2,1); % xpos
        plot(X1(1,:)); hold on
        plot(X1hat(1,:),'--')
        title('x-pos')
        
        subplot(2,2,2); % ypos
        plot(X1(2,:)); hold on
        plot(X1hat(2,:),'--')
        title('y-pos')
        
        subplot(2,2,3); % xvel
        plot(X1(3,:)); hold on
        plot(X1hat(3,:),'--')
        title(sprintf('x-vel: mse=%.2f',mse_avg(i,ii,1)))
        
        subplot(2,2,4); % yvel
        plot(X1(4,:)); hold on
        plot(X1hat(4,:),'--')
        title(sprintf('y-vel: mse=%.2f',mse_avg(i,ii,2)))
        
        % save and close fig
        saveas(fig,fullfile(savedir,figname),'png')
        close(fig)
    end
    
end

%% plot mse across a and w vals
[x,y] = meshgrid(w_vals,a_vals);

fig = figure('position',[681 647 934 303]);
subplot(121);
surf(x,y,mse_avg(:,:,1))
xlabel('w')
ylabel('a')
zlabel('mean squared error')
title('Vx')

subplot(122);
surf(x,y,mse_avg(:,:,2))
xlabel('w')
ylabel('a')
zlabel('mean squared error')
title('Vy')

saveas(fig,fullfile(savedir,'perf_across_params'),'png')
close(fig)

%% save mat file w/ data
save(fullfile(savedir,'perf_across_params.mat'),'mse_std','mse_avg','a_vals','w_vals')

end

