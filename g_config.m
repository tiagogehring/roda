classdef g_config
    % g_config Global constants
    properties(Constant)
        TRIALS_PER_SESSION = 4;
        SESSIONS = 3;
        TRIALS = g_config.TRIALS_PER_SESSION*g_config.SESSIONS;
        TRIAL_TIMEOUT = 90; % seconds
        % centre point of arena in cm        
        CENTRE_X = 0;
        CENTRE_Y = 0;
        % radius of the arena
        ARENA_R = 100;
        % platform position and radius
        PLATFORM_X = -50;
        PLATFORM_Y = 10;
        PLATFORM_R = 6;        
        
        TRAJECTORY_DATA_DIRS = {... % 1st set
            '/home/tiago/neuroscience/rat_navigation/data/set1/', ...                                      
            '/home/tiago/neuroscience/rat_navigation/data/set2/', ...
            '/home/tiago/neuroscience/rat_navigation/data/set3/', ...
        }; 
    
    	% used to calibrate the trajectories
        TRAJECTORY_SNAPSHOTS_DIRS = {...
            '/home/tiago/neuroscience/rat_navigation/screenshots/set1/', ...
            '/home/tiago/neuroscience/rat_navigation/screenshots/set2/', ...
            '/home/tiago/neuroscience/rat_navigation/screenshots/set3/' ...
        };        
    
        NDISCARD = 0;
    
        % relation between animal ids and groups (1 = control, 2 = stress,
        % 3 = control + modified diet, 4 = stress + modified diet                
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
        
        % tag types
        TAG_TYPE_ALL = 0;
        TAG_TYPE_BEHAVIOUR_CLASS = 1;
        TAG_TYPE_TRAJECTORY_ATTRIBUTE = 2;
        
        % default tags       
        TAGS = [ tag('UD', 'undefined', g_config.TAG_TYPE_BEHAVIOUR_CLASS), ...
                 tag('TT', 'thigmotaxis', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 1), ...
                 tag('IC', 'incursion', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 2), ...
                 tag('TS', 'target sweep', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 3), ...                 
                 tag('SC', 'scanning', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 4), ...
                 tag('SO', 'self orienting', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 5), ...
                 tag('CR', 'chaining response', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 6), ...
                 tag('ST', 'target scanning', g_config.TAG_TYPE_BEHAVIOUR_CLASS, 7), ...
                 tag('FT', 'target focused search', g_config.TAG_TYPE_BEHAVIOUR_CLASS), ...                 
                 tag('FS', 'focused search', g_config.TAG_TYPE_BEHAVIOUR_CLASS), ...                 
                 tag('AT', 'approaching targed', g_config.TAG_TYPE_TRAJECTORY_ATTRIBUTE), ...             
                 tag('DF', 'direct finding', g_config.TAG_TYPE_BEHAVIOUR_CLASS), ...
                 tag('CP', 'close pass', g_config.TAG_TYPE_TRAJECTORY_ATTRIBUTE), ...
                 tag('S1', 'selected 1', g_config.TAG_TYPE_TRAJECTORY_ATTRIBUTE)];

        
        REDUCED_BEHAVIOURAL_CLASSES = [ ...
            tag.combine_tags( [g_config.TAGS(tag.tag_position(g_config.TAGS, 'TT')), g_config.TAGS(tag.tag_position(g_config.TAGS, 'IC'))]), ...
            tag.combine_tags( [g_config.TAGS(tag.tag_position(g_config.TAGS, 'SC')), g_config.TAGS(tag.tag_position(g_config.TAGS, 'TS'))]), ...
            tag.combine_tags( [g_config.TAGS(tag.tag_position(g_config.TAGS, 'SO')), g_config.TAGS(tag.tag_position(g_config.TAGS, 'ST')), g_config.TAGS(tag.tag_position(g_config.TAGS, 'CR'))]) ...
        ];   

        UNDEFINED_TAG_ABBREVIATION = 'UD'; 
        UNDEFINED_TAG_INDEX = 1;        
                                    
        CLUSTER_CLASS_MINIMUM_SAMPLES_P = 0.01; % 2% o
        CLUSTER_CLASS_MINIMUM_SAMPLES_EXP = 0.75;
        
        FOCUS_P = 1.;
        
        DEFAULT_SEGMENT_LENGTH = 250;
        DEFAULT_SEGMENT_OVERLAP = 0.95;        
        DEFAULT_NUMBER_OF_CLUSTERS = 120;
        
        DEFAULT_FEATURE_SET = [features.MEDIAN_RADIUS, features.IQR_RADIUS, features.FOCUS, features.PLATFORM_PROXIMITY, ...
                               features.PLATFORM_SURROUNDINGS, features.BOUNDARY_ECCENTRICITY, features.LONGEST_LOOP]; 
        
        FULL_FEATURE_SET = [ features.MEDIAN_RADIUS, ...
                             features.IQR_RADIUS, ...
                             features.FOCUS, ...
                             features.BOUNDARY_CENTRE_DISTANCE_PLATFORM, ...
                             features.LOOPS, ...
                             features.SPIN, ...
                             features.BOUNDARY_ECCENTRICITY, ...
                             features.MEDIAN_INNER_RADIUS, ...
                             features.CV_INNER_RADIUS ];
                         
        SEGMENTS_TAGS200_PATH = '/home/tiago/neuroscience/rat_navigation/trajectories/segment_labels_200.csv';       
        SEGMENTS_TAGS250_PATH = '/home/tiago/neuroscience/rat_navigation/trajectories/segment_labels_250.csv';
        SEGMENTS_TAGS300_PATH = '/home/tiago/neuroscience/rat_navigation/trajectories/segment_labels_300.csv';
       
        FULL_TRAJECTORIES_TAGS_PATH = '/home/tiago/neuroscience/rat_navigation/trajectories/labels_full.csv';

        DEFAULT_TAGS_PATH = g_config.SEGMENTS_TAGS250_PATH;
        
        SHORT_TRAJECTORIES_TAGS_PATH = '/home/tiago/neuroscience/rat_navigation/trajectories/labels_250_short.csv';
        
        % plot properties
        AXIS_LINE_WIDTH = 1.5;    % AxesLineWidth
        FONT_SIZE = 20;      % Fontsize
        LINE_WIDTH = 1.4;      
        OUTPUT_DIR = '/home/tiago/results/'; % where to put all the graphics and other generated output
        CLASSES_COLORMAP = colormap('jet');
    end   
end
