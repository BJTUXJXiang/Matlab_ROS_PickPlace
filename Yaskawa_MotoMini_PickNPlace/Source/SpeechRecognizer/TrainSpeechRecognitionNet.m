%% �[�w�w�K���g�p���������R�}���h�F��

%% �����R�}���h �f�[�^�Z�b�g�̓ǂݍ���
% �f�[�^�Z�b�g��
% https://storage.cloud.google.com/download.tensorflow.org/data/speech_commands_v0.02.tar.gz
% ����_�E�����[�h���𓀁B
tempdir = pwd;
datafolder = fullfile(tempdir,'data_speech_commands_v0.02');
ads = audioDatastore(datafolder, ...
    'IncludeSubfolders',true, ...
    'FileExtensions','.wav', ...
    'LabelSource','foldernames')
ads0 = copy(ads);

%% �F������P��̑I��
% ���f���ɃR�}���h�Ƃ��ĔF��������P����w��B
% commands = categorical(["yes","no","up","down","left","right","on","off","stop","go"]);
commands = categorical(["forward","left","right","stop","go"]);

% ���m�̒P��Ɩ��m�̒P��̕����B
isCommand = ismember(ads.Labels,commands);
isUnknown = ~ismember(ads.Labels,[commands,"_background_noise_"]);

includeFraction = 0.2;
mask = rand(numel(ads.Labels),1) < includeFraction;
isUnknown = isUnknown & mask;
ads.Labels(isUnknown) = categorical("unknown");

% �t�@�C���ƃ��x���݂̂��܂ރf�[�^�X�g�A���쐬�B
ads = subset(ads,isCommand|isUnknown);
countEachLabel(ads)

%% �w�K�Z�b�g�A���؃Z�b�g�A����уe�X�g �Z�b�g�ւ̃f�[�^�̕���
% �f�[�^�X�g�A���w�K�Z�b�g�A���؃Z�b�g�A����уe�X�g �Z�b�g�ɕ����B
[adsTrain,adsValidation,adsTest] = splitData(ads,datafolder);

%% �����X�y�N�g���O�����̌v�Z
% �X�y�N�g���O�����̌v�Z�Ɏg�p����p�����[�^�[���`�B
segmentDuration = 1;
frameDuration = 0.025;
hopDuration = 0.010;
numBands = 40;

% ���炩�ȕ��z�̃f�[�^�𓾂邽�߂ɁA���I�t�Z�b�gepsil�ŃX�y�N�g���O�����̑ΐ������B
epsil = 1e-6;

XTrain = speechSpectrograms(adsTrain,segmentDuration,frameDuration,hopDuration,numBands);
XTrain = log10(XTrain + epsil);

XValidation = speechSpectrograms(adsValidation,segmentDuration,frameDuration,hopDuration,numBands);
XValidation = log10(XValidation + epsil);

XTest = speechSpectrograms(adsTest,segmentDuration,frameDuration,hopDuration,numBands);
XTest = log10(XTest + epsil);

YTrain = adsTrain.Labels;
YValidation = adsValidation.Labels;
YTest = adsTest.Labels;

%% �f�[�^�̉���
% �������̊w�K��ɂ��Ĕg�`�ƃX�y�N�g���O�������v���b�g�B
% specMin = min(XTrain(:));
% specMax = max(XTrain(:));
% idx = randperm(size(XTrain,4),3);
% figure('Units','normalized','Position',[0.2 0.2 0.6 0.6]);
% for i = 1:3
%     [x,fs] = audioread(adsTrain.Files{idx(i)});
%     subplot(2,3,i)
%     plot(x)
%     axis tight
%     title(string(adsTrain.Labels(idx(i))))
% 
%     subplot(2,3,i+3)
%     spect = XTrain(:,:,1,idx(i));
%     pcolor(spect)
%     caxis([specMin+2 specMax])
%     shading flat
% 
%     sound(x,fs)
%     pause(2)
% end

% �w�K�f�[�^�̃s�N�Z���l�̃q�X�g�O�������v���b�g�B
% figure
% histogram(XTrain,'EdgeColor','none','Normalization','pdf')
% axis tight
% ax = gca;
% ax.YScale = 'log';
% xlabel("Input Pixel Value")
% ylabel("Probability Density")

%% �o�b�N�O���E���h �m�C�Y �f�[�^�̒ǉ�
adsBkg = subset(ads0, ads0.Labels=="_background_noise_");
numBkgClips = 4000;
volumeRange = [1e-4,1];

XBkg = backgroundSpectrograms(adsBkg,numBkgClips,volumeRange,segmentDuration,frameDuration,hopDuration,numBands);
XBkg = log10(XBkg + epsil);

% �w�K�Z�b�g�A���؃Z�b�g�A�e�X�g �Z�b�g�ɕ����B
numTrainBkg = floor(0.8*numBkgClips);
numValidationBkg = floor(0.1*numBkgClips);
numTestBkg = floor(0.1*numBkgClips);

XTrain(:,:,:,end+1:end+numTrainBkg) = XBkg(:,:,:,1:numTrainBkg);
XBkg(:,:,:,1:numTrainBkg) = [];
YTrain(end+1:end+numTrainBkg) = "background";

XValidation(:,:,:,end+1:end+numValidationBkg) = XBkg(:,:,:,1:numValidationBkg);
XBkg(:,:,:,1:numValidationBkg) = [];
YValidation(end+1:end+numValidationBkg) = "background";

XTest(:,:,:,end+1:end+numTestBkg) = XBkg(:,:,:,1: numTestBkg);
clear XBkg;
YTest(end+1:end+numTestBkg) = "background";

YTrain = removecats(YTrain);
YValidation = removecats(YValidation);
YTest = removecats(YTest);

% �w�K�Z�b�g�ƌ��؃Z�b�g���̂��܂��܂ȃN���X ���x���̕��z���v���b�g�B
figure('Units','normalized','Position',[0.2 0.2 0.5 0.5]);
subplot(2,1,1)
histogram(YTrain)
title("Training Label Distribution")
subplot(2,1,2)
histogram(YValidation)
title("Validation Label Distribution")

%% �f�[�^�g���̒ǉ�
sz = size(XTrain);
specSize = sz(1:2);
imageSize = [specSize 1];
augmenter = imageDataAugmenter( ...
    'RandXTranslation',[-10 10], ...
    'RandXScale',[0.8 1.2], ...
    'FillValue',log10(epsil));
augimdsTrain = augmentedImageDatastore(imageSize,XTrain,YTrain, ...
    'DataAugmentation',augmenter);

%% �j���[���� �l�b�g���[�N �A�[�L�e�N�`���̒�`
% �V���v���ȃl�b�g���[�N �A�[�L�e�N�`����w�̔z��Ƃ��č쐬�B
% ��ݍ��ݑw�ƃo�b�`���K���w���g�p�B(ReLU)
% �ő�v�[�����O�w��ǉ��B
% �Ō�̑S�����w�ւ̓��͂ɏ��ʂ̃h���b�v�A�E�g��ǉ��B
% �d�ݕt�������G���g���s�[���ޑ������g�p�B

classWeights = 1./countcats(YTrain);
classWeights = classWeights'/mean(classWeights);
numClasses = numel(categories(YTrain));

dropoutProb = 0.2;
numF = 12;
layers = [
    imageInputLayer(imageSize)

    convolution2dLayer(3,numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(3,'Stride',2,'Padding','same')

    convolution2dLayer(3,2*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(3,'Stride',2,'Padding','same')

    convolution2dLayer(3,4*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(3,'Stride',2,'Padding','same')

    convolution2dLayer(3,4*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,4*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer([1 13])

    dropoutLayer(dropoutProb)
    fullyConnectedLayer(numClasses)
    softmaxLayer
    weightedClassificationLayer(classWeights)];

%% �l�b�g���[�N�̊w�K
% Adam �I�v�e�B�}�C�U�[���g�p�B
% �w�K�� 25 �G�|�b�N�s���A20 �G�|�b�N��Ɋw�K���� 10 ���� 1 �ɉ�����B
miniBatchSize = 128;
validationFrequency = floor(numel(YTrain)/miniBatchSize);
options = trainingOptions('adam', ...
    'InitialLearnRate',3e-4, ...
    'MaxEpochs',25, ...
    'MiniBatchSize',miniBatchSize, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress', ...
    'Verbose',false, ...
    'ValidationData',{XValidation,YValidation}, ...
    'ValidationFrequency',validationFrequency, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',20);

doTraining = false;
if doTraining
    trainedNet = trainNetwork(augimdsTrain,layers,options);
    save('trainedNet.mat','trainedNet');
else
    load('trainedNet.mat','trainedNet');
end


%% �w�K�ς݃l�b�g���[�N�̕]��
YValPred = classify(trainedNet,XValidation);
validationError = mean(YValPred ~= YValidation);
YTrainPred = classify(trainedNet,XTrain);
trainError = mean(YTrainPred ~= YTrain);
disp("Training error: " + trainError*100 + "%")
disp("Validation error: " + validationError*100 + "%")

% �����s����v���b�g�B
figure('Units','normalized','Position',[0.2 0.2 0.5 0.5]);
cm = confusionchart(YValidation,YValPred);
cm.Title = 'Confusion Matrix for Validation Data';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
sortClasses(cm, [commands,"unknown","background"])

% ���p�\�ȃ���������ьv�Z���\�[�X�̐������l���B
% info = whos('trainedNet');
% disp("Network size: " + info.bytes/1024 + " kB")
% 
% for i=1:100
%     x = randn(imageSize);
%     tic
%     [YPredicted,probs] = classify(trainedNet,x,"ExecutionEnvironment",'cpu');
%     time(i) = toc;
% end
% disp("Single-image prediction time on CPU: " + mean(time(11:end))*1000 + " ms")

%% �����R�}���h���o�T���v���A�v��
% - �w�K�ς݃��f���Ƃ��� trainedNet.mat ��Ǎ��B
% 1. getCmdMain.m �����s
% 2. "forward","left","right","stop","go" ��F���\�B����ȊO��"unknown"�B
% 3. "unknown" �ȊO�̌��o���ʂ͔g�`�O���t�ɏo�́B
% 4. Figure �̃N���[�Y or "stop" �̔F���ɂ��break�B
edit getCmdMain.m

%% �����R�}���h���o��ROS�m�[�h�Ƃ��Ď���
% ���񃏁[�J�[�Ɋ��蓖�ĂĔ񓯊����s(�}���`�R�A�������I�ɗ��p���邽��)
rosshutdown;
ros_mater_ip = "127.0.0.1";
setenv('ROS_MASTER_URI',"")
setenv('ROS_IP',ros_mater_ip) %�z�X�g����IP�A�h���X
rosinit;
delete(gcp('nocreate'))
p = gcp(); % Get the current parallel pool
f = parfeval(p,@speechRecognizerNode,0,ros_mater_ip,'trainedNet.mat','trainedNet');
wait(f,'running');
rostopic echo /speech_recognizer/speech_results
delete(gcp('nocreate'))
