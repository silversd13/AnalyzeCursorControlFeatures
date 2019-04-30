function neural_features = compute_features(BroadbandData,FilterBank,BinSize,NumBins),

% unique pwr feature + all phase features
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

