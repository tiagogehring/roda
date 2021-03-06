classdef label_trajectories_view < handle
    %LABEL_TRAJECTORIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        window = [];        
        parent = [];
        % GUI elements
        views_box = [];
        status_text = [];
        ctrl_box = [];        
        sec_view_handles = [];
        views_grid = [];    
        views_panels = [];
        axis_handles = [];
        desc_handles = [];
        view_panels = [];
        cb_handles = [];
        yviews_combo = [];
        xviews_combo = [];
        filter_combo_box = []
        filter_combo = [];
        sort_combo = [];
        sort_reverse_check = [];
        main_view_combo = [];
        main_view_dir_check = [];
        main_view_full_combo = [];
        main_view_tol_combo = [];
        filter_prev_button = [];
        filter_next_button = [];
        sec_view_combos = [];
        sec_view_dir_check = [];
        sec_view_full_combos = [];           
        sec_view_tol_combos = [];
        % other state        
        filter = [];        
        nitems_filter = 0;
        sorting = [];        
        simplify_level_prev = 0;
        data_repr_norm = [];
        segments_map = [];
        covering = [];
        diff_set = [];
        distr_status = [];
        filter_combo_valid = 0;        
        % current trajectory index
        cur = 0;       
    end
    
    methods
        function inst = label_trajectories_view(par, par_wnd)            
            inst.parent = par;            
            inst.window = uiextras.VBox('Parent', par_wnd);
            inst.filter = 1:inst.parent.traj.count;
            inst.sorting = 1:inst.parent.traj.count;
        end    
            
        function update(inst)
            if isempty(inst.views_box)                                                    
                %%
                %% Create controls
                %%%
                % control buttons box
                inst.views_box = uiextras.VBox('Parent', inst.window);
                inst.ctrl_box = uiextras.HBox('Parent', inst.window);
                set(inst.window, 'Sizes', [-1 100] );
                % box with additional controls on the left    
                filter_panel = uiextras.BoxPanel('Parent', inst.ctrl_box, 'Title', 'Filter/Sort');
                filter_box = uiextras.VBox('Parent', filter_panel);
                % box with left navigation controls
                lnav_box = uiextras.VBox('Parent', inst.ctrl_box);
                % middle status box
                stat_box = uiextras.VBox('Parent', inst.ctrl_box);
                % box with right navigation controls
                rnav_box = uiextras.VBox('Parent', inst.ctrl_box);
                % and another one
                layout_panel = uiextras.BoxPanel('Parent', inst.ctrl_box, 'Title', 'Layout');
                layout_box = uiextras.VBox('Parent', layout_panel);

                set(inst.ctrl_box, 'Sizes', [300 75 -1 75 550]);
                % trajectories navigation
                uicontrol('Parent', lnav_box, 'Style', 'pushbutton', 'String', '<-', 'Callback', {@inst.previous_callback});
                uicontrol('Parent', rnav_box, 'Style', 'pushbutton', 'String', '->', 'Callback', {@inst.next_callback});    
                uicontrol('Parent', lnav_box, 'Style', 'pushbutton', 'String', '<<-', 'Callback', {@inst.previous2_callback});
                uicontrol('Parent', rnav_box, 'Style', 'pushbutton', 'String', '->>', 'Callback', {@inst.next2_callback});
                uicontrol('Parent', lnav_box, 'Style', 'pushbutton', 'String', '<<<-', 'Callback', {@inst.previous3_callback});
                uicontrol('Parent', rnav_box, 'Style', 'pushbutton', 'String', '->>>', 'Callback', {@inst.next3_callback});

                % status text (middle)
                inst.status_text = uicontrol('Parent', stat_box, 'Style', 'text', 'String', '');
                % feature sorting control
                sortstr = {'** none **', '** distance to centre (max) **', '** distance to centre (euclidean) **', '** combined **', '** random **' };
                for i = 1:length(inst.parent.config.SELECTED_FEATURES) % have to do this way because of stupid matlab        
                    sortstr = [sortstr, inst.parent.config.SELECTED_FEATURES(i).description];
                end
                sort_box = uiextras.HBox('Parent', filter_box);
                uicontrol('Parent', sort_box, 'Style', 'text', 'String', 'Sort:');        
                inst.sort_combo = uicontrol('Parent', sort_box, 'Style', 'popupmenu', 'String', sortstr, 'Callback', {@inst.sorting_callback});
                inst.sort_reverse_check = uicontrol('Parent', filter_box, 'Style', 'checkbox', 'String', 'Reverse', 'Callback', {@inst.sorting_callback});       
                set(sort_box, 'Sizes', [40, -1]);
                % cluster navigation and control (note: combo-box is created elsewhere
                % since it is dynamic
                inst.filter_combo_box = uiextras.HBox('Parent', filter_box);
                filter_nav_box = uiextras.HButtonBox('Parent', filter_box);
                inst.filter_prev_button = uicontrol('Parent', filter_nav_box, 'Style', 'pushbutton', 'String', '<-', 'Callback', {@inst.filter_prev_callback});    
                inst.filter_next_button = uicontrol('Parent', filter_nav_box, 'Style', 'pushbutton', 'String', '->', 'Callback', {@inst.filter_next_callback});
                inst.nitems_filter = 0;
                % layout controls
                box = uiextras.HBox('Parent', layout_box);
                uicontrol('Parent', box, 'Style', 'text', 'String', 'NX:');
                inst.xviews_combo = uicontrol('Parent', box, 'Style', 'popupmenu', 'String', {'1', '2', '3', '4', '5', '6'}, 'Callback', {@inst.layout_change_callback});
                set(inst.xviews_combo, 'value', inst.parent.config.property('BROWSE_SEGMENTS_NX', 2));
                uicontrol('Parent', box, 'Style', 'text', 'String', 'NY:');
                inst.yviews_combo = uicontrol('Parent', box, 'Style', 'popupmenu', 'String', {'1', '2', '3', '4', '5', '6'}, 'Callback', {@inst.layout_change_callback});      
                set(inst.yviews_combo, 'value', inst.parent.config.property('BROWSE_SEGMENTS_NY', 2));
                
                % build a list with all the possible data representations
                strs = {};
                for i = 1:length(inst.parent.config.DATA_REPRESENTATIONS)                    
                    strs = [strs, inst.parent.config.DATA_REPRESENTATIONS(i).description];
                end
                if ~isempty(inst.parent.traj)
                    full_status = 'on';
                else
                    full_status = 'off';
                end
                strs = ['None', strs];
                tol_str = arrayfun( @(x) num2str(x), 0:25, 'UniformOutput', 0);
                                     
                % 1st combo: main view                
                box = uiextras.HBox('Parent', layout_box);    
                uicontrol('Parent', box, 'Style', 'text', 'String', 'Main:');
                inst.main_view_combo = uicontrol('Parent', box, 'Style', 'popupmenu', 'String', strs, 'Callback', {@inst.layout_change_callback}, 'Value', 2);        
                set(inst.main_view_combo, 'Value', inst.parent.config.property('MAIN_VIEW_DATA_REPR', 2));
                inst.main_view_dir_check = uicontrol('Parent', box, 'Style', 'checkbox', 'String', 'Vec.', 'Callback', {@inst.layout_change_callback});    
                set(inst.main_view_dir_check, 'Value', inst.parent.config.property('MAIN_VIEW_VECTOR_FIELD', 0));
                inst.main_view_full_combo = uicontrol('Parent', box, 'Style', 'popupmenu', 'String', strs, 'Callback', {@inst.layout_change_callback}, 'Enable', full_status);
                set(inst.main_view_full_combo, 'Value', inst.parent.config.property('MAIN_VIEW_FULL_DATA_REPR', 1));                
                uicontrol('Parent', box, 'Style', 'text', 'String', 'Smth.');    
                inst.main_view_tol_combo = uicontrol('Parent', box, 'Style', 'popupmenu', 'String', tol_str, 'Callback', {@inst.layout_change_callback});                
                set(inst.main_view_tol_combo, 'Value', inst.parent.config.property('MAIN_VIEW_TOLERANCE', 1));                                
                set(box, 'Sizes', [50, -1, 50, -1, 60, 60]);
                
                % 2nd combo: secondary view 1    
                box = uiextras.HBox('Parent', layout_box);    
                uicontrol('Parent', box, 'Style', 'text', 'String', 'Sec. 1:');
                inst.sec_view_combos = [uicontrol('Parent', box, 'Style', 'popupmenu', 'String', strs, 'Callback', {@inst.layout_change_callback})];      
                inst.sec_view_dir_check = uicontrol('Parent', box, 'Style', 'checkbox', 'String', 'Vec.', 'Callback', {@inst.layout_change_callback});    
                inst.sec_view_full_combos = [uicontrol('Parent', box, 'Style', 'popupmenu', 'String', strs, 'Callback', {@inst.layout_change_callback}, 'Enable', full_status)];
                uicontrol('Parent', box, 'Style', 'text', 'String', 'Smth.');    
                inst.sec_view_tol_combos = [uicontrol('Parent', box, 'Style', 'popupmenu', 'String', tol_str, 'Callback', {@inst.layout_change_callback})];
                
                set(box, 'Sizes', [50, -1, 50, -1, 60, 60]);
                % 3rd combo: secondary view 2
                box = uiextras.HBox('Parent', layout_box);    
                uicontrol('Parent', box, 'Style', 'text', 'String', 'Sec. 2:');
                inst.sec_view_combos = [ inst.sec_view_combos, ...
                                    uicontrol('Parent', box, 'Style', 'popupmenu', 'String', strs, 'Callback', {@inst.layout_change_callback}) ...
                                  ];     
                inst.sec_view_dir_check = [inst.sec_view_dir_check, uicontrol('Parent', box, 'Style', 'checkbox', 'String', 'Vec.', 'Callback', {@inst.layout_change_callback})];
                inst.sec_view_full_combos = [inst.sec_view_full_combos, uicontrol('Parent', box, 'Style', 'popupmenu', 'String', strs, 'Callback', {@inst.layout_change_callback}, 'Enable', full_status)];
                uicontrol('Parent', box, 'Style', 'text', 'String', 'Smth.');    
                inst.sec_view_tol_combos = [inst.sec_view_tol_combos, uicontrol('Parent', box, 'Style', 'popupmenu', 'String', tol_str, 'Callback', {@inst.layout_change_callback})];
                
                set(box, 'Sizes', [50, -1, 50, -1, 60, 60]);

                set(inst.sec_view_combos(1), 'Value', inst.parent.config.property('SEC_VIEW_1_DATA_REPR', 1));
                set(inst.sec_view_dir_check(1), 'Value', inst.parent.config.property('SEC_VIEW_1_VECTOR_FIELD', 0));
                set(inst.sec_view_full_combos(1), 'Value', inst.parent.config.property('SEC_VIEW_1_FULL_DATA_REPR', 1));
                set(inst.sec_view_tol_combos(1), 'Value', inst.parent.config.property('SEC_VIEW_1_TOLERANCE', 1));
                
                set(inst.sec_view_combos(2), 'Value', inst.parent.config.property('SEC_VIEW_2_DATA_REPR', 1));
                set(inst.sec_view_dir_check(2), 'Value', inst.parent.config.property('SEC_VIEW_2_VECTOR_FIELD', 0));
                set(inst.sec_view_full_combos(2), 'Value', inst.parent.config.property('SEC_VIEW_2_FULL_DATA_REPR', 1));
                set(inst.sec_view_tol_combos(2), 'Value', inst.parent.config.property('SEC_VIEW_2_TOLERANCE', 1));
                             
                % normalization values for speed and other scalar values
                inst.data_repr_norm = inst.parent.config.property('DATA_REPR_NORMALIZATION', []);

                inst.create_views;
                inst.cur = 1; %current index                        
            end  
            if ~inst.filter_combo_valid
                inst.update_filter_combo;
                inst.filter_combo_valid = 1;
            end
            inst.show_trajectories;
        end
        
        
        function [nx, ny] = number_of_views(inst)
            nx = get(inst.xviews_combo, 'value');
            ny = get(inst.yviews_combo, 'value');
        end

        function create_views(inst)
            % create base grid
            if ~isempty(inst.views_grid)
                delete(inst.views_grid);
            end
            inst.views_grid = uiextras.Grid('Parent', inst.views_box);
            
            inst.views_panels = [];
            inst.axis_handles = [];
            inst.view_panels = [];
            inst.desc_handles = [];
            inst.cb_handles = [];
            inst.sec_view_handles = [];                

            [nx, ny] = inst.number_of_views;
            main1 = get(inst.main_view_combo, 'value');
            main2 = get(inst.main_view_full_combo, 'value');
            main = (main1 > 1 || main2 > 1);
            sec1 = get(inst.sec_view_combos(1), 'value');
            sec1main = get(inst.sec_view_full_combos(1), 'value');        
            sec2 = get(inst.sec_view_combos(2), 'value');
            sec2main = get(inst.sec_view_full_combos(2), 'value');
            sec = (sec1 > 1 || sec2 > 1 || sec1main > 1 || sec2main > 1);

            for j =1:nx
                for i = 1:ny
                    inst.view_panels = [inst.view_panels, uiextras.BoxPanel('Parent', inst.views_grid)];
                    % boxes for the view (a vertical one for the checkboxes)
                    view_hbox = uiextras.HBox('Parent', inst.view_panels(end));

                    % trajectory display
                    view_vbox = uiextras.VBox('Parent', view_hbox);
                    % do we have any secondary views ?
                    if (sec)                                
                        hbox = uiextras.HBox('Parent', view_vbox);                    
                        if main
                            inst.axis_handles = [inst.axis_handles, axes('Parent', hbox)];
                        else
                            uicontrol('Parent', hbox, 'Style', 'text', 'String', 'None');
                        end
                        % create another box for the secondary views
                        vbox = uiextras.VBox('Parent', hbox);
                        if (sec1 > 1)
                            inst.sec_view_handles = [inst.sec_view_handles , axes('Parent', vbox)];
                        else
                            inst.sec_view_handles = [inst.sec_view_handles, uicontrol('Parent', vbox, 'Style', 'text', 'String', 'None')];
                        end
                        if (sec2 > 1)
                            inst.sec_view_handles = [inst.sec_view_handles, axes('Parent', vbox)];
                        else
                            inst.sec_view_handles = [inst.sec_view_handles, uicontrol('Parent', vbox, 'Style', 'text', 'String', 'None')];        
                        end
                    else                    
                        if main
                            inst.axis_handles = [inst.axis_handles, axes('Parent', view_vbox)];
                        else
                            uicontrol('Parent', view_vbox, 'Style', 'text', 'String', 'None');
                        end
                    end
                    % trajectory description            
                    inst.desc_handles = [inst.desc_handles, uicontrol('Parent', view_vbox, 'Style', 'text')];
                    set(view_vbox, 'Sizes', [-1, 35]);

                    % check boxes with tags
                    % yet another box
                    cb_box = uiextras.VButtonBox('Parent', view_hbox);
                    set(view_hbox, 'Sizes', [-1, 50]);       
                    hcb_new = [];
                    for k = 1:length(inst.parent.config.TAGS)
                        txt = inst.parent.config.TAGS(k).abbreviation;
                        hcb_new = [ hcb_new, ...
                                      uicontrol('Parent', cb_box, 'Style', 'checkbox', 'String', txt, 'Callback', {@inst.checkbox_callback}) ...
                                  ];
                    end
                    inst.cb_handles = [inst.cb_handles; hcb_new];
                end
            end

            set(inst.views_grid, 'RowSizes', -1*ones(1, ny), 'ColumnSizes', -1*ones(1, nx));
        end  

        function update_filter_combo(inst)
            if ~isempty(inst.filter_combo)
                delete(inst.filter_combo);
                inst.filter_combo = [];
            end
            strings = {'** all **', '** tagged **', '** untagged **', '** isolated **', '** suspicious **', '** selection **', '** compare **', '** errors **'};
            if ~isempty(inst.parent.clustering_results)
                strings = [strings, arrayfun( @(t) t.description, inst.parent.clustering_results.classes, 'UniformOutput', 0)];
            end     

            if ~isempty(inst.parent.clustering_results)
                % isolated/lonely segments            
                isol = ~inst.covering;
                for i = 1:max(inst.parent.clustering_results.nclusters)
                    if inst.parent.clustering_results.cluster_class_map(i) == 0
                        lbl = inst.parent.config.UNDEFINED_TAG.abbreviation;
                    else
                        lbl = inst.parent.clustering_results.classes(inst.parent.clustering_results.cluster_class_map(i)).abbreviation;
                    end
                    nclus = sum(inst.parent.clustering_results.cluster_index == i);
                    mat = inst.parent.labels_matrix;
                    strings = [strings, sprintf('Cluster #%d (''%s'', N=%d, L=%d, I=%d)', ... 
                                                i, lbl, nclus, ...
                                                length(find(sum(mat(inst.parent.clustering_results.cluster_index == i, :), 2) > 0)), ...
                                                sum(isol(inst.parent.clustering_results.cluster_index == i)))];  
                end
            end

            inst.filter_combo = uicontrol('Parent', inst.filter_combo_box, 'Style', 'popupmenu', 'String', strings, 'Callback', {@inst.combobox_filter_callback});
            inst.nitems_filter = length(strings);

            inst.combobox_filter_callback(0, 0);
        end

        function plot_trajectory(inst, tr, repr, vec, tol, hl)
            lw = 1.2;
            lc = [0 0 0];
            if hl
                hold on;
                lw = 2;
                lc = [0 1 0];
            else
                cla;
                hold on;
                axis off;
                daspect([1 1 1]);
                inst.parent.config.draw_arena(tr, repr);                                                
            end

            pts = repr.apply(tr, 'SimplificationTolerance', tol);
            
            if repr.data_type == base_config.DATA_TYPE_COORDINATES
                if vec
                    % simplify trajectory
                    sz = getpixelposition(gca);

                    for ii = 2:size(pts, 1)                    
                        arrow(pts(ii - 1, 2:3), pts(ii, 2:3), 'LineWidth', lw, 'Length', min(sz(3), sz(4))*0.04, 'FaceColor', lc, 'EdgeColor', lc);
                    end
                else
                    plot(pts(:,2), pts(:,3), '-', 'LineWidth', lw, 'Color', lc);
                end
                
                % show direction vector                
                ra = inst.parent.config.property('ARENA_R', 1);
                %ang = atan2( pts(4, 3) - pts(1, 3), pts(4, 2) - pts(1, 2) );                                
                %arrow(pts(1, 2:3), pts(1, 2:3) + 0.25*r*[cos(ang), sin(ang)], 'LineWidth', 2, 'Length', 0.12*r, 'FaceColor', 'b', 'EdgeColor', 'b');
                rectangle('Position',[pts(1, 2), pts(1,3), ra*.07, ra*.07],...
                    'Curvature',[1, 1], 'FaceColor',[.2, .8, .2], 'edgecolor', [0.2, .8, 0.2], 'LineWidth', 1);
                
            elseif repr.data_type == base_config.DATA_TYPE_SCALAR_FIELD            
                % normalize values
                off = [];
                fac = [];
                % see if already computed
                id = hash_value({repr, tol});
                for i = 1:size(inst.data_repr_norm, 1)
                    if inst.data_repr_norm(i, 1) == id
                        fac = inst.data_repr_norm(i, 2);
                        off = inst.data_repr_norm(i, 3);
                        break;
                    end
                end
                if isempty(fac)
                   val_min = []; 
                   val_max = [];
                   for ii = 1:length(inst.parent.traj.items)
                       tmp = repr.apply(inst.parent.traj.items(ii), 'SimplificationTolerance', tol);
                       if isempty(val_min)
                           val_min = min(tmp(:, 4));
                           val_max = max(tmp(:, 4));
                       else
                           val_min = min(val_min, min(tmp(:, 4)));
                           val_max = max(val_max, max(tmp(:, 4)));
                       end
                   end
                   fac = 1/(val_max - val_min);
                   off = val_min;
                   inst.data_repr_norm = [inst.data_repr_norm; id, double(fac), double(off)]; 
                   inst.parent.config.set_property('DATA_REPR_NORMALIZATION', inst.data_repr_norm);                
                end
                pts(:, 4) = (pts(:, 4) - double(off))*double(fac); 

                cm = jet;
                n = 20;
                cm = cmapping(n + 1, cm);
                fac = 1/n;
                np = size(pts, 1);

                if vec
                    clr = cm(floor(pts(:, 4) ./ repmat(fac, np, 1)) + 1, :);
                    sz = getpixelposition(gca);
                    for ii = 2:size(pts, 1)
                        arrow(pts(ii - 1, 2:3), pts(ii, 2:3), 'FaceColor', clr(ii, :), 'EdgeColor', clr(ii, :), 'LineWidth', lw, 'Length', min(sz(3), sz(4))*0.04);
                    end 
                else
                    clr = floor(pts(:, 4) ./ repmat(fac, np, 1) + 1);
                    z = zeros(1,np);
                    surface( [pts(:,2)'; pts(:,2)'], [pts(:,3)'; pts(:,3)'], [z;z], [clr'; clr'], ...
                         'facecol','no', 'edgecol', 'interp', 'linew', 2);            
                    colormap(cm);
                end
            elseif repr.data_type == base_config.DATA_TYPE_EVENTS
                % plot coordinates            
                plot(pts(:,2), pts(:,3), '-', 'LineWidth', lw, 'Color', [0 0 0]);
                % and plot points for the events
                pos = find(pts(:,4) > 0);
                sz = getpixelposition(gca);

                r = sz(3)*0.005;
                for kk = 1:length(pos)
                    rectangle('Position', [pts(pos(kk), 2) - r, pts(pos(kk), 3) - r, 2*r, 2*r], 'Curvature', [1,1], 'FaceColor', [1 0 0]);                
                end
            elseif repr.data_type == base_config.DATA_TYPE_FUNCTION
                cla;
                % get rid 
                hold off;                
                axis tight;
                if tol > 0
                    plot(pts(:, 1), medfilt1(pts(:, 2), ceil(tol)));
                    % plot(pts(:, 1), smooth(pts(:, 2), ceil(tol)));
                else                   
                    plot(pts(:, 1), pts(:, 2));
                end
                    
                xlabel('t');                
            end

            set(gca, 'LooseInset', [0,0,0,0]);
        end

        function show_trajectories(inst) 
            set(inst.parent.window, 'pointer', 'watch');
            drawnow;
            
            [nx, ny] = inst.number_of_views;
            for i = 1:nx*ny
                if inst.cur + i < length(inst.filter)
                    traj_idx = inst.filter(inst.sorting(inst.cur + i - 1));

                    % plot views
                    for k = 1:3                                        
                        if k == 1                        
                            idx = get(inst.main_view_combo, 'value') - 1;
                            idxfull = get(inst.main_view_full_combo, 'value') - 1;
                            if idx == 0 && idxfull == 0
                                continue;
                            end
                            vec = get(inst.main_view_dir_check, 'value');
                            set(inst.parent.window, 'currentaxes', inst.axis_handles(i));
                            tol = get(inst.main_view_tol_combo, 'value') - 1;
                        else
                            if isempty(inst.sec_view_handles)
                                break;
                            end                        
                            idx = get(inst.sec_view_combos(k - 1), 'value') - 1; % second -1 because of the "none"
                            idxfull = get(inst.sec_view_full_combos(k - 1), 'value') - 1; % second -1 because of the "none"
                            vec = get(inst.sec_view_dir_check(k - 1), 'value');
                            if idx == 0 && idxfull == 0
                                continue; % "none"
                            end
                            set(inst.parent.window, 'currentaxes', inst.sec_view_handles((i - 1)*2 + k - 1));
                            tol = get(inst.sec_view_tol_combos(k - 1), 'value') - 1;
                        end

                        hasfull = idxfull > 0 && idxfull <= length(inst.parent.config.DATA_REPRESENTATIONS);
                        if hasfull
                            % look for parent trajectory
                            id = inst.parent.traj.items(traj_idx).identification;
                            for l = 1:inst.parent.traj.count
                                id2 = inst.parent.traj.items(l).identification;
                                len = length(id) - 1;
                                if isequal(id(1:len), id2(1:len))                               
                                    inst.plot_trajectory(inst.parent.traj.items(l), inst.parent.config.DATA_REPRESENTATIONS(idxfull), 0, 0, 0);                                
                                    break;
                                end
                            end                                                
                        end

                        if idx > 0 && idx <= length(inst.parent.config.DATA_REPRESENTATIONS)
                            tol = tol*0.01*inst.parent.config.property('ARENA_R');
                            
                            inst.plot_trajectory( inst.parent.traj.items(traj_idx) ...
                                                , inst.parent.config.DATA_REPRESENTATIONS(idx) ...
                                                , vec, tol, hasfull);
                        end                                        
                    end

                    hold on;                
%                     if ~isempty(inst.covering)
%                         if inst.covering(traj_idx)
%                             rectangle('Position', [80, 80, 10, 10], 'FaceColor', [0.5, 1, 0.5]);                    
%                         else
%                             rectangle('Position', [80, 80, 10, 10], 'FaceColor', [1, 0.5, 0.5]);
%                         end
%                     end                                    

                    % update the status text with feature values
                    str = '';
                    for j = 1:length(inst.parent.config.SELECTED_FEATURES)
                        if j > 1
                            str = strcat(str, ' | ');
                        end                        
                        str = strcat(str, sprintf('%s: %.4f', inst.parent.config.SELECTED_FEATURES(j).abbreviation, inst.parent.features_values(traj_idx, j)));                    
                    end
                    set(inst.desc_handles(i), 'String', str);

                    % put segment identification in the title
                    str = sprintf('id: %d | set: %d | track: %d | session: %d | trial:%d +%dcm', inst.parent.traj.items(traj_idx).id, inst.parent.traj.items(traj_idx).set, inst.parent.traj.items(traj_idx).track, inst.parent.traj.items(traj_idx).session, inst.parent.traj.items(traj_idx).trial, round(inst.parent.traj.items(traj_idx).offset));
                    if ~isempty(inst.parent.clustering_results)
                        str = sprintf('%s || cluster #%d', str, inst.parent.clustering_results.cluster_index(traj_idx));
                    end               
                    set(inst.view_panels(i), 'Title', str);

                    % update checkboxes
                    handles = inst.cb_handles(i, :);
                    tags = inst.parent.traj_labels.has_tag(traj_idx, inst.parent.config.TAGS); 
                    arrayfun(@(h,j) set(h, 'Value', tags(j)), handles, 1:length(handles));  

                    for j = 1:(length(handles) - 1)
                        % by default no color
                        c = get(gcf,'DefaultUicontrolBackgroundCol');

                        if ~isempty(inst.parent.clustering_results) 
                            idx = -1;
                            if inst.parent.config.TAGS(j).matches(inst.parent.config.UNDEFINED_TAG.abbreviation)
                                idx = 0;
                            else
                                for k = 1:length(inst.parent.clustering_results.classes)                            
                                    if inst.parent.config.TAGS(j).matches(inst.parent.clustering_results.classes(k).abbreviation)                                
                                        idx = k;
                                        break;
                                    end
                                end                        
                            end

                             % see if we have a segment for comparison
                            if ~isempty(inst.parent.reference_results) && inst.parent.results_difference(traj_idx) == idx
                                c = [0.6 0.0 0.0];                            
                            end

                            if idx ~= -1 && inst.parent.clustering_results.class_map(traj_idx) == idx                            
                                if tags(j)                                
                                    c = [0.2, 1., 0.2];                            
                                else
                                    if sum(tags) > 0                              
                                        c = [1., 0.2, 0.2];                            
                                    else
                                        c = [.5, 0.5, 0.9];
                                    end
                                end                                                                               
                            end                                                
                        end
                        set(handles(j), 'BackgroundCol', c); 
                    end

                    % "unknown" is treated separatedly
                    if ~isempty(inst.parent.clustering_results) && (inst.parent.clustering_results.class_map(traj_idx) == -1)
                        set(handles(end), 'BackgroundCol', [1., 1., 0.3]);                            
                    else
                        set(handles(end), 'BackgroundCol', get(gcf,'DefaultUicontrolBackgroundCol'));                            
                    end
                end
            end
            inst.update_status;
            set(inst.parent.window, 'pointer', 'arrow');           
        end   

        function save_data(inst)           
            % save values from screen
            [nx, ny] = inst.number_of_views;
            for i = 0:nx*ny - 1
                if length(inst.filter) >= inst.cur + i
                    vals = arrayfun(@(h) get(h, 'Value'), inst.cb_handles(i + 1, :));                    
                    inst.parent.traj_labels.replace_tags(inst.filter(inst.sorting(inst.cur + i)), ...
                        inst.parent.config.TAGS(vals == 1) ...
                    );
                end
            end

            % save only the tags to speed up things
            inst.parent.config.save_to_file('TagsOnly', 1);            
        end

        function update_status(inst)
            [nx, ny] = inst.number_of_views;
            str = sprintf('%d to %d from %d\n\n', inst.cur, inst.cur + nx*ny - 1, length(inst.filter));
            first = 1;
            tags = inst.parent.labels_matrix;
            for i = 1:size(tags, 2)
                n = sum(tags(inst.filter, i));            
                if n > 0
                    if first
                        first = 0;
                        str = strcat(str, sprintf('\n%s: %d  ', inst.parent.config.TAGS(i).abbreviation, n));
                    else
                        str = strcat(str, sprintf(' | %s: %d', inst.parent.config.TAGS(i).abbreviation, n));
                    end
                end
            end
            if ~isempty(inst.parent.clustering_results)
                pcov = sum(inst.covering) / inst.parent.traj.count;
                str = strcat(str, sprintf('\nErrors: %d (%.3f%%) | Unknown: %.1f%% | Coverage: %.1f%%', ...
                    inst.parent.clustering_results.nerrors, inst.parent.clustering_results.perrors*100, inst.parent.clustering_results.punknown*100, pcov*100)); 
            end
            if ~isempty(inst.diff_set)            
                str = strcat(str, sprintf(' | Agreement: %.1f%%', 100.* ...
                    sum(inst.diff_set == 0) / sum(inst.diff_set > -1) ...
                ));
            end

            str = sprintf('%s\n%s', str, inst.distr_status);        
            set(inst.status_text, 'String', str);
        end

        function checkbox_callback(inst, source, eventdata)
            inst.save_data;   
            inst.update_status;
        end

        function combobox_filter_callback(inst, source, eventdata)
            val = get(inst.filter_combo, 'value');
            switch val
                case 1
                    % everyone
                    inst.filter = 1:inst.parent.traj.count;
                case 2                        
                    % everyone labelled
                    inst.filter = find(sum(inst.parent.labels_matrix, 2) > 0);                            
                case 3                        
                    % everyone not labelled
                    inst.filter = find(sum(inst.parent.labels_matrix, 2) == 0);                                        
                case 4
                    inst.filter = find(inst.covering == 0);
                case 5
                    % "suspicious" guys 
                    if ~isempty(inst.parent.clustering_results)
                        if isempty(inst.segments_map)
                            [~, ~, inst.segments_map] = inst.parent.clustering_results.mapping_ordered(-1, 'MinSegments', 4);
                        end

                        inst.filter = find(inst.segments_map ~= inst.parent.clustering_results.class_map & inst.segments_map > 0 & inst.parent.clustering_results.class_map > 0);                    
                    end
                case 6
                    % user selection
                    inst.filter = selection;
                case 7
                    % reference classification
                    if ~isempty(inst.diff_set)                    
                        inst.filter = find(inst.diff_set > 0);
                    end
                case 8                  
                    % mis-matched classifications      
                    if ~isempty(inst.parent.clustering_results)
                        inst.filter = inst.parent.clustering_results.non_empty_labels_idx(inst.parent.clustering_results.errors == 1);            
                    else
                        inst.filter = 1:inst.parent.traj.count;
                    end
                otherwise
                    % classes
                    if val <= inst.parent.clustering_results.nclasses + 8
                        if strcmp(inst.parent.clustering_results.classes(val - 8).abbreviation, inst.parent.config.UNDEFINED_TAG.abbreviation)
                            inst.filter = find(inst.parent.clustering_results.class_map == 0);
                        else
                            inst.filter = find(inst.parent.clustering_results.class_map == (val - 8));                                    
                        end
                    else
                       % clusters
                       inst.filter = find(inst.parent.clustering_results.cluster_index == (val - inst.parent.clustering_results.nclasses - 8));
                    end
            end
            % status text string
            if ~isempty(inst.parent.clustering_results)
               vals = unique(inst.parent.clustering_results.class_map(inst.filter));
               pc = arrayfun( @(v) sum(inst.parent.clustering_results.class_map(inst.filter) == v)*100. / length(inst.filter), vals);
               [pc, idx] = sort(pc, 'descend');
               vals = vals(idx);
               inst.distr_status = '';
               for i = 1:length(vals)
                    if vals(i) == 0
                        lbl = inst.parent.config.UNDEFINED_TAG.abbreviation;
                    else
                        lbl = inst.parent.clustering_results.classes(vals(i)).abbreviation;
                    end
                    if i == 1
                        inst.distr_status = strcat(inst.distr_status, sprintf('%s: %.1f%% ', lbl, pc(i)));
                    else
                        inst.distr_status = strcat(inst.distr_status, sprintf(' | %s: %.1f%% ', lbl, pc(i)));
                    end        
               end
            end
            inst.update_sorting;
            inst.cur = 1;
            inst. show_trajectories;
            inst.update_filter_navigation;
        end

        function update_sorting(inst)
            val = get(inst.sort_combo, 'value');
            rev = get(inst.sort_reverse_check, 'value');
            switch val
                case 1
                    inst.sorting = 1:length(inst.filter);              
                case 2                
                    % distance to centre of clusters
                    middle = (min(inst.parent.features_values(inst.filter, :)) + max(inst.parent.features_values(inst.filter, :))) / 2;                
                    nz = all(inst.parent.features_values(inst.filter, :) ~= 0);
                    vals = (inst.parent.features_values(inst.filter, nz) - repmat( middle(nz), length(inst.filter), 1)) ./ repmat( max(inst.parent.features_values(inst.filter, nz)) - min(inst.parent.features_values(inst.filter, nz)), length(inst.filter), 1);                                
                    dist = max(abs(vals), [], 2);
                    [~, inst.sorting] = sort(dist);                
                case 3                
                    % distance to centre of clusters                
                    feat_norm = max(inst.parent.features_values) - min(inst.parent.features_values);
                    dist = ((inst.parent.features_values(inst.filter, :) - inst.parent.clustering_results.centroids(:, inst.parent.clustering_results.cluster_index(inst.filter), :)') / repmat(feat_norm, size(inst.parent.features_values, 1), 1)).^2;
                    [~, inst.sorting] = sort(dist);                            
                case 4
                    % distance function
                    dist = sum((inst.parent.features_values(inst.filter, :) ./ repmat( max(inst.parent.features_values(inst.filter, :)) - min(inst.parent.features_values(inst.filter, :)), length(inst.filter), 1)).^2, 2);                
                    [~, inst.sorting] = sort(dist);                            
                case 5
                    % random
                    inst.sorting = randperm(length(inst.filter));
                otherwise                        
                    % sort by a single feature
                    featval = inst.parent.features_values;
                    featval = featval(inst.filter, :);
                    [~, inst.sorting] = sort(featval(:, val - 5));                                        
            end
            if rev
                inst.sorting = inst.sorting(end:-1:1);
            end
        end

        function update_filter_navigation(inst)        
            if get(inst.filter_combo, 'value') == inst.nitems_filter
                set(inst.filter_next_button, 'Enable', 'off');
            else
                set(inst.filter_next_button, 'Enable', 'on');
            end
            if get(inst.filter_combo, 'value') == 1
                set(inst.filter_prev_button, 'Enable', 'off');
            else
                set(inst.filter_prev_button, 'Enable', 'on');
            end
        end

        function filter_next_callback(inst, source, eventdata)
            val = get(inst.filter_combo, 'value');        
            set(inst.filter_combo, 'value', val + 1);
            inst.combobox_filter_callback(0, 0);
        end

        function filter_prev_callback(inst, source, eventdata)
            val = get(inst.filter_combo, 'value');        
            set(inst.filter_combo, 'value', val - 1);
            inst.combobox_filter_callback(0, 0);
        end    

        function layout_change_callback(inst, source, eventdata)
            % save current properties
            set(inst.parent.window, 'pointer', 'watch');
            drawnow;
            inst.parent.config.set_property('BROWSE_SEGMENTS_NX', get(inst.xviews_combo, 'value'));
            inst.parent.config.set_property('BROWSE_SEGMENTS_NY', get(inst.yviews_combo, 'value'));
            % main view
            inst.parent.config.set_property('MAIN_VIEW_DATA_REPR', get(inst.main_view_combo, 'value'));
            inst.parent.config.set_property('MAIN_VIEW_VECTOR_FIELD', get(inst.main_view_dir_check, 'value'));
            inst.parent.config.set_property('MAIN_VIEW_FULL_DATA_REPR', get(inst.main_view_full_combo, 'value'));
            inst.parent.config.set_property('MAIN_VIEW_TOLERANCE', get(inst.main_view_tol_combo, 'value'));
            % 1st mini view
            inst.parent.config.set_property('SEC_VIEW_1_DATA_REPR', get(inst.sec_view_combos(1), 'value'));
            inst.parent.config.set_property('SEC_VIEW_1_VECTOR_FIELD', get(inst.sec_view_dir_check(1), 'value'));
            inst.parent.config.set_property('SEC_VIEW_1_FULL_DATA_REPR', get(inst.sec_view_full_combos(1), 'value'));
            inst.parent.config.set_property('SEC_VIEW_1_TOLERANCE', get(inst.sec_view_tol_combos(1), 'value'));
            % 2nd mini view
            inst.parent.config.set_property('SEC_VIEW_2_DATA_REPR', get(inst.sec_view_combos(2), 'value'));
            inst.parent.config.set_property('SEC_VIEW_2_VECTOR_FIELD', get(inst.sec_view_dir_check(2), 'value'));
            inst.parent.config.set_property('SEC_VIEW_2_FULL_DATA_REPR', get(inst.sec_view_full_combos(2), 'value'));
            inst.parent.config.set_property('SEC_VIEW_2_TOLERANCE', get(inst.sec_view_tol_combos(2), 'value'));
                                    
            inst.parent.config.save_to_file;
            
            inst.create_views;
            inst.show_trajectories;
            set(inst.parent.window, 'pointer', 'arrow');            
        end

        function sorting_callback(inst, source, eventdata)
            inst.update_sorting;
            inst.cur = 1;
            inst.show_trajectories;
        end

        function previous_callback(inst, source, eventdata)
            [nx, ny] = inst.number_of_views;
            if inst.cur >= nx*ny + 1
                inst.cur = inst.cur - nx*ny;
                inst.show_trajectories;
            end        
        end

        function next_callback(inst, source, eventdata)        
            [nx, ny] = inst.number_of_views;
            inst.cur = inst.cur + nx*ny;
            if inst.cur > (length(inst.filter) - nx*ny + 1)
                inst.cur = length(inst.filter) - nx*ny + 1;                               
            end     
            inst.show_trajectories;        
        end

        function previous2_callback(inst, source, eventdata)
            inst.cur = inst.cur - floor(0.01*length(inst.filter));
            if inst.cur < 1
                inst.cur = 1;
            end
            inst.show_trajectories;
        end

        function next2_callback(inst, source, eventdata)        
            inst.cur = inst.cur + floor(0.01*length(inst.filter));
            if inst.cur > (length(inst.filter) - 3)
                inst.cur = length(inst.filter) - 3;                        
            end        
            inst.show_trajectories;
        end

        function previous3_callback(inst, source, eventdata)
            inst.cur = inst.cur - floor(0.05*length(inst.filter));
            if inst.cur < 1
                inst.cur = 1;
            end
            inst.show_trajectories;        
        end

        function next3_callback(inst, source, eventdata)        
            inst.cur = inst.cur + floor(0.05*length(inst.filter));
            if inst.cur > (length(inst.filter) - 3)
                inst.cur = length(inst.filter) - 3;                        
            end        
            inst.show_trajectories;
        end

        function clustering_results_updated(inst, source, eventdata)             
            inst.segments_map = [];
            [~, inst.covering] = inst.parent.clustering_results.coverage();              
        
            inst.filter_combo_valid = 0;                    
        end
        
        function tags_updated(inst, source, eventdata)
            if ~isempty(inst.views_grid)
                inst.layout_change_callback;
                inst.update_filter_combo;
            end
        end
    end   
end
