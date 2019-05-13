function trials = parse_blackrock(anin,Fs)

% get trial structure from anin signal
time = (1:length(anin))/Fs - 1/Fs;

% get upward pulse times
th = 2000;
anin = anin>th;
pulseidx = find(diff(anin)>.5)+1;
pulsetime = time(pulseidx);

% look for groups of pulses
% consolidate (e.g., [5,5,5,5,5,4,4,4,4,4,4,4,4,1] --> [5,4,4,1])
i = 1;
ct = 1;
pulse_groups = [];
group_idx = [];
group_times = [];
while i<length(pulseidx),
    % within group of pulses
    num_pulses = 1;
    while 1,
        if pulsetime(i)==pulsetime(end),
            break;
        elseif (pulsetime(i+1)-pulsetime(i))<.2,
            num_pulses = num_pulses + 1;
            i = i + 1;
        else,
            i = i + 1;
            break;
        end
    end
    if num_pulses==5, % if 5, split into 2 and 3
        pulse_groups(ct) = 2; % time of first pulse
        group_idx(ct) = pulseidx(i-5);
        group_times(ct) = pulsetime(i-5);
        ct = ct + 1;
        
        pulse_groups(ct) = 3; % time of third pulse
        group_idx(ct) = pulseidx(i-3);
        group_times(ct) = pulsetime(i-3);
        ct = ct + 1;
    else, % otherwise, collect time of first pulse
        pulse_groups(ct) = num_pulses; 
        group_idx(ct) = pulseidx(i-num_pulses); 
        group_times(ct) = pulsetime(i-num_pulses); 
        ct = ct + 1;
    end
end

% only look at first session data (imagined mvmts)
idx20 = find(pulse_groups>=20);
start_idx = idx20(1)+1;

pulse_groups    = pulse_groups(start_idx:end);
group_idx       = group_idx(start_idx:end);
group_times     = group_times(start_idx:end);

% trial times
idx1 = find(pulse_groups==1);
trials = [];
for i=1:length(idx1),
    trials(i).start_idx = group_idx(idx1(i));
    trials(i).start_time = group_times(idx1(i));
end

end % parse_blackrock