function neural_features = compute_features(BroadbandData,Features,BinSize,NumBins),

% unique pwr feature + all phase features
FilterBank = ConstructFilterBank(Features);
NumBuffer = sum([FilterBank.buffer_flag]);
NumHilbert = sum([FilterBank.hilbert_flag]);
NumPhase = sum([FilterBank.phase_flag]);
NumPower = length(unique([FilterBank.feature]));
NumFeatures = NumPower + NumPhase;

% filter data
filtered_data = ApplyFilterBank(BroadbandData,FilterBank);

% first compute hilbert for low freq bands
H = hilbert(filtered_data(:,:,1:NumHilbert));

% compute pwr in low freq bands based on hilbert (only keep last bin)
hilb_pwr = abs(H); % [samples x channels x freqs]
pwr1 = log10(hilb_pwr); % [samples x channels x freqs]

% compute average pwr for all remaining freq bands in last bin
pwr2 = log10(filtered_data(:,:,NumBuffer+1:end).^2); % [samples x channels x freqs]

% bin features according to BinSize
pwr1_binned = zeros(NumBins,size(pwr1,2),size(pwr1,3));
pwr2_binned = zeros(NumBins,size(pwr1,2),size(pwr2,3));
for i=1:NumBins,
    pwr1_binned(i,:,:) = mean(pwr1(BinSize*(i-1)+1:BinSize*(i),:,:),1);
    pwr2_binned(i,:,:) = mean(pwr2(BinSize*(i-1)+1:BinSize*(i),:,:),1);
end

% combine feature vectors and remove singleton dimension
pwr = cat(3,pwr1_binned,pwr2_binned);
feature_idx = [FilterBank.feature];
for i=(NumPhase+1):NumFeatures,
    idx = feature_idx == i;
    neural_features(i,:) = reshape(mean(pwr,3),1,[]);
end

% vectorize
neural_features = reshape(neural_features',[],1);

end % CompNeuralFeatures

function filtered_data = ApplyFilterBank(BroadbandData,FilterBank)
BroadbandData = BroadbandData';
[samps, chans] = size(BroadbandData);
filtered_data = zeros(samps,chans,length(FilterBank));

% apply each filter and track filter state
for i=1:length(FilterBank),
    filtered_data(:,:,i) = ...
        filter(...
        FilterBank(i).b, ...
        FilterBank(i).a, ...
        BroadbandData);
end

end % ApplyFilterBank

function FilterBank = ConstructFilterBank(features)
FilterBank = [];
ct = 1;

if any(strcmp(features,'delta')),
    FilterBank(end+1).fpass = [.5,4];    % delta
    FilterBank(end).buffer_flag = true;
    FilterBank(end).hilbert_flag = true;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    ct = ct + 1;
end

if any(strcmp(features,'theta')),
    FilterBank(end+1).fpass = [4,8];     % theta
    FilterBank(end).buffer_flag = true;
    FilterBank(end).hilbert_flag = true;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    ct = ct + 1;
end

if any(strcmp(features,'alpha')),
    FilterBank(end+1).fpass = [8,13];    % alpha
    FilterBank(end).buffer_flag = true;
    FilterBank(end).hilbert_flag = true;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    ct = ct + 1;
end

if any(strcmp(features,'beta')),
    FilterBank(end+1).fpass = [13,19];   % beta1
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [19,30];   % beta2
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    ct = ct + 1;
end

if any(strcmp(features,'low_gamma')),
    FilterBank(end+1).fpass = [30,36];   % low gamma1
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [36,42];   % low gamma2
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [42,50];   % low gamma3
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    ct = ct + 1;
end

if any(strcmp(features,'high_gamma')),
    FilterBank(end+1).fpass = [70,77];   % high gamma1
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [77,85];   % high gamma2
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [85,93];   % high gamma3
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [93,102];  % high gamma4
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [102,113]; % high gamma5
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [113,124]; % high gamma6
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [124,136]; % high gamma7
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    
    FilterBank(end+1).fpass = [136,150]; % high gamma8
    FilterBank(end).buffer_flag = false;
    FilterBank(end).hilbert_flag = false;
    FilterBank(end).phase_flag = false;
    FilterBank(end).feature = ct;
    ct = ct + 1;
end

% compute filter coefficients
Fs = 1000;
for i=1:length(FilterBank),
    [b,a] = butter(3,FilterBank(i).fpass/(Fs/2));
    FilterBank(i).b = b;
    FilterBank(i).a = a;
end


end % ConstructFilterBank
