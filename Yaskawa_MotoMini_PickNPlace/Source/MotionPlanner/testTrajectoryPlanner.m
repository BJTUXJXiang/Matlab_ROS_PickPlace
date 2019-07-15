%% �œK���v�Z�ɂ��O���v��
% MATLAB, Simulink, Robotics System
% Toolbox, Simscape Multibody, and Optimization Toolbox
% Author: Carlos Santacruz-Rosero, Ph.D. and Tohru Kikawada
% Copyright 2019 The MathWorks, Inc.

%% 0. ������
clear; close all; clc; bdclose all;

%% 1. MotoMini���c���[�\�����{�b�g�Ƃ��ĕ\��
modelName = 'motominiPlanning';
motomini = createMotomini();
restConfig = motomini.homeConfiguration;
restConfig(7).JointPosition = 0.03;
restConfig(8).JointPosition = 0.03;
hFig = figure;
show(motomini,restConfig,'Frame','off');
axis tight
campos auto
EELinkName = 'gripper_EE_link';
motominiParams = setMotominiParameters('',motomini);

%% 2. �^�[�Q�b�g�̐ݒ�
cupHeight = 0.05;
cupRadius = 0.02;
cupPosition = [0.3;0.3;cupHeight/2]; 

alpha 0.1;
hold on;
% Create points for visualizing a cup
[X,Y,Z] = cylinder(cupRadius*linspace(0,1,50).^0.125);
% Scale the Z coordinates
Z = cupHeight*Z - cupHeight/2;
% Translate to the specified position
X = X + cupPosition(1);
Y = Y + cupPosition(2);
Z = Z + cupPosition(3);
% Add the cup to the figure and configure lighting
s = patch(surf2patch(X,Y,Z));
s.FaceColor = 'red';
s.FaceLighting = 'gouraud';
s.EdgeAlpha = 0;
axis tight
campos auto
camtarget auto
camva auto
shg;

%% �ŏI�p���̐ݒ�
% �����p��
X0_tform = motomini.getTransform(restConfig,'gripper_EE_link');
X0.p = X0_tform(1:3,4); 
X0.ezyx = tform2eul(X0_tform)';

% �ŏI�p��
Xf.p =  cupPosition; 
Xf.ezyx = [0; -pi/2; pi+pi/4];

% ����
rbtree = robotics.RigidBodyTree;
body1 = robotics.RigidBody('cup_reach_frame');
jnt1 = robotics.Joint('jnt1','fixed');
jnt1.setFixedTransform(trvec2tform(Xf.p')*eul2tform(Xf.ezyx'));
body1.Joint = jnt1;
rbtree.addBody(body1,'base');
h = show(rbtree);
shg;

%% 3. �n�_�ƏI�_�̋t�^���w������

% �֐ߊp�v�Z
[q0, ~] = solveIK(motomini,EELinkName, X0.p, X0.ezyx, [restConfig.JointPosition]);
[qf, ~] = solveIK(motomini,EELinkName, Xf.p, Xf.ezyx, [restConfig.JointPosition]);
finalConfig = restConfig;
finalConfig = arrayfun(@(x,y) setfield(x, 'JointPosition', y), finalConfig, qf);
hold on;
show(motomini,finalConfig,'PreservePlot',true,'Frames','off');
shg;

%% 4. ���`��Ԃŏ����O���𐶐�
doOptim = true;

% ���s�܂ł̎���
totalTime = 1;
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
hXYZOr = plot3(XYZOr(:,1),XYZOr(:,2),XYZOr(:,3),'-o','LineWidth',3);
shg;

%% Simscape Multibody�ŋt���͊w�V�~�����[�V����(���`��ԋO��)
% Simscape Multibody��Mechanics Explorer �ŃA�j���[�V������
open_system(modelName);

set_param([modelName '/Draw Trajectory'],'Commented','on');
set_param(modelName,'SimMechanicsOpenEditorOnUpdate','on');
MotominiParams.jntMaxLim = motominiParams.jntMaxLim;
MotominiParams.jntMinLim = motominiParams.jntMinLim;
sim(modelName);

%% 4. �O���v����œK�����Ƃ��ĉ���
% FMINCON���Ă�ōœK��������

[QOpt,Q0,t,Qout,dQout] = planTrajectory(doOptim,q0, qf, totalTime, ...
    numPoints, obstacles, motominiParams, modelName, useParallel,...
    showMultibodyExplorer);
% ���Ԃ�������̂ŕK�v�ɉ����āu��~�v���N���b�N���čœK�����~�߂�

%% 5. �œK���v�Z���ʂ����[�h���ĕ\��
load('MotominiOptimResultsForDemoShowcase.mat')

%% 6. 3���X�v���C����Ԃɂ��O�������Ɖ���
XYZOpt = calcXYZFromSplineMatrix(motomini,EELinkName,numPoints,QOpt);
figure(hFig);
plot3(XYZOpt(:,1),XYZOpt(:,2),XYZOpt(:,3),'-o','LineWidth',3);
shg;

%% 6. 3���X�v���C����Ԃɂ��O�������̃V�~�����[�V����
% Show results of optimization in Multibody Explorer
q0 = Q0(:,1);
Qt = QOpt;
set_param(modelName,'SimMechanicsOpenEditorOnUpdate','on');
sim(modelName);

%%
% %% 8. ��Q���̒�`
% set_param([modelName '/Collision Model'],'Commented','off')
% colObject1.type = 'sphere';
% colObject1.radius = 0.13;
% colObject1.pos = [0.0428; 0.1358; 0.5536];
% obstacles = [colObject1];   % in the future this will be an array. 
% 
% 
% %% 9. �ēx�A�œK�����[�`�������s
% close all
% % PlanTrajectory calls FMINCON
% [QOpt,Q0,t,Qout,dQout] = planTrajectory(doOptim,q0, qf, totalTime, ...
%     numPoints, obstacles, motominiParams, modelName, useParallel,...
%     showMultibodyExplorer);
% % Stop the Optimization figure and load results in Next step
% 
% %% 10. �œK���v�Z���ʂ̃��[�h
% load('YBOptimResultsForDemoShowcase.mat')
% QOpt = QOptExampleObs;
% Q0 = Q0ExampleObs;
% openfig('QoptExampleObsYB.fig');
% 
% 
% %% 11. 3���X�v���C����Ԃɂ��O�������Ɖ����A�V�~�����[�V����
% Qt = QOpt;
% q0 = Q0(:,1);
% set_param(modelName,'SimMechanicsOpenEditorOnUpdate','on');
% XYZOr = calcXYZFromSplineMatrix(youbot,EELinkName,numPoints,Q0);
% XYZOpt = calcXYZFromSplineMatrix(youbot,EELinkName,numPoints,QOpt);
% sim(modelName);




%% Dont' run this: Save results from optimization
% QOptExampleObs = QOpt;
% Q0ExampleObs = Q0;
% save('YBOptimResultsForDemoShowcase.mat','QOptExampleObs', 'Q0ExampleObs', '-append');


