%% ROS�A�g�ɂ��w�K�摜�̎��W
% Robotics System Toolbox�Œ񋟂���ROS�A�g�@�\

%% ������
clear; close all force; clc;

%% ROS�ɐڑ�
rosshutdown;
rosinit('192.168.115.130','NodeHost','192.168.115.1');

%% 3�����_�Q���擾���邽�߂̃T�u�X�N���C�o�[���`
%ptsub = rossubscriber('/kinect2/sd/points');
%receive(ptsub);
imSub = rossubscriber('/kinect2/sd/image_color');
receive(imSub);

%% �_�Q���擾
%ptMsg = receive(ptsub);
%ptMsg.PreserveStructureOnRead = true;
% ���炩���ߕۑ����Ă���_�Q���g���ꍇ
% load ptMsg;

%% �擾�����摜�̉���
testIm = readImage(receive(imSub));
figure, imshow(testIm);

%% Kinect2�̎p�����擾
tftree = rostf;
pause(1);
tf = getTransform(tftree,'world','kinect2_rgb_optical_frame');

% tf�I�u�W�F�N�g����ϊ��s����쐬
tr = tf.Transform.Translation;
quat = tf.Transform.Rotation;
p = [tr.X tr.Y tr.Z];
q = [quat.W, quat.X, quat.Y, quat.Z];
rotm = quat2rotm(q);

% ���[���h���W�n���_���烍�{�b�g�A�[����
% ���_�t���[��(world)�ւ̃I�t�Z�b�g��ǉ�
p(3) = p(3) + 1.02;

%% Kinect2�̓����p�����[�^�[�ƊO���p�����[�^���Z�b�g
horizontal_fov = 84.1*pi/180.0;
width = 512;
height = 424;
f = width/(2*tan(horizontal_fov/2));
IntrinsicMatrix = [f 0 0; 0 f 0; width/2 height/2 1];
cameraParams = cameraParameters('IntrinsicMatrix',IntrinsicMatrix);
[rotationMatrix,translationVector] = cameraPoseToExtrinsics(rotm',p);

%% Gazebo��̃��[�N�p�����擾���摜��Ƀo�E���f�B���O�{�b�N�X�\��
% Gazebo�̃I�u�W�F�N�g���擾
gazebo = ExampleHelperGazeboCommunicator();

%% Gazebo�̕����G���W���̐ݒ�ύX
realTimeFactor = 5;
pauseSim(gazebo);
phys = readPhysics(gazebo);
phys.TimeStep = realTimeFactor/phys.UpdateRate;
setPhysics(gazebo,phys);
resumeSim(gazebo);

%% �I�u�W�F�N�g����]�����Ȃ���w�K�摜���擾
% Gazebo��̃{�[���̈ʒu��p����MATLAB����ύX�\

% �摜�̕ۑ��t�H���_
load('DemoDir');
imDir =  fullfile(DemoDir,'Source','ObjectDetector','trainingData');
winopen(imDir)
[~,~,~] = mkdir(imDir);

% �\���p�̃v���C���[
videoPlayer = vision.DeployableVideoPlayer;

% ���[�N�̃I�u�W�F�N�g��
targets = {'arm_part','t_brace_part','disk_part'};

% ���[�N���͂�3D�̃o�E���f�B���O�{�b�N�X
bboxes = [-0.05 0.05 -0.07 0.03 -0.01 0.04;
    -0.02 0.11 -0.06 0.06 -0.01 0.02;
    -0.04 0.04 -0.04 0.04 -0.01 0.03];

% 3D�o�E���f�B���O�{�b�N�X�𒸓_���W�ɕϊ�
vertices = zeros(8,3,3);
for k = 1:numel(targets)
    [xrange,yrange,zrange] = meshgrid(bboxes(k,1:2),bboxes(k,3:4),bboxes(k,5:6));
    vertices(:,:,k) = [xrange(:),yrange(:),zrange(:)];
end

% ���[�N�̏����ʒu�p�����擾���A�ێ�
% (��ʒu���痎�������Ċw�K�f�[�^�����邽��)
posOrg = zeros(numel(targets),3);
oriOrg = zeros(numel(targets),3);
for l = 1:numel(targets)
    model = ExampleHelperGazeboSpawnedModel(targets{l},gazebo);
    [pos, ori, vel] = getState(model);
    posOrg(l,:) = pos;
    oriOrg(l,:) = ori;
end
posOrg(:,3) = posOrg(:,3) + 0.1; % ���������ė��Ƃ�
velocity.Linear = [0,0,0];
velocity.Angular = [0,0,0];

% ��]�̃p�^�[���𐶐�
numAngles = 8-1;
angles = linspace(0,2*pi,numAngles+1);
[r,p,y] = meshgrid(angles,angles,angles);
r = r(:); p = p(:); y = y(:);

% �p����ground truth�ۑ��ptable
groundTruthPoses = table;

% �p����ς��Ȃ���w�K�f�[�^�𐶐�
for k = 1:numel(r)
    % �p����ς���
    orientation = [r(k), p(k), y(k)];
    for l = 1:numel(targets)
        model = ExampleHelperGazeboSpawnedModel(targets{l},gazebo);
        setState(model,'position',posOrg(l,:),...
            'velocity',velocity,...
            'orientation',orientation);
    end
    
    % �p������������܂ő҂�
    pause(5);
    
    % �摜���擾
    testIm = readImage(receive(imSub));
    testImOut = testIm;
    
    % �p�����擾
    bboxesImg = zeros(numel(targets),4);
    positions = zeros(numel(targets),3);
    orientations = zeros(numel(targets),3);
    for l = 1:numel(targets)
        model = ExampleHelperGazeboSpawnedModel(targets{l},gazebo);
        [pos, ori, vel] = getState(model);
        positions(l,:) = pos;
        orientations(l,:) = ori;
    end
    
    % �擾�����p������3D�o�E���f�B���O�{�b�N�X�̒��_���W���v�Z
    % �܂��A2D�̃o�E���f�B���O�{�b�N�X�Ɏˉe
    for l = 1:numel(targets)
        vert = positions(l,:) + vertices(:,:,l)*(eul2rotm(deg2rad(orientations(l,:)))');
        imagePoints = worldToImage(cameraParams,rotationMatrix,translationVector,vert);
        minPts = min(imagePoints);
        maxPts = max(imagePoints);
        bbox = [minPts maxPts-minPts];
        bboxesImg(l,:) = bbox;
        testImOut = insertMarker(testImOut,imagePoints);
        testImOut = insertShape(testImOut,'rectangle',bbox);
    end
    
    % �^�l��ۑ�
    groundTruthPoses = [groundTruthPoses;
        table(bboxesImg,positions,orientations)];
    
    pause(1);
    
    % �擾�����摜�ƃo�E���f�B���O�{�b�N�X������
    videoPlayer(testImOut);
    
    % �摜��ۑ�
    imwrite(testIm,fullfile(imDir,['image_' sprintf('%05d',int32(k)) '.png'])); % �ۑ�����Ƃ�
end
save(fullfile(imDir,'groundTruthPoses.mat'),'groundTruthPoses');

%% �擾�摜�̕\��
% �C���[�W�u���E�U�ŉ摜�m�F
% �F�̂������l�A�v���P�[�V�������N������
% �P���Ȃ������l�ɂ��Z�O�����e�[�V����������
imageBrowser(imDir);

%%
% Copyright (c) 2019, MathWorks, Inc.
