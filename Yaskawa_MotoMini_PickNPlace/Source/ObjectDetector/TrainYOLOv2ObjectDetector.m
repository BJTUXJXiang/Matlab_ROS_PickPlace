%% YOLO v2 ���̌��o��̊w�K

%% ������
clear; close all; clc; rng('default');

%% �摜�f�[�^�̃��[�h
% imageDatastore�ɂ���K�͉摜�̎�舵��
% �C���[�W�u���E�U�[��imageDatastore�̓��e���m�F���邱�Ƃ��\
load DemoDir;
imDir = fullfile(DemoDir,'Source','ObjectDetector','trainingData');
imds = imageDatastore(imDir); % imageDatastore�I�u�W�F�N�g�����p

%% ���x����`�̐���
% ���[�N�̃I�u�W�F�N�g��
labelNames = {'arm_part','t_brace_part','disk_part'};
ldc = labelDefinitionCreator();
for k = 1:numel(labelNames)
    addLabel(ldc,labelNames{k},labelType.Rectangle);
end
labelDefs = create(ldc);
numClasses = numel(labelNames);

%% �A�m�e�[�V�����̓ǂݍ���
d = load(fullfile(DemoDir,'Source','ObjectDetector','trainingData','groundTruthPoses'));
gtArrayForLabelData = permute(reshape(d.groundTruthPoses.bboxesImg',4*3,[]),[2 1]);
labelData = table(gtArrayForLabelData(:,1:4),...
    gtArrayForLabelData(:,5:8),...
    gtArrayForLabelData(:,9:12),...
    'VariableNames',labelNames);

%% groundTruth�I�u�W�F�N�g�̐���
gTruth = groundTruth(groundTruthDataSource(imds.Files),...
    labelDefs,labelData);
save('gTruth','gTruth','imds','labelData');
disp(gTruth);
disp(gTruth.DataSource);

%% Image Labeler�Ŋm�F
% >> imageLabeler;
% �u���x�����C���|�[�g�v���u���[�N�X�y�[�X����v��gTruth��I�����ĊJ��

%% ����
index = 1;
% �F�t���\��
cmaps = im2uint8(jet(width(gTruth.LabelData)));
Iout = imread(gTruth.DataSource.Source{index});
for k = 1: width(gTruth.LabelData)
    bboxes = table2array(gTruth.LabelData(index,k));
    if ~isempty(bboxes{1})
        Iout = insertObjectAnnotation(Iout,'rectangle',bboxes{1},gTruth.LabelDefinitions.Name{k},'Color',cmaps(k,:));
    end
end
figure, imshow(Iout);

%% �o�E���f�B���O�{�b�N�X�̕��z������

% ���ׂẴo�E���f�B���O�{�b�N�X��A��
allBoxes = d.groundTruthPoses.bboxesImg;

% �o�E���f�B���O�{�b�N�X�̖ʐςƃA�X�y�N�g��̃v���b�g
aspectRatio = allBoxes(:,3) ./ allBoxes(:,4);
area = prod(allBoxes(:,3:4),2);

figure
scatter(area,aspectRatio)
xlabel("�o�E���f�B���O�{�b�N�X�̖ʐ�")
ylabel("�A�X�y�N�g�� (width/height)");
title("�ʐ� vs. �A�X�y�N�g��")

%% �N���X�^�����O

% 4�̃O���[�v�ɃN���X�^�����O
numAnchors = 4;

% K-Medoids���g���ăN���X�^�����O
[clusterAssignments, anchorBoxes, sumd] = kmedoids(allBoxes(:,3:4),numAnchors,'Distance',@iouDistanceMetric);

% �N���X�^�����O�������σA���J�[�{�b�N�X�̃T�C�Y
disp(anchorBoxes);

% �N���X�^�����O���ʂ̃v���b�g
figure
gscatter(area,aspectRatio,clusterAssignments);
title("K-Mediods��"+numAnchors+"�N���X�^�����O")
xlabel("�ʐ�")
ylabel("�A�X�y�N�g�� (width/height)");
grid

% �ݐω��Z
counts = accumarray(clusterAssignments, ones(length(clusterAssignments),1),[],@(x)sum(x)-1);

% ����IoU���v�Z
meanIoU = mean(1 - sumd./(counts));
disp("����IoU : " + meanIoU);

%% �A���J�[�{�b�N�X�̐��ƕ���IoU�̊֌W
% �A���J�[�{�b�N�X�𑝂₷�ƕ���IoU�͉��P���邪�v�Z�ʂ͑���
% �O���t�����k=4���o�����X���悳����

% 1����15�܂ŃA���J�[�{�b�N�X�𑝂₵���Ƃ��ɕ���IoU�̉��P���ǂ��Ȃ邩
maxNumAnchors = 15;
for k = 1:maxNumAnchors
    
    % Estimate anchors using clustering.
    [clusterAssignments, ~, sumd] = kmedoids(allBoxes(:,3:4),k,'Distance',@iouDistanceMetric);
    
    % ����IoU���v�Z
    counts = accumarray(clusterAssignments, ones(length(clusterAssignments),1),[],@(x)sum(x)-1);
    meanIoU(k) = mean(1 - sumd./(counts));
end

figure
plot(1:maxNumAnchors, meanIoU,'-o')
ylabel("����IoU")
xlabel("�A���J�[��")
title("�A���J�[�� vs. ����IoU")

%% �w�K�p�̃e�[�u���ɕϊ�

trainingDataset = objectDetectorTrainingData(gTruth);

% �Č������m�ۂ��邽�߂ɗ����̃V�[�h�����l�ɂ���
rng(0);

% �����_���ɕ���
shuffledIndices = randperm(height(trainingDataset));
idx = floor(0.9 * length(shuffledIndices) );
trainingData = trainingDataset(shuffledIndices(1:idx),:);
testData = trainingDataset(shuffledIndices(idx+1:end),:);

%% �w�K�̏���(YOLO v2)

% �O�i�̓������o�Ɏg���w�K�ς݃��f��
network = resnet50();

% �������o�Ƃ��Ďg�����C���[���w��
featureLayer = 'activation_40_relu';

% ���͉摜�T�C�Y
imageSize = network.Layers(1).InputSize;

% YOLO v2���̌��o�l�b�g���[�N���`
lgraph = yolov2Layers(imageSize, numClasses, round(anchorBoxes), ...
    network, featureLayer);

% �l�b�g���[�N����
analyzeNetwork(lgraph)

options = trainingOptions('sgdm', ...
    'InitialLearnRate', 0.001, ...
    'Verbose', true, 'MiniBatchSize', 16, 'MaxEpochs', 50,...
    'Shuffle', 'every-epoch', 'VerboseFrequency', 1);

%% �w�K
rng('default');
tic;
[detector,info] = trainYOLOv2ObjectDetector(trainingData,lgraph,options);
toc
figure
plot(info.TrainingLoss)
grid on
xlabel('�J��Ԃ���')
ylabel('�����֐��̒l')
save('trainedYOLOv2Detector','detector','info');

%% ���_

I = imread(trainingData.imageFilename{251});

% ���o������s
[bboxes, scores, labels] = detect(detector, I);
[~,ind] = ismember(labels,gTruth.LabelDefinitions.Name);

% ���ʂ̉���
detectedImg = insertObjectAnnotation(I, 'Rectangle', bboxes, cellstr(labels),...
    'Color',cmaps(ind,:));

figure
imshow(detectedImg)

%% ���\�]�� 
numImages = height(testData);
results = table('Size',[numImages 3],...
    'VariableTypes',{'cell','cell','cell'},...
    'VariableNames',{'Boxes','Scores','Labels'});

% ���o���S�e�X�g�f�[�^�ɑ΂��Ď��s
for i = 1:numImages
    
    % �摜�ǂݍ���
    I = imread(testData.imageFilename{i});
    
    % ���o������s
    [bboxes,scores,labels] = detect(detector,I);
   
    % ���ʂ̊i�[
    results.Boxes{i} = bboxes;
    results.Scores{i} = scores;
    results.Labels{i} = labels;
end

% �e�X�g�f�[�^����^�l�̃o�E���f�B���O�{�b�N�X�����o��
expectedResults = testData(:, 2:end);

% ���ϓK�����A�Č����A�K������]��
[ap, recall, precision] = evaluateDetectionPrecision(results, expectedResults);

% �K����/�Č���(PR) �Ȑ����v���b�g
figure
hold on;
for k = 1:numel(recall)
    plot(recall{k},precision{k});
end
xlabel('�Č���')
ylabel('�K����')
grid on
legend(labelNames,'Interpreter','none');
title(sprintf('���ϓK���� = %.2f ', mean(ap)))

%% �T�|�[�g�֐�
function dist = iouDistanceMetric(boxWidthHeight,allBoxWidthHeight)
% Return the IoU distance metric. The bboxOverlapRatio function
% is used to produce the IoU scores. The output distance is equal
% to 1 - IoU.

% Add x and y coordinates to box widths and heights so that
% bboxOverlapRatio can be used to compute IoU.
boxWidthHeight = prefixXYCoordinates(boxWidthHeight);
allBoxWidthHeight = prefixXYCoordinates(allBoxWidthHeight);

% Compute IoU distance metric.
dist = 1 - bboxOverlapRatio(allBoxWidthHeight, boxWidthHeight);
end

function boxWidthHeight = prefixXYCoordinates(boxWidthHeight)
% Add x and y coordinates to boxes.
n = size(boxWidthHeight,1);
boxWidthHeight = [ones(n,2) boxWidthHeight];
end

%% �I��
% Copyright 2019 The MathWorks, Inc.
