classdef config_mwm < base_config
    % config_mwm Global constants
    properties(Constant)        
        TRIAL_TYPES_DESCRIPTION = { ...            
            'Training' ...
        };                    
        
        TRIALS_PER_SESSION = [4 4 4];
        SESSIONS = length(config_mwm.TRIALS_PER_SESSION);
        TRIALS = sum(config_mwm.TRIALS_PER_SESSION);        
        TRIAL_TYPE = ones(1, config_mwm.TRIALS);
        TRIAL_TIMEOUT = 90; % seconds
        GROUPS = 2;
        GROUPS_DESCRIPTION = {'Control', 'Stress', 'Control/Food', 'Stress/Food'};
        
        % centre point of arena in cm        
        CENTRE_X = 0;
        CENTRE_Y = 0;
        % radius of the arena
        ARENA_R = 100;
        % platform position and radius
        PLATFORM_X = -50;
        PLATFORM_Y = 10;
        PLATFORM_R = 6;               
        % other parameters
        PLATFORM_PROXIMITY_RADIUS = 5; % in platform radii
        LONGEST_LOOP_EXTENSION = 40; % in cm
        
        
        % number of animals to discard from each group
        REGULARIZE_GROUPS = 1;
        NDISCARD = 0;
        DISCARD_FEATURE = base_config.FEATURE_AVERAGE_SPEED;
    
        % relation between animal ids and groups 
        % (1 = control, 2 = stress, 3 = control + modified diet, 4 = stress
        % + modified diet)
        TRAJECTORY_GROUPS = {...
                 %1st set   
                [87, 1; 91, 1; 93, 1; 95, 1; 99, 1; 101, 1; 103, 1; ...
                 114, 1; 115, 1; 121, 1; 88, 2; 90, 2; 98, 2; 100, 2; ...  
                 104, 2; 106, 2; 108, 2; 113, 2; 118, 2; 122, 2], ...
                 % 2nd set
                [43, 1; 49, 1; 52, 1; 57, 1; 59, 1; 65, 1; 75, 1; ...
                 82, 1; 44, 2; 50, 2; 53, 2; 58, 2; 60, 2; 67, 2; ...
                 71, 2; 76, 2; 78, 2; 83, 2], ...
                 % 3rd set
                [50, 1; 61, 1; 67, 1; 71, 1; 75, 1; 83, 1; 90, 1; ...
                 94, 1; 100, 1; 111, 1; 52, 2; 57, 2; 63, 2; 69, 2; ...
                 73, 2; 81, 2; 92, 2; 96, 2; 102, 2; 107, 2; 51, 3; ...
                 55, 3; 56, 3; 62, 3; 68, 3; 74, 3; 82, 3; 91, 3; 95, 3; ...
                 106, 3; 53, 4; 58, 4; 64, 4; 72, 4; 76, 4; 84, 4; 97, 4; ...
                 103, 4; 108, 4; 113, 4] ...
         };                      
               
                                      
        CLUSTER_CLASS_MINIMUM_SAMPLES_P = 0.01; % 2% o
        CLUSTER_CLASS_MINIMUM_SAMPLES_EXP = 0.75;
                
        FEATURE_LONGEST_LOOP = base_config.FEATURE_LAST + 1;
        FEATURE_CENTRE_DISPLACEMENT = base_config. FEATURE_LAST + 2;
        FEATURE_PLATFORM_PROXIMITY = base_config.FEATURE_LAST + 3;
        FEATURE_CV_INNER_RADIUS = base_config.FEATURE_LAST + 4;
                        
        DEFAULT_FEATURE_SET = [config_mwm.FEATURE_MEDIAN_RADIUS, ...
                               config_mwm.FEATURE_IQR_RADIUS, ...
                               config_mwm.FEATURE_FOCUS, ...
                               config_mwm.FEATURE_CENTRE_DISPLACEMENT, ... 
                               config_mwm.FEATURE_CV_INNER_RADIUS, ...
                               config_mwm.FEATURE_PLATFORM_PROXIMITY, ...
                               config_mwm.FEATURE_BOUNDARY_ECCENTRICITY, ...
                               config_mwm.FEATURE_LONGEST_LOOP];
                       
        CLUSTERING_FEATURE_SET = config_mwm.DEFAULT_FEATURE_SET;
        %%
        %% Tags sets - number/indices have to match the list below        
        %%
        TAGS_FULL = 1; 
        TAGS250_90 = 2; % Important: go from "more detailed" to less detailed 
        TAGS250_70 = 3;
        TAGS300_70 = 4;
                        
        CLASSES_COLORMAP = @jet;
    end
    
    properties(GetAccess = 'public', SetAccess = 'protected')
        TRAJECTORY_DATA_DIRS = {};
        TRAJECTORY_SNAPSHOTS_DIRS = {};    
        TAGS_CONFIG = {};
    end
    
    methods    
        function inst = config_mwm()
            inst@base_config('Morris water maze', ...                
               [ tag('TT', 'thigmotaxis', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 1), ... % default tags
                 tag('IC', 'incursion', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 2), ...
                 tag('SS', 'scanning-surroundings', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 7), ...                 
                 tag('SC', 'scanning', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 3), ...
                 tag('FS', 'focused search', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 4), ...                                  
                 tag('SO', 'self orienting', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 6), ...
                 tag('CR', 'chaining response', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 5), ...
                 tag('ST', 'target scanning', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 8), ...
                 tag('TS', 'target sweep', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 3), ...             
                 tag('DF', 'direct finding', base_config.TAG_TYPE_BEHAVIOUR_CLASS), ...
                 tag('AT', 'approaching_target', base_config.TAG_TYPE_BEHAVIOUR_CLASS), ...                              
                 tag('CI', 'circling', base_config.TAG_TYPE_BEHAVIOUR_CLASS, 8), ...                                   
                 tag('CP', 'close pass', base_config.TAG_TYPE_TRAJECTORY_ATTRIBUTE), ...
                 tag('S1', 'selected 1', base_config.TAG_TYPE_TRAJECTORY_ATTRIBUTE) ], ...
               [], ...% no additional data representation
               { {'L_max', 'Longest loop', 'trajectory_longest_loop', 1, 40}, ...
                 {'D_ctr', 'Centre displacement', 'trajectory_centre_displacement', 1, {'CENTRE_X', 'CENTRE_Y', 'ARENA_R'}}, ...
                 {'P_plat', 'Platform proximity', 'trajectory_time_within_radius', 1, 3*config_mwm.PLATFORM_R, 'X0', config_mwm.PLATFORM_X, 'Y0', config_mwm.PLATFORM_Y}, ...
                 {'Ri_CV', 'Inner radius variation', 'trajectory_cv_inner_radius', 1, {'CENTRE_X', 'CENTRE_Y'} } }, ...                 
               {} ...
            );  
        
            cur_dir = fileparts(mfilename('fullpath'));
            
            inst.TRAJECTORY_DATA_DIRS = {... % 1st set
                fullfile(cur_dir, '../../data/mwm_peripubertal_stress/set1/'), ...                                      
                fullfile(cur_dir, '../../data/mwm_peripubertal_stress/set2/'), ...
                fullfile(cur_dir, '../../data/mwm_peripubertal_stress/set3/'), ...
            }; 
    
            % used to calibrate the trajectories
            inst.TRAJECTORY_SNAPSHOTS_DIRS = {...
                fullfile(cur_dir, '../../data/mwm_peripubertal_stress/screenshots/set1/'), ...
                fullfile(cur_dir, '../../data/mwm_peripubertal_stress/screenshots/set2/'), ...
                fullfile(cur_dir, '../../data/mwm_peripubertal_stress/screenshots/set3/') ...
            };        
    
            inst.TAGS_CONFIG = { ... % values are: file that stores the tags, segment length, overlap, default number of clusters
                { fullfile(cur_dir, '../../data/mwm_peripubertal_stress/labels_full.csv'), 0, 0}, ...
                { fullfile(cur_dir, '../../data/mwm_peripubertal_stress/segment_labels_250c.csv'), 75, base_config.SEGMENTATION_CONSTANT_LENGTH, 2, 250, 0.90}, ... 
                { fullfile(cur_dir, '../../data/mwm_peripubertal_stress/segment_labels_250_70.csv'), 35, base_config.SEGMENTATION_CONSTANT_LENGTH, 2, 250, 0.70}, ...
                { fullfile(cur_dir, '../../data/mwm_peripubertal_stress/segment_labels_300_70.csv'), 37, base_config.SEGMENTATION_CONSTANT_LENGTH, 2, 300, 0.70}, ...
            };

        end
                
        % Imports trajectories from Noldus data file's
        function traj = load_data(inst, path)
            addpath(fullfile(fileparts(mfilename('fullpath')),'../../import/noldus'));
            traj = load_trajectories(1:3, 1, 'DeltaX', -100, 'DeltaY', -100);
        end        
    end
end

