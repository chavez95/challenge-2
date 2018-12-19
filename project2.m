files = dir('audio/*.wav');
listSize = size(files,1);
fileList = strings([listSize 1]);   % create empty array of string

%create file names to use open audio files, that will be evaluated
for i = 1:listSize
        fileList(i) = strcat('audio/' ,string(files(i).name));
end


% deterine whether what each file is music/speech
final = cell(listSize, 2);
result = ones(1,80);
for i = 1:listSize
    % call method to determin whether audio is music or speech.
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% METHOD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % {
    
    % 91% successfull as is
    % Energy analysis
    % Apply a cap to the signal. All signals greater than 0.75 of max
    % amplitude are capped to 0.75 of max amplitude. 
    % Breaks up the signal into m bin
    % applys fft to each bin 
    % calculates engergy of each element in each bin
    % finds the number of bins below a threshold energy
    % if a bin has more than a threshold number of low energy bins it is
    % added to the low energy bin count
    % after analyzing the entire file the file is classified as speech or
    % music depending on the total number of low energy bins found in file.
    % 
    final{i,1} = fileList(i);
    [y,Fs] = audioread(char(fileList(i)));
    y(abs(y) < 0.001)  = 0;
    maxx = max(y);
    y(y > 0.75*maxx) = 0.75*maxx; 
    m = round(size(y,1)/(Fs/9)); % number of bins per data set
    n = round(size(y,1)/m); % number of samples per bin

    ys = reshape(y, [m n]);
    lows = 0;
    high = 0;
    for j = 1:m
        yyf = fft(ys(j,:));
        yyc = (yyf/Fs) .* conj(yyf/Fs);
        minV = sum(yyc)/length(yyc) * 0.503;  % energy threshold    
        ymin = yyc(yyc  < minV);   
        if(size(ymin,2) > 984)                % low energy samples threshold
            lows = lows +1;
        end
    end
    
    result(1,i) = lows;
    
    
    if(lows < 200)                            % low energy bin threshold
        final{i,2} = 1;
    else
        final{i,2} = 0;
    end
   
    % }

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    
    %{
 
    %%%%%%%%%%%%%%%%%%%%% ZERO CROSSING METHOD %%%%%%%%%%%%%%%%%%%%%%%%
    
    % as is 88% success
    
    % Zero crossing count anaylsis
    % Zeroing out y-axis values near 0 helps remove any false zero crossing
    % that may appear due to noise. 
    % Each file is put into bins. There are m bins and each bin contains n
    % data points. 
    % Each bin is passed into a zero crossing detector.
    % If the number of zero crossing found is greater than the crossing
    % threshold, it is counted a high zero crossing bin
    % Music and speech are discrimanted using a threshold on the number of
    % bins with high zero crossing values. 
    
    
    final{i,1} = fileList(i);
    [y,Fs] = audioread(char(fileList(i)));
    y(abs(y) < 0.01)  = 0;  % zeroing noise
    m = round(size(y,1)/(Fs/6)); % number of bins per data set
    n = round(size(y,1)/m); % number of samples per bin
    yy = reshape(y,[m n]);
    zcd = dsp.ZeroCrossingDetector;
    cross = 0;

    zerosF = zeros(1,n);
    for j = 1:m
        yyy = yy(j,:);
        zcdOut = zcd(yyy');
        if(zcdOut > 1250)       % threshold for high zero crossing
           cross = cross + 1; 
        end
    end
    result(1,i) = cross;
    if(cross<177)               % threshold for bin with many high zero crossing bins
        final{i,2} = 1;         % speech tended to have high number of zero crossing bins
    else
        final{i,2} = 0;         % music tended to have high number of zero crossing bins
    end
    %%%%%%%%%%%%%%%%% END OF ZERO CROSSING METHOD %%%%%%%%%%%%%%%%%%%%%%%
    
   %} 
    
    
end

ll= scatter(linspace(1,80,80), result, 'r');
hold on
bthres = plot(linspace(1,80,80), ones(1,80)*200  , 'k');
msSpilt = plot(ones(1,80)*40, linspace(1,300,80), 'b');

xlabel('audio file #')
ylabel('number of low energy bins')
title('Low Energy Frames Results')
legend([ll,bthres,msSpilt],'NUMBER OF LOW ENERGY BINS ','LOW ENERGY BIN THRESHOLD', '<MUSIC FILES|SPEECH FILES>')
save('Resultsfile.mat','final');
