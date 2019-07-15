%% ���o���̂�3�����ʒu�擾�ƃ��{�b�g���W�n�ւ̕ϊ�
%% ������

clear; close all force; clc; bdclose all;
useGazebo = true;
%% ROS�m�[�h�o�^

if useGazebo
    rosshutdown;
    rosinit('192.168.115.130','NodeHost','192.168.115.1');
end
%% 3�����_�Q���擾���邽�߂̃T�u�X�N���C�o�[���`

if useGazebo
    ptSub = rossubscriber('/kinect2/sd/points');
    receive(ptSub); % dummy call
end
%% �_�Q���擾

if useGazebo
    ptMsg = receive(ptSub);
    ptMsg.PreserveStructureOnRead = true; % Keep organized point cloud
    clear ptSub;
else
    % ���炩���ߕۑ����Ă���_�Q���g���ꍇ
    load ptMsg;
end
%% �_�Q����摜�f�[�^�̒��o

I = readRGB(ptMsg);
figure, imshow(I);
%% �_�Q����[�x�f�[�^�̒��o

xyz = readXYZ(ptMsg);
figure, imagesc(xyz(:,:,3));
colorbar;truesize;
%% 3�����_�Q�Ƃ��ĕ\��
% pcfitsphere�Ȃǂŋ��̃t�B�b�e�B���O���\

pc = pointCloud(xyz,'Color',I);
hFig = figure;
h = pcshow(pc,'VerticalAxis','Y','VerticalAxisDir','Down');
xlabel('X(m)'),ylabel('Y(m)'),zlabel('Z(m)');
axis([-0.5 0.5 -0.4 0.2 0.5 1]);
hFig.Color = [0.5 0.5 0.5];
h.Color = [0.5 0.5 0.5];
%% Kinect���W�n���烍�{�b�g���W�n�ւ̕ϊ��s��擾
% �ϊ����W�̎擾��ROS tf���g��

tftree = rostf;
pause(1);
tf = getTransform(tftree,'world','kinect2_rgb_optical_frame');

% ���炩���ߕۑ����Ă���tf(transform stamped)���g���ꍇ
% load tfSaved

% tf�I�u�W�F�N�g����ϊ��s����쐬
tr = tf.Transform.Translation;
quat = tf.Transform.Rotation;
p = [tr.X tr.Y tr.Z];
q = [quat.W, quat.X, quat.Y, quat.Z];
rotm = quat2rotm(q);
b_T_k = trvec2tform(p)*rotm2tform(rotm)
% Simulink���f���Ŏg���̂ŕۑ����Ă���
% save('params','b_T_k');
%% MotoMini���c���[�\�����{�b�g�Ƃ��ĕ\��

modelName = 'motominiPlanning';
motomini = createMotomini();
restConfig = motomini.homeConfiguration;
hFig2 = figure;
h2 = show(motomini,restConfig,'Frame','on');
hold on;
alpha 0.1;
EELinkName = 'gripper_EE_link';
axis([-0.5 0.5 -0.5 0.5 -0.1 0.5]);
view(45,45)
motominiParams = setMotominiParameters('',motomini);
%% �_�Q�̍��W�ϊ�

pc_b = pctransform(pc,affine3d(b_T_k'));
set(gcf,'Visible','on')
pcshow(pc_b);
xlabel('X(m)'),ylabel('Y(m)'),zlabel('Z(m)');
axis([-0.5 0.5 -0.5 0.5 -0.1 0.5]);
hFig2.Color = [0.5 0.5 0.5];
h2.Color = [0.5 0.5 0.5];
view(45,45)
%% System Object���g����YOLO v2�ɂ�镨�̌��o�ƈʒu����

detector = ObjectDetectorYOLOv2('tform',b_T_k);
%% YOLO v2�ɂ�镨�̌��o�̎��s

[predictedLabels,bboxes,xyzPoints] = step(detector,I,xyz)
%% ���ʂ̉���

l = size(predictedLabels,1);
Iout = insertObjectAnnotation(I,'rectangle',bboxes,...
    cellstr(num2str((1:l)','#%1.0f')));
Iout = insertText(Iout,[zeros(l,1) (0:l-1)'*20],...
    cellstr([num2str((1:l)','#%1.0f, ') ...
    num2str(predictedLabels,'Label:%d,') ...
    num2str(xyzPoints,'X:% 2.2f, Y:% 2.2f, Z:% 2.2f')]));
figure, imshow(Iout);
truesize;
%% �ŏI�p���̐ݒ�
% �s�b�L���O���������̂̍��W�ʒu�����o���A�p�����`

% �ŏI�p��
Xf.p =  xyzPoints(1,:)' + [0;0;0.1];  % 1�Ԗڂ̃I�u�W�F�N�g
Xf.ezyx = [pi+pi/2; pi; 0]; % �p���͔C�ӂɒ�`
%% �ŏI�p���̋t�^���w������

% �֐ߊp�v�Z
[qf, ~] = solveIK(motomini,EELinkName, Xf.p, Xf.ezyx, [restConfig.JointPosition]);
finalConfig = restConfig;
finalConfig = arrayfun(@(x,y) setfield(x, 'JointPosition', y), finalConfig, qf);
figure(hFig2);
set(gcf,'Visible','on');
show(motomini,finalConfig,'PreservePlot',true,'Frames','off');
shg;
%% ���`��Ԃŏ����O���𐶐�

% ���s�܂ł̎���
totalTime = 4;
% ��Q��
obstacles = [];
% �o�R�_�̐�
numPoints = 4;
% ����v�Z�̗L��
useParallel = false;
% ����
showMultibodyExplorer = true;

% ���`��Ԃŏ����O���𐶐�
t0 = 0;
q0 = [restConfig.JointPosition]';
t = linspace(t0,totalTime,numPoints + 2);
Q0 = zeros(motominiParams.numJoints, numPoints + 2);
for i = 1:motominiParams.numJoints
    Q0(i,:) = linspace(q0(i), qf(i),numPoints + 2);
end
Qt = Q0;

% Robotics System Toolbox�ŋO��������
% �O�����֐ߍ��W�n����EE�̍�ƍ��W�n�ɕϊ�
Xt = zeros(size(Qt,2),3);
config = restConfig;
for k = 1:size(Qt,2)
    config = arrayfun(@(x,y) setfield(x, 'JointPosition', y), config, [Qt(:,k);0;0]');
    Xt(k,:) = tform2trvec(motomini.getTransform(config,'gripper_EE_link'));
end
XYZOr = calcXYZFromSplineMatrix(motomini,EELinkName,numPoints,Q0);
hold on;
hXYZOr = plot3(XYZOr(:,1),XYZOr(:,2),XYZOr(:,3),'-ro','LineWidth',3);
view(135,35)
shg;
figure;
plot(t,Qt');
legend(motominiParams.jntNames,'Interpreter',"none");
%% Simscape Multibody�ŋt���͊w�V�~�����[�V����(���`��ԋO��)
% Simscape Multibody��Mechanics Explorer �ŃA�j���[�V������

% open_system(modelName);
% set_param([modelName '/Draw Trajectory'],'Commented','on');
% set_param(modelName,'SimMechanicsOpenEditorOnUpdate','on');
% MotominiParams.jntMaxLim = motominiParams.jntMaxLim;
% MotominiParams.jntMinLim = motominiParams.jntMinLim;
% sim(modelName);
%% �O���v����œK�����Ƃ��ĉ���
% FMINCON���Ă�ōœK��������
% 
% ���Ԃ�������̂ŕK�v�ɉ����āu��~�v���N���b�N���čœK�����~�߂�

% doOptim = false;
% [QOpt,Q0,t,Qout,dQout] = planTrajectory(doOptim,q0, qf, totalTime, ...
%     numPoints, obstacles, motominiParams, modelName, useParallel,...
%     showMultibodyExplorer);

%% 3���X�v���C����Ԃɂ��O�������Ɖ���

%XYZOpt = calcXYZFromSplineMatrix(motomini,EELinkName,numPoints,QOpt);
%figure(hFig2);
%plot3(XYZOpt(:,1),XYZOpt(:,2),XYZOpt(:,3),'-o','LineWidth',3);
%view(45,45);
%shg;
%% ���������O���̃V�~�����[�V����
% Show results of optimization in Multibody Explorer

% q0 = Q0(:,1);
% Qt = QOpt;
%set_param(modelName,'SimMechanicsOpenEditorOnUpdate','on');
%sim(modelName);
%% ROS�o�R�Ŋ֐ߏ����擾

if useGazebo
    % Gazebo�̐ݒ�ύX��API�I�u�W�F�N�g���쐬
    gazebo = ExampleHelperGazeboCommunicator();
    
    % �����G���W���̃^�C���X�e�b�v��������(=�����������)
    pauseSim(gazebo);
    phys = readPhysics(gazebo);
    phys.TimeStep = 0.001;
    phys.UpdateRate = 1000;
    setPhysics(gazebo,phys);
    resumeSim(gazebo);
end
if useGazebo
    %% Get state from robot
    armStateSub = rossubscriber('/motomini_controller/state');
    pause(1)
    qAct = armStateSub.LatestMessage.Actual.Positions
    display(armStateSub.LatestMessage.JointNames);
end
%% ROS�o�R�ŋO�����𑗐M���A���[�`���O�p����

if useGazebo
    %% Create publisher and message to send command to robot
    [armCmdPub,armCmdMsg] = rospublisher('/motomini_controller/command')
    display(armCmdMsg);    % 'trajectory_msgs/JointTrajectory'
    
    %% Create Joint Trajectory Point messages
    % Joint Trajectory Point 1: all joints to zero
    jntJTPs = arrayfun(@(~) rosmessage(rostype.trajectory_msgs_JointTrajectoryPoint),zeros(1,numPoints+2));
    for k = 1:(numPoints+2)
        jntJTPs(k) = rosmessage(rostype.trajectory_msgs_JointTrajectoryPoint);
        dur1 = rosduration(totalTime/(numPoints+2)*k);
        jntJTPs(k).TimeFromStart = copy(dur1);
        jntJTPs(k).Positions = Qt(:,k);
        jntJTPs(k).Velocities = zeros(motominiParams.numJoints,1);
    end
    %% Configure command message 'trajectory_msgs/JointTrajectory' and send
    armCmdMsg.JointNames = motominiParams.jntNames;
    armCmdMsg.Points = jntJTPs;
    send(armCmdPub, armCmdMsg)
    
    pause(20);
    imSub = rossubscriber('/kinect2/sd/image_color');
    imMsg = receive(imSub);
    I = readImage(imMsg);
    figure, imshow(I);

end
%% �O���b�p�[�I�[�v��

if useGazebo
    %% Get state from robot
    gripperStateSub = rossubscriber('/gripper_controller/state');
    pause(1)
    qAct = gripperStateSub.LatestMessage.Actual.Positions
    display(gripperStateSub.LatestMessage.JointNames);
    
    [gripperPub,gripperMsg] = rospublisher('/gripper_controller/command');
    gripperMsg.JointNames = gripperStateSub.LatestMessage.JointNames;
    
    jntJTPg = rosmessage(rostype.trajectory_msgs_JointTrajectoryPoint);
    dur1 = robotics.ros.msg.Duration;
    dur1.Sec = 1;
    jntJTPg.TimeFromStart = dur1;
    jntJTPg.Positions = [0.03; 0.03];
    jntJTPg.Velocities = zeros(2,1)

    gripperMsg.Points = [jntJTPg];
    send(gripperPub,gripperMsg);
end
%% �s�b�L���O�p����
% �s�b�L���O���������̂̍��W�ʒu�����o���A�p�����`

% �ŏI�p��
Xf.p =  xyzPoints(1,:)'+[0;0;0.01];  % 1�Ԗڂ̃I�u�W�F�N�g
Xf.ezyx = [pi+pi/2; pi; 0]; % �p���͔C�ӂɒ�`
% �֐ߊp�v�Z
[qf, ~] = solveIK(motomini,EELinkName, Xf.p, Xf.ezyx, [restConfig.JointPosition]);
finalConfig = restConfig;
finalConfig = arrayfun(@(x,y) setfield(x, 'JointPosition', y), finalConfig, qf);
figure(hFig2);
set(gcf,'Visible','on');
show(motomini,finalConfig,'PreservePlot',true,'Frames','off');

if useGazebo
    jntJTP1 = rosmessage(rostype.trajectory_msgs_JointTrajectoryPoint);
    dur1 = robotics.ros.msg.Duration;
    dur1.Sec = 5;
    jntJTP1.TimeFromStart = dur1;
    jntJTP1.Positions = qf(1:6);
    jntJTP1.Velocities = zeros(motominiParams.numJoints,1);
    armCmdMsg.JointNames = motominiParams.jntNames;
    armCmdMsg.Points = [jntJTP1];
    send(armCmdPub, armCmdMsg)
    pause(20);
    imMsg = receive(imSub);
    I = readImage(imMsg);
    figure, imshow(I);
end
%% �O���b�p�[�N���[�Y & ���[�`���O�|�C���g�ɖ߂�

if useGazebo
    % �O���b�p�[�N���[�Y
    gripperMsg.Points.Positions = [0, 0];
    send(gripperPub,gripperMsg);
    pause(5);
    imMsg = receive(imSub);
    I = readImage(imMsg);
    figure, imshow(I);

   % ���[�`���O�|�C���g�֖߂�
    armCmdMsg.Points = jntJTPs(end);
    send(armCmdPub, armCmdMsg)
    pause(5);
    imMsg = receive(imSub);
    I = readImage(imMsg);
    figure, imshow(I);
end
%%
% Copyright 2019 The MathWorks, Inc.
% 
%